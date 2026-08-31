import { Response } from 'express';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { OrderItem } from '../entities/OrderItem';
import { Product } from '../entities/Product';
import { ProductVariant } from '../entities/ProductVariant';
import { Address } from '../entities/Address';
import { User } from '../entities/User';
import { AuthRequest } from '../middleware/auth.middleware';
import { idempotencyKeyFromReq } from '../middleware/idempotency.middleware';
import { normalizePaymentMethod } from '../constants/payment-method';
import { PaymentService } from '../services/payment.service';
import { FCMService } from '../services/fcm.service';
import { OrderInventoryService } from '../services/order-inventory.service';
import { ServiceabilityService, isValidLat, isValidLng } from '../services/serviceability.service';
import { StoreStatusService } from '../services/store-status.service';
import { ProductController } from './product.controller';
import { QueryFailedError, In } from 'typeorm';
import { PaymentsV2Service } from '../services/payments-v2.service';

/**
 * Thrown inside the order-creation transaction when a stock UPDATE finds
 * insufficient stock. Causes the entire transaction to roll back — no order
 * row, no order_items, no partial stock decrements. Caught by createOrder's
 * catch and mapped to a 409 response.
 */
class InsufficientStockError extends Error {
  constructor(public readonly itemKey: string) {
    super(`Insufficient stock for ${itemKey}`);
    this.name = 'InsufficientStockError';
  }
}

export class OrderController {
  static async createOrder(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { items, addressId, paymentMethod, notes } = req.body;

      if (!items || !Array.isArray(items) || items.length === 0) {
        res.status(400).json({ message: 'Order items are required' });
        return;
      }

      if (!addressId) {
        res.status(400).json({ message: 'Delivery address is required' });
        return;
      }

      const normalizedPaymentMethod = normalizePaymentMethod(paymentMethod);
      if (!normalizedPaymentMethod) {
        res
          .status(400)
          .json({ message: 'Invalid paymentMethod. Allowed: upi, cod (aliases: cash, razorpay).' });
        return;
      }

      // Enforce store open/closed server-side — never trust the client's UX
      // check. The app greys out the Place Order button, but a stale in-memory
      // flag (app opened before the store closed) or a direct API call would
      // sail straight past it. Checked BEFORE the user/address/product lookups
      // so a closed store rejects cheaply.
      //
      // Uses the uncached read: order creation is low-volume next to status
      // polling, and this is the one call site where being seconds stale costs
      // real money. Reads fail OPEN, so a database blip can't shut the shop.
      //
      // Scope: NEW orders only. Existing orders, rider deliveries, admin
      // actions and cancellations all continue normally while closed — a
      // customer who already paid still gets their groceries.
      const storeStatus = await StoreStatusService.isAcceptingOrders();
      if (!storeStatus.isOpen) {
        res.status(409).json({
          message:
            storeStatus.customMessage ||
            "We're not accepting orders right now. Please try again shortly.",
          code: 'STORE_CLOSED',
          closedReason: storeStatus.closedReason,
          expectedReopenAt: storeStatus.expectedReopenAt,
        });
        return;
      }

      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOneBy({ id: userId });

      if (!user) {
        res.status(404).json({ message: 'User not found' });
        return;
      }

      const addressRepository = AppDataSource.getRepository(Address);
      const address = await addressRepository.findOne({
        where: { id: addressId, user: { id: userId } },
      });

      if (!address) {
        res.status(404).json({ message: 'Address not found' });
        return;
      }

      // Enforce serviceability server-side — never trust the client's UX check.
      // Only when the store radius is configured AND the address has coordinates;
      // legacy coord-less addresses fall through so existing users aren't blocked.
      if (ServiceabilityService.isConfigured() && address.latitude && address.longitude) {
        const aLat = Number(address.latitude);
        const aLng = Number(address.longitude);
        if (isValidLat(aLat) && isValidLng(aLng)) {
          const svc = ServiceabilityService.check(aLat, aLng);
          if (!svc.available) {
            res.status(400).json({
              message: 'Delivery address is outside our service area',
              code: 'OUT_OF_SERVICE_AREA',
              distanceKm: svc.distanceKm,
              radiusKm: svc.radiusKm,
            });
            return;
          }
        }
      }

      // Validate quantities up front — these values are later inlined into
      // the SET clause of an UPDATE statement (safe only if they're positive ints).
      for (const item of items) {
        if (!Number.isInteger(item.quantity) || item.quantity <= 0) {
          res.status(400).json({ message: 'Item quantity must be a positive integer' });
          return;
        }
      }

      const productRepository = AppDataSource.getRepository(Product);
      const variantRepository = AppDataSource.getRepository(ProductVariant);
      let totalAmount = 0;
      const orderItems: OrderItem[] = [];

      // Validate items and calculate total
      for (const item of items) {
        const product = await productRepository.findOneBy({ id: item.productId });

        if (!product) {
          res.status(404).json({ message: `Product ${item.productId} not found` });
          return;
        }

        if (!product.isAvailable) {
          res.status(400).json({ message: `Product ${product.name} is not available` });
          return;
        }

        // Handle variant if provided
        let variant: ProductVariant | null = null;
        let itemPrice: number;
        let itemUnit: string;
        let itemStock: number;
        let displayLabel: string;

        if (item.variantId) {
          // Fetch and validate variant
          variant = await variantRepository.findOne({
            where: { id: item.variantId },
            relations: ['product'],
          });

          if (!variant) {
            res.status(404).json({ message: `Variant ${item.variantId} not found` });
            return;
          }

          if (variant.product.id !== product.id) {
            res.status(400).json({
              message: `Variant ${item.variantId} does not belong to product ${item.productId}`,
            });
            return;
          }

          if (!variant.isAvailable) {
            res.status(400).json({ message: `Variant ${variant.label} is not available` });
            return;
          }

          if (variant.stock < item.quantity) {
            res.status(400).json({
              message: `Insufficient stock for ${variant.label}. Available: ${variant.stock}`,
            });
            return;
          }

          itemPrice = variant.price;
          itemUnit = variant.unit;
          itemStock = variant.stock;
          displayLabel = item.quantity > 1 ? `${item.quantity} × ${variant.label}` : variant.label;
        } else {
          // No variant - use product price and stock
          if (product.stock < item.quantity) {
            res.status(400).json({
              message: `Insufficient stock for ${product.name}. Available: ${product.stock}`,
            });
            return;
          }

          itemPrice = product.price;
          itemUnit = product.unit || 'piece';
          itemStock = product.stock;
          displayLabel = item.quantity > 1 ? `${item.quantity} × ${product.name}` : product.name;
        }

        const itemTotal = itemPrice * item.quantity;
        totalAmount += itemTotal;

        const orderItem = new OrderItem();
        orderItem.product = product;
        orderItem.variant = variant;
        orderItem.quantity = item.quantity;
        orderItem.unit = itemUnit;
        orderItem.price = itemPrice;
        orderItem.total = itemTotal;
        orderItem.displayLabel = displayLabel;

        orderItems.push(orderItem);
      }

      // Atomically: decrement stock with row-level guards, then insert the order.
      // The conditional UPDATE (`stock >= :q`) is the real safety net against
      // overselling — even if two requests pass the pre-check above, only one
      // can affect a row when stock is the last unit. If any item fails,
      // InsufficientStockError rolls back the whole transaction, so no order
      // row, no order_items, no partial stock decrement survives.
      const order = await AppDataSource.transaction(async (manager) => {
        for (const item of items) {
          if (item.variantId) {
            const result = await manager
              .createQueryBuilder()
              .update(ProductVariant)
              .set({ stock: () => `stock - ${item.quantity}` })
              .where('id = :id AND stock >= :q', { id: item.variantId, q: item.quantity })
              .execute();
            if (result.affected !== 1) {
              throw new InsufficientStockError(`variant ${item.variantId}`);
            }
          } else {
            const result = await manager
              .createQueryBuilder()
              .update(Product)
              .set({ stock: () => `stock - ${item.quantity}` })
              .where('id = :id AND stock >= :q', { id: item.productId, q: item.quantity })
              .execute();
            if (result.affected !== 1) {
              throw new InsufficientStockError(`product ${item.productId}`);
            }
          }
        }

        const orderRepo = manager.getRepository(Order);
        const created = orderRepo.create({
          user,
          deliveryAddress: address,
          items: orderItems,
          totalAmount,
          paymentMethod: normalizedPaymentMethod,
          notes,
          status: 'pending',
          idempotencyKey: idempotencyKeyFromReq(req),
        });
        return orderRepo.save(created);
      });

      await ProductController.invalidateProductListCache();

      // Create payment order if UPI.
      //
      // A failure here used to be swallowed: the response still came back 201 with
      // paymentOrder: null and no indication anything was wrong. Since no Payment row
      // exists in that case, neither the BullMQ worker nor the reconciler will ever
      // look at this order (both scan the payments table), so the reserved stock just
      // sits until auto-cancel notices 30 minutes later.
      //
      // The order itself is genuinely created, so this stays a 201 rather than an
      // error — but the failure is now reported. The mobile client recovers anyway by
      // calling /payment/create-order separately; paymentError is for any client that
      // relies on this response.
      let paymentOrder = null;
      let paymentError: string | null = null;
      if (normalizedPaymentMethod === 'upi') {
        try {
          paymentOrder = await PaymentService.createOrder(totalAmount, 'INR', `ORDER_${order.id}`);
        } catch (error) {
          paymentError = 'Could not start the payment. Open the order and retry payment.';
          console.error(`[order] payment order creation failed for order #${order.id}:`, error);
        }
      }

      // COD only.
      //
      // This used to fire unconditionally, so admins were interrupted for online
      // orders that had not been paid for and might never be — while nothing at all
      // told them when a payment actually succeeded. The signal arrived at the least
      // informative moment.
      //
      // For online orders the notification now fires from PaymentsV2Service once the
      // webhook confirms the money, where it carries a real accept-or-refuse decision.
      // COD has no payment to wait for, so it still notifies here.
      if (normalizedPaymentMethod === 'cod') {
        console.log(`📤 [ORDER] Queued admin notification for COD order #${order.id}`);
        FCMService.enqueue(
          () =>
            FCMService.sendNotificationToRole(
              'admin',
              '🛒 New Order! (Cash on delivery)',
              `🛒 New COD order • ₹${totalAmount} — Order #${order.id}`,
              { orderId: order.id.toString(), type: 'new_order' }
            ),
          `notify admins new COD order #${order.id}`
        );
      }

      res.status(201).json({
        order,
        paymentOrder, // Razorpay order details if UPI
        paymentError, // non-null when the order exists but payment could not be started
      });
    } catch (error) {
      if (error instanceof InsufficientStockError) {
        res.status(409).json({
          message: 'An item just went out of stock. Please refresh your cart and try again.',
        });
        return;
      }
      // DB unique-constraint hit: duplicate (user, idempotency_key) — the Redis fast-path
      // missed (e.g. Redis was unreachable when this request started), but the DB caught it.
      if (error instanceof QueryFailedError && (error as QueryFailedError & { code?: string }).code === 'ER_DUP_ENTRY') {
        res.status(409).json({
          message: 'Duplicate request detected. Please refresh to see your existing order.',
        });
        return;
      }
      console.error(error);
      res.status(500).json({ message: 'Error creating order' });
    }
  }

  static async getUserOrders(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { status, fields } = req.query;
      const orderRepository = AppDataSource.getRepository(Order);

      // Optional pagination: ?limit=15&offset=0 — My Orders app screen (full relations).
      // Omit limit → same as before: return full array JSON (backward compatible).
      const limitRaw = req.query.limit;
      const offsetRaw = req.query.offset;
      const usePagination =
        limitRaw !== undefined && limitRaw !== null && String(limitRaw).trim() !== '';
      let limit: number | undefined;
      let offset = 0;
      if (usePagination) {
        const parsed = parseInt(String(limitRaw), 10);
        limit = Number.isFinite(parsed) ? Math.min(Math.max(parsed, 1), 100) : 15;
        const off = parseInt(String(offsetRaw ?? '0'), 10);
        offset = Number.isFinite(off) && off >= 0 ? off : 0;
      }

      // Build where condition
      // status=active → sirf pending/accepted/preparing/out_for_delivery (home screen ke liye)
      // status=delivered/cancelled → sirf wo status
      // no status → sab orders (orders page ke liye)
      let whereCondition: any = { user: { id: userId } };

      if (status === 'active') {
        whereCondition = [
          { user: { id: userId }, status: 'pending' },
          { user: { id: userId }, status: 'accepted' },
          { user: { id: userId }, status: 'preparing' },
          { user: { id: userId }, status: 'out_for_delivery' },
        ];
      } else if (status && typeof status === 'string') {
        whereCondition = { user: { id: userId }, status };
      }

      // fields=light → minimal data, 0 JOINs (home screen active order bar ke liye)
      // Kyun: Home screen pe sirf id, status, totalAmount chahiye
      // 6 JOINs lagana unnecessary hai — ~90% faster response
      if (fields === 'light') {
        if (usePagination && limit !== undefined) {
          const [orders, total] = await orderRepository.findAndCount({
            where: whereCondition,
            select: ['id', 'status', 'totalAmount', 'createdAt', 'updatedAt'],
            order: { createdAt: 'DESC' },
            skip: offset,
            take: limit,
          });
          res.json({ orders, total, limit, offset });
          return;
        }
        const orders = await orderRepository.find({
          where: whereCondition,
          select: ['id', 'status', 'totalAmount', 'createdAt', 'updatedAt'],
          order: { createdAt: 'DESC' },
        });
        res.json(orders);
        return;
      }

      // Full data — orders page, order detail ke liye (6 JOINs)
      if (usePagination && limit !== undefined) {
        const [orders, total] = await orderRepository.findAndCount({
          where: whereCondition,
          relations: [
            'user',
            'items',
            'items.product',
            'items.variant',
            'deliveryAddress',
            'deliveryBoy',
          ],
          order: { createdAt: 'DESC' },
          skip: offset,
          take: limit,
        });
        const flags = await PaymentsV2Service.getRefundFlagsForOrders(
          orders.map((o) => o.id)
        );
        res.json({
          orders: orders.map((o) => ({ ...o, ...(flags.get(o.id) ?? {}) })),
          total,
          limit,
          offset,
        });
        return;
      }

      const orders = await orderRepository.find({
        where: whereCondition,
        relations: [
          'user',
          'items',
          'items.product',
          'items.variant',
          'deliveryAddress',
          'deliveryBoy',
        ],
        order: { createdAt: 'DESC' },
      });

      // One batched lookup for the page so the list can distinguish a refunded
      // order from a paid one, and flag a refund that needs our attention.
      // The `fields=light` branch above is deliberately excluded: it exists to
      // serve the home screen with zero joins.
      const refundFlags = await PaymentsV2Service.getRefundFlagsForOrders(
        orders.map((o) => o.id)
      );
      res.json(orders.map((o) => ({ ...o, ...(refundFlags.get(o.id) ?? {}) })));
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching orders' });
    }
  }

  static async getOrderById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id), user: { id: userId } },
        relations: [
          'user',
          'items',
          'items.product',
          'items.variant',
          'deliveryAddress',
          'deliveryBoy',
        ],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      // Refund state for the tracking screen. Needed because a refund that fails
      // permanently releases the payment back to `paid` — without this the customer
      // would see a reassuring "Paid Online" moments after being told their refund
      // was delayed.
      const [refundFlags, refund] = await Promise.all([
        PaymentsV2Service.getRefundFlagsForOrders([order.id]),
        PaymentsV2Service.getCustomerRefundForOrder(order.id),
      ]);
      res.json({ ...order, ...(refundFlags.get(order.id) ?? {}), refund });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching order' });
    }
  }

  static async getOrderStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const id = Number(req.params.id);
      if (!Number.isInteger(id) || id <= 0) {
        res.status(400).json({ message: 'Invalid order id' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      // Ownership check baked into the WHERE clause: a hit means the order
      // exists AND belongs to the caller. Anything else returns the same 404
      // so we don't leak existence of other users' orders.
      const order = await orderRepository.findOne({
        where: { id, user: { id: userId } },
        relations: ['items', 'items.product'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      res.json({
        id: order.id,
        status: order.status,
        totalAmount: order.totalAmount,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching order status' });
    }
  }

  static async cancelOrder(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id), user: { id: userId } },
        relations: ['items', 'items.product', 'items.variant'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      // Direct cancel is ONLY for orders already being prepared or out for
      // delivery — and it carries NO refund (resources already committed).
      // Orders still in pending/accepted must go through request-cancellation
      // (admin-approved full refund). delivered/cancelled are terminal.
      if (order.status === 'pending' || order.status === 'accepted') {
        res.status(400).json({
          message:
            'Order not yet packed — use request-cancellation to cancel with a refund.',
          code: 'USE_REQUEST_CANCELLATION',
        });
        return;
      }
      if (order.status !== 'preparing' && order.status !== 'out_for_delivery') {
        res.status(400).json({ message: `Cannot cancel order with status: ${order.status}` });
        return;
      }

      // Atomic claim: only ONE concurrent cancel flips the order → restores stock,
      // so a double-tap/race can't restore reserved stock twice.
      const claim = await orderRepository.update(
        { id: order.id, status: In(['preparing', 'out_for_delivery']) },
        { status: 'cancelled' }
      );
      if (claim.affected !== 1) {
        res.status(409).json({ message: 'Order already cancelled or its status changed.' });
        return;
      }

      await OrderInventoryService.restoreReservedStockForItems(order.items);
      order.status = 'cancelled';

      FCMService.enqueue(
        () =>
          FCMService.sendNotificationToRole(
            'admin',
            '😔 Order Cancelled',
            `Order #${order.id} cancelled by customer after packing (no refund due)`,
            { orderId: order.id.toString(), type: 'order_cancelled' }
          ),
        `notify admins customer cancelled #${order.id}`
      );

      res.json({ message: 'Order cancelled successfully', order });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error cancelling order' });
    }
  }

  /**
   * Customer raises a cancellation/refund REQUEST. Allowed only before the order
   * is packed (status pending/accepted). Does NOT cancel — sets the request to
   * 'requested' and notifies admin, who approves (→ cancel + full refund) or
   * rejects. After packing, customers use cancelOrder directly (no refund).
   */
  static async requestCancellation(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { id } = req.params;
      const { reason } = req.body as { reason?: string };

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id), user: { id: userId } },
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      // Refund-eligible window only: before packing begins.
      if (order.status !== 'pending' && order.status !== 'accepted') {
        res.status(400).json({
          message:
            'Order is already being prepared. You can cancel it, but no refund will be given.',
          code: 'ALREADY_PACKED',
        });
        return;
      }

      // Idempotent: re-requesting while one is pending is a no-op.
      if (order.cancelRequestStatus === 'requested') {
        res.json({ message: 'Cancellation request already pending', order });
        return;
      }

      order.cancelRequestStatus = 'requested';
      order.cancellationReason = (reason ?? '').trim().slice(0, 255) || null;
      order.cancellationRequestedAt = new Date();
      await orderRepository.save(order);

      FCMService.enqueue(
        () =>
          FCMService.sendNotificationToRole(
            'admin',
            '↩️ Refund Requested',
            `Order #${order.id}: customer requested cancellation & refund`,
            { orderId: order.id.toString(), type: 'refund_requested' }
          ),
        `notify admins refund requested #${order.id}`
      );

      res.json({ message: 'Cancellation request submitted', order });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error requesting cancellation' });
    }
  }
}
