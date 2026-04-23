import { LessThan, In } from 'typeorm';
import { AppDataSource } from '../config/database';
import { Payment } from '../entities/Payment';
import { Refund } from '../entities/Refund';
import { Order } from '../entities/Order';
import { RazorpayService } from './razorpay.service';
import { OrderInventoryService } from './order-inventory.service';
import { PaymentsV2Service } from './payments-v2.service';

/**
 * Reconciliation worker.
 *
 * Runs every 5 minutes, scanning for payments that might have drifted from Razorpay's
 * view of the world — e.g. webhook got lost, verify never called, refund never reached
 * terminal state. For each drift, we apply the same state-machine transition the webhook
 * would have, so the fix is idempotent and race-safe.
 *
 * Interval is configurable via RECONCILER_INTERVAL_MINUTES (default 5).
 */
export class PaymentsReconcilerService {
  private static intervalId: NodeJS.Timeout | null = null;

  static start(): void {
    if (this.intervalId) return;
    const raw = process.env.RECONCILER_INTERVAL_MINUTES;
    const minutes = raw ? Number(raw) : 5;
    const safeMins = Number.isFinite(minutes) && minutes > 0 ? minutes : 5;
    const intervalMs = safeMins * 60 * 1000;

    console.log(`[Reconciler] starting — every ${safeMins} min`);

    this.intervalId = setInterval(() => {
      this.tick().catch((err) => console.error('[Reconciler] tick error', err));
    }, intervalMs);

    // Run once at startup after a short delay so DB is ready.
    setTimeout(() => {
      this.tick().catch((err) => console.error('[Reconciler] initial tick error', err));
    }, 15_000);
  }

  static stop(): void {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  static async tick(): Promise<void> {
    await this.reconcileStalePayments();
    await this.reconcilePendingRefunds();
  }

  /**
   * Payments still in {initiated, success_unverified} after 10 minutes are candidates
   * for drift. Pull authoritative state from Razorpay and correct the DB.
   */
  private static async reconcileStalePayments(): Promise<void> {
    const paymentRepo = AppDataSource.getRepository(Payment);
    const cutoff = new Date(Date.now() - 10 * 60 * 1000);

    const stale = await paymentRepo.find({
      where: {
        status: In(['initiated', 'success_unverified']),
        createdAt: LessThan(cutoff),
      },
      take: 200,
    });

    if (stale.length === 0) return;
    console.log(`[Reconciler] ${stale.length} stale payments to check`);

    for (const p of stale) {
      try {
        await this.reconcileOnePayment(p);
      } catch (err) {
        console.error('[Reconciler] failed for payment', p.id, err);
      }
    }
  }

  private static async reconcileOnePayment(p: Payment): Promise<void> {
    const rzp = (await RazorpayService.fetchPaymentsForOrder(p.razorpayOrderId)) as unknown as {
      items?: Array<Record<string, unknown>>;
    };
    const items = rzp.items ?? [];

    // Prefer a captured payment; else most recent.
    const captured = items.find((x) => x.status === 'captured');
    const authorized = items.find((x) => x.status === 'authorized');
    const failed = items.find((x) => x.status === 'failed');
    const latest = captured ?? authorized ?? failed ?? items[items.length - 1];

    if (!latest) {
      // No payment attempted at all — if row is very old, mark failed and release inventory.
      const ageMs = Date.now() - p.createdAt.getTime();
      if (ageMs > 60 * 60 * 1000) {
        await this.markPaymentFailed(p, 'RECONCILER_TIMEOUT');
      }
      return;
    }

    const latestStatus = latest.status as string;
    const latestId = latest.id as string;
    const latestAmount = Number(latest.amount);

    if (latestStatus === 'captured') {
      // Feed it through the webhook handler logic for a consistent transition.
      const synthesized = synthesizePaymentCapturedEvent(p.razorpayOrderId, latestId, latestAmount);
      await PaymentsV2Service.handleWebhook(synthesized);
      console.log(`[Reconciler] fixed missing payment.captured for ${p.razorpayOrderId}`);
      return;
    }

    if (latestStatus === 'failed') {
      const synthesized = synthesizePaymentFailedEvent(p.razorpayOrderId, latestId, latestAmount);
      await PaymentsV2Service.handleWebhook(synthesized);
      console.log(`[Reconciler] marked failed for ${p.razorpayOrderId}`);
      return;
    }

    // authorized / created / else — not terminal yet, leave for next tick.
  }

  private static async markPaymentFailed(p: Payment, code: string): Promise<void> {
    const paymentRepo = AppDataSource.getRepository(Payment);
    p.status = 'failed';
    p.failureCode = code;
    await paymentRepo.save(p);

    const orderRepo = AppDataSource.getRepository(Order);
    const order = await orderRepo.findOne({
      where: { id: p.orderId },
      relations: ['items', 'items.product', 'items.variant'],
    });
    if (order && order.status === 'pending') {
      await OrderInventoryService.restoreReservedStockForItems(order.items);
      order.status = 'cancelled';
      order.paymentStatus = 'failed';
      await orderRepo.save(order);
    }
  }

  /**
   * Refunds stuck in `pending` for >30 min — fetch state from Razorpay.
   */
  private static async reconcilePendingRefunds(): Promise<void> {
    const refundRepo = AppDataSource.getRepository(Refund);
    const cutoff = new Date(Date.now() - 30 * 60 * 1000);

    const pending = await refundRepo.find({
      where: { status: 'pending', createdAt: LessThan(cutoff) },
      take: 200,
    });

    for (const r of pending) {
      try {
        if (!r.razorpayRefundId) continue; // Razorpay call never succeeded; leave alone.
        const rzpRefund = (await RazorpayService.fetchRefund(r.razorpayRefundId)) as {
          status?: string;
        };
        if (rzpRefund.status === 'processed') {
          r.status = 'processed';
          await refundRepo.save(r);
          // Delegated: handles idempotent state transition + FCM notification in one place.
          await PaymentsV2Service.markPaymentRefunded(r.paymentId);
        } else if (rzpRefund.status === 'failed') {
          r.status = 'failed';
          await refundRepo.save(r);
        }
      } catch (err) {
        console.error('[Reconciler] refund check failed', r.id, err);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Synthesize the event envelope the webhook handler expects.
// ---------------------------------------------------------------------------

function synthesizePaymentCapturedEvent(
  razorpayOrderId: string,
  razorpayPaymentId: string,
  amountPaise: number
): { eventId: string; eventType: string; payload: Record<string, unknown> } {
  return {
    eventId: `reconciler:captured:${razorpayPaymentId}`,
    eventType: 'payment.captured',
    payload: {
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: razorpayPaymentId,
            order_id: razorpayOrderId,
            amount: amountPaise,
            status: 'captured',
          },
        },
      },
    },
  };
}

function synthesizePaymentFailedEvent(
  razorpayOrderId: string,
  razorpayPaymentId: string,
  amountPaise: number
): { eventId: string; eventType: string; payload: Record<string, unknown> } {
  return {
    eventId: `reconciler:failed:${razorpayPaymentId}`,
    eventType: 'payment.failed',
    payload: {
      event: 'payment.failed',
      payload: {
        payment: {
          entity: {
            id: razorpayPaymentId,
            order_id: razorpayOrderId,
            amount: amountPaise,
            status: 'failed',
            error_code: 'PAYMENT_FAILED',
          },
        },
      },
    },
  };
}
