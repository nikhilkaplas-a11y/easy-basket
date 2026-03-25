import { AppDataSource } from '../config/database';
import { AuthRequest } from '../middleware/auth.middleware';
import { FCMService } from '../services/fcm.service';
import { Order } from '../entities/Order';
import { User } from '../entities/User';
import { IsNull } from 'typeorm';
import { Response } from 'express';

export class DeliveryController {
  static async getAssignedOrders(req: AuthRequest, res: Response): Promise<void> {
    try {
      const deliveryBoyId = req.user?.id;

      if (!deliveryBoyId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { status } = req.query;
      const orderRepository = AppDataSource.getRepository(Order);
      const queryBuilder = orderRepository
        .createQueryBuilder('order')
        .leftJoinAndSelect('order.user', 'user')
        .leftJoinAndSelect('order.items', 'items')
        .leftJoinAndSelect('items.product', 'product')
        .leftJoinAndSelect('items.variant', 'variant')
        .leftJoinAndSelect('order.deliveryAddress', 'deliveryAddress')
        .leftJoinAndSelect('order.deliveryBoy', 'deliveryBoy')
        .where('order.deliveryBoyId = :deliveryBoyId', { deliveryBoyId })
        .orderBy('order.createdAt', 'DESC');

      if (status) {
        queryBuilder.andWhere('order.status = :status', { status });
      }

      const orders = await queryBuilder.getMany();
      console.log(`✅ Delivery agent ${deliveryBoyId} has ${orders.length} assigned orders`);
      if (orders.length > 0) {
        console.log(`   Orders: ${orders.map(o => `#${o.id} (${o.status})`).join(', ')}`);
      }
      res.json(orders);
    } catch (error) {
      console.error('❌ Error fetching assigned orders:', error);
      res.status(500).json({ message: 'Error fetching orders' });
    }
  }

  static async updateOrderStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      const deliveryBoyId = req.user?.id;
      const { id } = req.params;
      const { status } = req.body;

      if (!deliveryBoyId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      if (!status) {
        res.status(400).json({ message: 'Status is required' });
        return;
      }

      // Allow delivery agents to update status: accepted -> preparing -> out_for_delivery -> delivered
      const validStatuses = ['accepted', 'preparing', 'out_for_delivery', 'delivered'];
      if (!validStatuses.includes(status)) {
        res.status(400).json({ message: 'Invalid status. Allowed: accepted, preparing, out_for_delivery, delivered' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id), deliveryBoy: { id: deliveryBoyId } },
        relations: ['user'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found or not assigned to you' });
        return;
      }

      order.status = status;
      await orderRepository.save(order);

      // Notify customer
      if (order.user.fcmToken) {
        let notificationTitle = 'Order Update';
        let notificationBody = `Your order #${order.id} status: ${status}`;

        if (status === 'preparing') {
          notificationTitle = 'Order Preparing';
          notificationBody = `Your order #${order.id} is being prepared`;
        } else if (status === 'out_for_delivery') {
          notificationTitle = 'Out for Delivery';
          notificationBody = `Your order #${order.id} is out for delivery`;
        } else if (status === 'delivered') {
          notificationTitle = 'Order Delivered';
          notificationBody = `Your order #${order.id} has been delivered. Thank you!`;
        }

        const token = order.user.fcmToken;
        const customerId = order.user.id;
        const oid = order.id;
        FCMService.enqueue(
          () =>
            FCMService.sendNotification(
              token,
              notificationTitle,
              notificationBody,
              {
                orderId: oid.toString(),
                status,
                type: 'order_status_update',
              },
              `delivery-status order=#${oid} customerId=${customerId}`,
              customerId
            ),
          `notify customer delivery status #${oid}`
        );
      }

      const oid = order.id;
      FCMService.enqueue(
        () =>
          FCMService.sendNotificationToRole(
            'admin',
            'Order Status Updated',
            `Order #${oid} status updated to ${status} by delivery boy`,
            { orderId: oid.toString(), status, type: 'order_status_update' }
          ),
        `notify admins delivery status #${oid}`
      );

      res.json(order);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating order status' });
    }
  }

  static async getDeliveryStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const deliveryBoyId = req.user?.id;

      if (!deliveryBoyId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);

      const [
        totalDeliveries,
        pendingDeliveries,
        todayDeliveries,
        completedDeliveries,
      ] = await Promise.all([
        orderRepository.count({ where: { deliveryBoy: { id: deliveryBoyId } } }),
        orderRepository.count({
          where: { deliveryBoy: { id: deliveryBoyId }, status: 'out_for_delivery' },
        }),
        orderRepository
          .createQueryBuilder('order')
          .where('order.deliveryBoyId = :deliveryBoyId', { deliveryBoyId })
          .andWhere('DATE(order.createdAt) = CURDATE()')
          .getCount(),
        orderRepository.count({
          where: { deliveryBoy: { id: deliveryBoyId }, status: 'delivered' },
        }),
      ]);

      res.json({
        total: totalDeliveries,
        pending: pendingDeliveries,
        today: todayDeliveries,
        completed: completedDeliveries,
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching delivery stats' });
    }
  }

  static async getOrderDetails(req: AuthRequest, res: Response): Promise<void> {
    try {
      const deliveryBoyId = req.user?.id;
      const { id } = req.params;

      if (!deliveryBoyId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id), deliveryBoy: { id: deliveryBoyId } },
        relations: ['user', 'deliveryAddress', 'items', 'items.product', 'deliveryBoy'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found or not assigned to you' });
        return;
      }

      res.json(order);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching order details' });
    }
  }

  // Get available orders (accepted/preparing without delivery boy assigned)
  static async getAvailableOrders(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { status } = req.query;
      const orderRepository = AppDataSource.getRepository(Order);
      const queryBuilder = orderRepository
        .createQueryBuilder('order')
        .leftJoinAndSelect('order.user', 'user')
        .leftJoinAndSelect('order.items', 'items')
        .leftJoinAndSelect('items.product', 'product')
        .leftJoinAndSelect('order.deliveryAddress', 'deliveryAddress')
        .where('order.deliveryBoyId IS NULL')
        .andWhere('order.status IN (:...statuses)', { statuses: ['accepted', 'preparing'] })
        .orderBy('order.createdAt', 'DESC');

      if (status) {
        queryBuilder.andWhere('order.status = :status', { status });
      }

      const orders = await queryBuilder.getMany();
      res.json(orders);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching available orders' });
    }
  }

  // Accept/claim an available order
  static async acceptOrder(req: AuthRequest, res: Response): Promise<void> {
    try {
      const deliveryBoyId = req.user?.id;
      const { id } = req.params;

      if (!deliveryBoyId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { 
          id: Number(id),
          deliveryBoy: IsNull(), // Only unassigned orders
          status: 'accepted' // Only accepted orders can be claimed
        },
        relations: ['user', 'deliveryBoy'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found or already assigned' });
        return;
      }

      // Assign order to delivery boy
      const userRepository = AppDataSource.getRepository(User);
      const deliveryBoy = await userRepository.findOneBy({ id: deliveryBoyId, role: 'delivery' });

      if (!deliveryBoy) {
        res.status(404).json({ message: 'Delivery boy not found' });
        return;
      }

      order.deliveryBoy = deliveryBoy;
      await orderRepository.save(order);

      if (order.user.fcmToken) {
        const token = order.user.fcmToken;
        const customerId = order.user.id;
        const oid = order.id;
        FCMService.enqueue(
          () =>
            FCMService.sendNotification(
              token,
              'Order Assigned',
              `Order #${oid} has been assigned to a delivery agent`,
              { orderId: oid.toString(), type: 'order_assigned' },
              `delivery-claim customerId=${customerId} order=#${oid}`,
              customerId
            ),
          `notify customer order assigned #${oid}`
        );
      }

      const oid = order.id;
      FCMService.enqueue(
        () =>
          FCMService.sendNotificationToRole(
            'admin',
            'Order Accepted by Delivery Agent',
            `Order #${oid} has been accepted by delivery agent`,
            { orderId: oid.toString(), type: 'order_accepted_by_delivery' }
          ),
        `notify admins delivery accepted #${oid}`
      );

      res.json(order);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error accepting order' });
    }
  }

  static async getEarnings(req: AuthRequest, res: Response): Promise<void> {
    try {
      const deliveryBoyId = req.user?.id;

      if (!deliveryBoyId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { period } = req.query; // today, week, month, all
      const orderRepository = AppDataSource.getRepository(Order);

      let queryBuilder = orderRepository
        .createQueryBuilder('order')
        .where('order.deliveryBoyId = :deliveryBoyId', { deliveryBoyId })
        .andWhere('order.status = :status', { status: 'delivered' });

      const now = new Date();
      if (period === 'today') {
        queryBuilder.andWhere('DATE(order.updatedAt) = CURDATE()');
      } else if (period === 'week') {
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        queryBuilder.andWhere('order.updatedAt >= :weekAgo', { weekAgo });
      } else if (period === 'month') {
        const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        queryBuilder.andWhere('order.updatedAt >= :monthAgo', { monthAgo });
      }

      const deliveredOrders = await queryBuilder.getMany();
      
      // Calculate earnings (assuming ₹20 per delivery or 5% commission)
      const totalDeliveries = deliveredOrders.length;
      const earningsPerDelivery = 20; // Fixed amount per delivery
      const totalEarnings = totalDeliveries * earningsPerDelivery;

      // Get today's earnings
      const todayOrders = deliveredOrders.filter(
        (order) => new Date(order.updatedAt).toDateString() === now.toDateString()
      );
      const todayEarnings = todayOrders.length * earningsPerDelivery;

      res.json({
        totalEarnings,
        todayEarnings,
        totalDeliveries,
        todayDeliveries: todayOrders.length,
        earningsPerDelivery,
        period: period || 'all',
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching earnings' });
    }
  }
}
