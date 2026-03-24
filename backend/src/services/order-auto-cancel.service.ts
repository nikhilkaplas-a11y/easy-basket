import { LessThan } from 'typeorm';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { FCMService } from './fcm.service';

/**
 * Auto-cancel service
 * Har minute check karta hai — agar koi order 3 min se zyada pending hai toh auto-cancel
 * Kyun: Admin ne 3 min mein accept nahi kiya toh customer ko wait nahi karana
 */
export class OrderAutoCancelService {
  private static intervalId: NodeJS.Timeout | null = null;
  private static readonly CHECK_INTERVAL_MS = 60 * 1000;  // Har 1 min mein check
  private static readonly AUTO_CANCEL_AFTER_MS = 30 * 60 * 1000; // 30 min baad cancel

  static start(): void {
    if (this.intervalId) {
      console.log('⚠️ [AutoCancel] Already running');
      return;
    }

    console.log('🔄 [AutoCancel] Started — pending orders will auto-cancel after 3 minutes');

    this.intervalId = setInterval(() => {
      this.checkAndCancelOrders();
    }, this.CHECK_INTERVAL_MS);

    // Pehli baar turant bhi check karo
    this.checkAndCancelOrders();
  }

  static stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      console.log('⏹️ [AutoCancel] Stopped');
    }
  }

  private static async checkAndCancelOrders(): Promise<void> {
    try {
      const orderRepository = AppDataSource.getRepository(Order);

      // 3 min pehle ka time nikalo
      const cutoffTime = new Date(Date.now() - this.AUTO_CANCEL_AFTER_MS);

      // Find all pending orders older than 3 minutes
      const staleOrders = await orderRepository.find({
        where: {
          status: 'pending',
          createdAt: LessThan(cutoffTime),
        },
        relations: ['user'],
      });

      if (staleOrders.length === 0) return;

      console.log(`🔄 [AutoCancel] Found ${staleOrders.length} stale pending order(s)`);

      for (const order of staleOrders) {
        // Cancel the order
        order.status = 'cancelled';
        await orderRepository.save(order);

        console.log(`❌ [AutoCancel] Order #${order.id} auto-cancelled (pending > 3 min)`);

        // Notify customer
        if (order.user?.fcmToken) {
          await FCMService.sendNotification(
            order.user.fcmToken,
            'Order Cancelled',
            `Order #${order.id} was auto-cancelled as it wasn't confirmed in time. Please try again.`,
            { orderId: order.id.toString(), type: 'ORDER_CANCELLED' }
          );
        }

        // Notify admins
        await FCMService.sendNotificationToRole(
          'admin',
          'Order Auto-Cancelled',
          `Order #${order.id} auto-cancelled — not accepted within 3 minutes`,
          { orderId: order.id.toString(), type: 'ORDER_CANCELLED' }
        );
      }
    } catch (error) {
      console.error('❌ [AutoCancel] Error:', error);
    }
  }
}
