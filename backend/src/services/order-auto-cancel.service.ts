import { LessThan } from 'typeorm';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { FCMService } from './fcm.service';
import { OrderInventoryService } from './order-inventory.service';

/**
 * Periodic job: pending orders that stay unaccepted past the configured window are cancelled
 * and reserved inventory is released (same rules as customer cancel).
 *
 * Window: ORDER_AUTO_CANCEL_MINUTES (default 30). Check interval: 1 minute.
 */
export class OrderAutoCancelService {
  private static intervalId: NodeJS.Timeout | null = null;
  private static readonly CHECK_INTERVAL_MS = 60 * 1000;
  private static readonly autoCancelAfterMs: number = OrderAutoCancelService.resolveAutoCancelMs();

  private static resolveAutoCancelMs(): number {
    const raw = process.env.ORDER_AUTO_CANCEL_MINUTES;
    const minutes = raw !== undefined ? parseInt(raw, 10) : 30;
    const safe = Number.isFinite(minutes) && minutes > 0 ? minutes : 30;
    return safe * 60 * 1000;
  }

  static start(): void {
    if (this.intervalId) {
      console.log('⚠️ [AutoCancel] Already running');
      return;
    }

    const mins = this.autoCancelAfterMs / 60_000;
    console.log(
      `🔄 [AutoCancel] Started — pending orders auto-cancel after ${mins} min (ORDER_AUTO_CANCEL_MINUTES)`
    );

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

      const cutoffTime = new Date(Date.now() - this.autoCancelAfterMs);

      const staleOrders = await orderRepository.find({
        where: {
          status: 'pending',
          createdAt: LessThan(cutoffTime),
        },
        relations: ['user', 'items', 'items.product', 'items.variant'],
      });

      if (staleOrders.length === 0) return;

      console.log(`🔄 [AutoCancel] Found ${staleOrders.length} stale pending order(s)`);

      const windowMins = Math.round(this.autoCancelAfterMs / 60_000);

      for (const order of staleOrders) {
        await OrderInventoryService.restoreReservedStockForItems(order.items);
        order.status = 'cancelled';
        await orderRepository.save(order);

        console.log(
          `❌ [AutoCancel] Order #${order.id} auto-cancelled (pending > ${windowMins} min), stock restored`
        );

        const oid = order.id;
        const userToken = order.user?.fcmToken;
        const customerId = order.user?.id;
        if (userToken && customerId != null) {
          FCMService.enqueue(
            () =>
              FCMService.sendNotification(
                userToken,
                '😔 Order Cancelled',
                `We're sorry! Your order #${oid} couldn't be processed this time. Please try again — we'd love to serve you! 🙏`,
                { orderId: oid.toString(), type: 'ORDER_CANCELLED' },
                `auto-cancel customerId=${customerId} order=#${oid}`,
                customerId
              ),
            `auto-cancel notify customer #${oid}`
          );
        }

        FCMService.enqueue(
          () =>
            FCMService.sendNotificationToRole(
              'admin',
              '⚠️ Order Auto-Cancelled',
              `⚠️ Order #${oid} auto-cancelled — was pending for ${windowMins} minutes`,
              { orderId: oid.toString(), type: 'ORDER_CANCELLED' }
            ),
          `auto-cancel notify admins #${oid}`
        );
      }
    } catch (error) {
      console.error('❌ [AutoCancel] Error:', error);
    }
  }
}
