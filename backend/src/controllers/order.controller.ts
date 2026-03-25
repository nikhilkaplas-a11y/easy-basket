import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { OrderItem } from '../entities/OrderItem';
import { Product } from '../entities/Product';
import { ProductVariant } from '../entities/ProductVariant';
import { Address } from '../entities/Address';
import { User } from '../entities/User';
import { AuthRequest } from '../middleware/auth.middleware';
import { PaymentService } from '../services/payment.service';
import { FCMService } from '../services/fcm.service';
import { OrderInventoryService } from '../services/order-inventory.service';

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
            res.status(400).json({ message: `Variant ${item.variantId} does not belong to product ${item.productId}` });
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
          displayLabel = item.quantity > 1 
            ? `${item.quantity} × ${variant.label}`
            : variant.label;
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
          displayLabel = item.quantity > 1 
            ? `${item.quantity} × ${product.name}`
            : product.name;
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

      // Create order
      const orderRepository = AppDataSource.getRepository(Order);
      const order = orderRepository.create({
        user,
        deliveryAddress: address,
        items: orderItems,
        totalAmount,
        paymentMethod: paymentMethod || 'UPI',
        notes,
        status: 'pending',
      });

      await orderRepository.save(order);

      // Update product/variant stock
      for (const item of items) {
        if (item.variantId) {
          // Update variant stock
          const variant = await variantRepository.findOneBy({ id: item.variantId });
          if (variant) {
            variant.stock -= item.quantity;
            await variantRepository.save(variant);
          }
        } else {
          // Update product stock
          const product = await productRepository.findOneBy({ id: item.productId });
          if (product) {
            product.stock -= item.quantity;
            await productRepository.save(product);
          }
        }
      }

      // Create payment order if UPI
      let paymentOrder = null;
      if (paymentMethod === 'UPI') {
        try {
          paymentOrder = await PaymentService.createOrder(
            totalAmount,
            'INR',
            `ORDER_${order.id}`
          );
        } catch (error) {
          console.error('Payment order creation error:', error);
        }
      }

      console.log(`📤 [ORDER] Queued admin notification for order #${order.id}`);
      FCMService.enqueue(
        () =>
          FCMService.sendNotificationToRole(
            'admin',
            'New Order Received',
            `Order #${order.id} for ₹${totalAmount}`,
            { orderId: order.id.toString(), type: 'new_order' }
          ),
        `notify admins new order #${order.id}`
      );

      res.status(201).json({
        order,
        paymentOrder, // Razorpay order details if UPI
      });
    } catch (error) {
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
        const orders = await orderRepository.find({
          where: whereCondition,
          select: ['id', 'status', 'totalAmount', 'createdAt', 'updatedAt'],
          order: { createdAt: 'DESC' },
        });
        res.json(orders);
        return;
      }

      // Full data — orders page, order detail ke liye (6 JOINs)
      const orders = await orderRepository.find({
        where: whereCondition,
        relations: ['user', 'items', 'items.product', 'items.variant', 'deliveryAddress', 'deliveryBoy'],
        order: { createdAt: 'DESC' },
      });

      res.json(orders);
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
        relations: ['user', 'items', 'items.product', 'items.variant', 'deliveryAddress', 'deliveryBoy'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      res.json(order);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching order' });
    }
  }

  static async getOrderStatus(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id) },
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

      if (order.status === 'delivered' || order.status === 'cancelled') {
        res.status(400).json({ message: `Cannot cancel order with status: ${order.status}` });
        return;
      }

      await OrderInventoryService.restoreReservedStockForItems(order.items);

      order.status = 'cancelled';
      await orderRepository.save(order);

      FCMService.enqueue(
        () =>
          FCMService.sendNotificationToRole(
            'admin',
            'Order Cancelled',
            `Order #${order.id} has been cancelled`,
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
}

