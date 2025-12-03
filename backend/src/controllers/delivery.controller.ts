import { AppDataSource } from '../config/database';
import { AuthRequest } from '../middleware/auth.middleware';
import { FCMService } from '../services/fcm.service';
import { Order } from '../entities/Order';
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
        .leftJoinAndSelect('order.deliveryAddress', 'deliveryAddress')
        .where('order.deliveryBoyId = :deliveryBoyId', { deliveryBoyId })
        .orderBy('order.createdAt', 'DESC');

      if (status) {
        queryBuilder.andWhere('order.status = :status', { status });
      }

      const orders = await queryBuilder.getMany();
      res.json(orders);
    } catch (error) {
      console.error(error);
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

      const validStatuses = ['out_for_delivery', 'delivered'];
      if (!validStatuses.includes(status)) {
        res.status(400).json({ message: 'Invalid status. Only out_for_delivery and delivered are allowed' });
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

        if (status === 'out_for_delivery') {
          notificationTitle = 'Out for Delivery';
          notificationBody = `Your order #${order.id} is out for delivery`;
        } else if (status === 'delivered') {
          notificationTitle = 'Order Delivered';
          notificationBody = `Your order #${order.id} has been delivered. Thank you!`;
        }

        await FCMService.sendNotification(
          order.user.fcmToken,
          notificationTitle,
          notificationBody,
          { orderId: order.id.toString(), status, type: 'order_status_update' }
        );
      }

      // Notify admin
      await FCMService.sendNotificationToRole(
        'admin',
        'Order Status Updated',
        `Order #${order.id} status updated to ${status} by delivery boy`,
        { orderId: order.id.toString(), status, type: 'order_status_update' }
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
