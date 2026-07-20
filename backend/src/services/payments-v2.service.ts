import crypto from 'crypto';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { Payment, PaymentStatus } from '../entities/Payment';
import { Refund } from '../entities/Refund';
import { WebhookEvent } from '../entities/WebhookEvent';
import { RazorpayService } from './razorpay.service';
import { RedisService } from './redis.service';
import { OrderInventoryService } from './order-inventory.service';
import { FCMService } from './fcm.service';
import { enqueuePaymentCheck } from './queue/payment-queue';

/**
 * Payment orchestration.
 *
 * All state transitions live here. Both the verify endpoint and the webhook handler
 * call into the same transition function, so they're guaranteed to apply the same
 * rules and can safely race each other — the last legitimate writer wins.
 *
 * Amounts: always paise (integer). Order.totalAmount is kept in rupees-decimal for
 * backward compatibility with the mobile app; we convert once, at the boundary.
 */
export class PaymentsV2Service {
  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  static toPaise(rupeesDecimal: number | string): number {
    const n = typeof rupeesDecimal === 'string' ? parseFloat(rupeesDecimal) : rupeesDecimal;
    if (!Number.isFinite(n) || n < 0) throw new Error(`Invalid amount: ${rupeesDecimal}`);
    return Math.round(n * 100);
  }

  /** Forward-only state machine. Returns true if the transition is legal. */
  private static canTransition(from: PaymentStatus, to: PaymentStatus): boolean {
    const allowed: Record<PaymentStatus, PaymentStatus[]> = {
      initiated: ['success_unverified', 'paid', 'failed'],
      success_unverified: ['paid', 'failed'],
      paid: ['refund_pending'],
      failed: [],
      refund_pending: ['refunded', 'paid'],
      refunded: [],
    };
    if (from === to) return true;
    return allowed[from].includes(to);
  }

  // -----------------------------------------------------------------------
  // 1. Initiate payment — called from order creation or /payment/create-order
  // -----------------------------------------------------------------------

  /**
   * Create (or reuse) a Razorpay order for the given internal order.
   * Idempotent: if an `initiated` payment row exists for this order and is fresh (<15m),
   * return that one instead of creating a new Razorpay order.
   */
  static async initiatePayment(params: {
    orderId: number;
    userId: number;
    amountPaise: number;
  }): Promise<{
    razorpayOrderId: string;
    amountPaise: number;
    currency: string;
    keyId: string;
  }> {
    const paymentRepo = AppDataSource.getRepository(Payment);

    const fifteenMinAgo = new Date(Date.now() - 15 * 60 * 1000);
    const existing = await paymentRepo
      .createQueryBuilder('p')
      .where('p.orderId = :oid', { oid: params.orderId })
      .andWhere('p.status = :st', { st: 'initiated' })
      .andWhere('p.createdAt > :cutoff', { cutoff: fifteenMinAgo })
      .orderBy('p.id', 'DESC')
      .getOne();

    if (existing) {
      if (existing.amountPaise !== String(params.amountPaise)) {
        // Amount changed mid-checkout (cart edited). Abandon the old one and create a new.
        existing.status = 'failed';
        existing.failureCode = 'AMOUNT_CHANGED';
        await paymentRepo.save(existing);
      } else {
        return {
          razorpayOrderId: existing.razorpayOrderId,
          amountPaise: Number(existing.amountPaise),
          currency: existing.currency,
          keyId: process.env.RAZORPAY_KEY_ID ?? '',
        };
      }
    }

    const rzpOrder = await RazorpayService.createOrder({
      amountPaise: params.amountPaise,
      receipt: `order_${params.orderId}`,
      notes: { order_id: String(params.orderId), user_id: String(params.userId) },
    });

    const payment = paymentRepo.create({
      orderId: params.orderId,
      userId: params.userId,
      razorpayOrderId: rzpOrder.id,
      razorpayPaymentId: null,
      amountPaise: String(params.amountPaise),
      currency: 'INR',
      status: 'initiated',
      failureCode: null,
      rawWebhookJson: null,
    });
    await paymentRepo.save(payment);

    // Mirror on the order for quick filtering without a join.
    await AppDataSource.getRepository(Order).update(
      { id: params.orderId },
      { paymentStatus: 'initiated' }
    );

    // Schedule a fast, restart-proof fallback check. Best-effort: if the enqueue
    // fails, the order is still created and the 30-min reconciler still catches it.
    // The webhook remains the primary confirmation path.
    enqueuePaymentCheck(String(payment.id), rzpOrder.id).catch((e) =>
      console.error('[payment] enqueue reconcile job failed', e)
    );

    return {
      razorpayOrderId: rzpOrder.id,
      amountPaise: params.amountPaise,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID ?? '',
    };
  }

  // -----------------------------------------------------------------------
  // 2. Verify — called from client after checkout.js succeeds
  // -----------------------------------------------------------------------

  /**
   * The client-verify path. Never a source of truth; only advances state to
   * `success_unverified` pending the webhook (or reconciler) promoting to `paid`.
   * That way, a spoofed verify cannot confirm the order on its own.
   */
  static async handleVerify(params: {
    userId: number;
    razorpayOrderId: string;
    razorpayPaymentId: string;
    signature: string;
  }): Promise<{ ok: true; status: PaymentStatus } | { ok: false; reason: string; code: number }> {
    const sigOk = RazorpayService.verifyCheckoutSignature({
      razorpayOrderId: params.razorpayOrderId,
      razorpayPaymentId: params.razorpayPaymentId,
      signature: params.signature,
    });
    if (!sigOk) {
      console.warn('[verify] signature mismatch', {
        rzpOrder: params.razorpayOrderId,
        user: params.userId,
      });
      return { ok: false, reason: 'Invalid signature', code: 400 };
    }

    const paymentRepo = AppDataSource.getRepository(Payment);
    const payment = await paymentRepo.findOne({
      where: { razorpayOrderId: params.razorpayOrderId },
    });
    if (!payment) return { ok: false, reason: 'Payment not found', code: 404 };

    // Ownership check — a user may only verify their own payment.
    if (payment.userId !== params.userId) {
      console.warn('[verify] ownership mismatch', {
        rzpOrder: params.razorpayOrderId,
        reqUser: params.userId,
        payUser: payment.userId,
      });
      return { ok: false, reason: 'Forbidden', code: 403 };
    }

    // Replay guard: a given razorpay_payment_id can only ever belong to one row.
    if (payment.razorpayPaymentId && payment.razorpayPaymentId !== params.razorpayPaymentId) {
      return { ok: false, reason: 'Payment id mismatch', code: 409 };
    }

    // Advance to success_unverified. If webhook already promoted to 'paid', leave it.
    if (payment.status === 'paid' || payment.status === 'refunded') {
      return { ok: true, status: payment.status };
    }

    if (payment.status === 'failed') {
      return { ok: false, reason: 'Payment already failed', code: 409 };
    }

    payment.razorpayPaymentId = params.razorpayPaymentId;
    if (this.canTransition(payment.status, 'success_unverified')) {
      payment.status = 'success_unverified';
    }
    await paymentRepo.save(payment);

    await AppDataSource.getRepository(Order).update(
      { id: payment.orderId },
      { paymentStatus: payment.status }
    );

    return { ok: true, status: payment.status };
  }

  // -----------------------------------------------------------------------
  // 3. Webhook — the authoritative path
  // -----------------------------------------------------------------------

  /**
   * Process a Razorpay webhook. Caller must have already verified the signature
   * and read the raw body.
   *
   * Idempotency: backed by UNIQUE(event_id) on webhook_events.
   * Concurrency: backed by a short Redis lock per razorpay_order_id, so verify
   *              and webhook can't both transition the same row at once.
   */
  static async handleWebhook(params: {
    eventId: string;
    eventType: string;
    payload: Record<string, unknown>;
  }): Promise<{ processed: boolean; reason?: string }> {
    const eventRepo = AppDataSource.getRepository(WebhookEvent);

    // Insert event row first — UNIQUE(event_id) is our atomic dedupe.
    try {
      const ev = eventRepo.create({
        eventId: params.eventId,
        eventType: params.eventType,
        payload: params.payload,
        processedAt: null,
      });
      await eventRepo.save(ev);
    } catch (err: unknown) {
      if (isDuplicateKeyError(err)) {
        // A row for this event already exists. If it finished (processedAt set),
        // this is a genuine duplicate → skip. If processedAt is still null, a prior
        // attempt inserted the row but crashed before completing; fall through and
        // re-run the processing below. All transitions are idempotent, so replaying
        // is safe and lets Razorpay's retry actually recover the stuck event.
        const existing = await eventRepo.findOne({ where: { eventId: params.eventId } });
        if (existing?.processedAt != null) {
          return { processed: false, reason: 'duplicate_event' };
        }
        // else: fall through to lock + processing
      } else {
        throw err;
      }
    }

    // Best-effort cross-process lock so verify doesn't race us mid-transition.
    const razorpayOrderId = extractRazorpayOrderId(params.payload);
    const lockKey = razorpayOrderId ? `lock:payment:${razorpayOrderId}` : null;
    let lockToken: string | null = null;
    if (lockKey) {
      lockToken = await acquireLock(lockKey, 30);
      if (!lockToken) {
        // Returning without processing; Razorpay will retry the webhook.
        return { processed: false, reason: 'busy' };
      }
    }

    try {
      switch (params.eventType) {
        case 'payment.captured':
          await this.onPaymentCaptured(params.payload);
          break;
        case 'payment.failed':
          await this.onPaymentFailed(params.payload);
          break;
        case 'refund.processed':
          await this.onRefundProcessed(params.payload);
          break;
        case 'refund.failed':
          await this.onRefundFailed(params.payload);
          break;
        default:
          // Known events we don't act on (order.paid, refund.created, etc.).
          break;
      }

      await eventRepo.update({ eventId: params.eventId }, { processedAt: new Date() });
      return { processed: true };
    } finally {
      if (lockKey && lockToken) await releaseLock(lockKey, lockToken);
    }
  }

  /**
   * Promote a payment from initiated/success_unverified → paid and confirm the order.
   * Idempotent. Caller is responsible for the amount-matches-expected check.
   * Shared between the webhook handler (after its amount guard) and the reconciler
   * (which guards explicitly before calling).
   */
  static async markPaymentPaid(
    payment: Payment,
    razorpayPaymentId: string | null,
    rawPayload: Record<string, unknown> | null = null
  ): Promise<void> {
    if (payment.status === 'paid' || payment.status === 'refunded') return;
    if (!this.canTransition(payment.status, 'paid')) return;

    // Atomic: payment + order move to paid together, or neither does. Without the
    // transaction, an order-save failure after the payment-save would leave payment
    // 'paid' (terminal, so the reconciler ignores it) while the order stays pending.
    let paidOnCancelledOrder = false;
    await AppDataSource.transaction(async (mgr) => {
      payment.status = 'paid';
      if (razorpayPaymentId) payment.razorpayPaymentId = razorpayPaymentId;
      if (rawPayload) payment.rawWebhookJson = rawPayload;
      await mgr.getRepository(Payment).save(payment);

      const order = await mgr.getRepository(Order).findOne({ where: { id: payment.orderId } });
      if (order) {
        if (order.status === 'pending') {
          order.status = 'accepted';
        }
        // Payment landed AFTER the order was already cancelled (classic case: the
        // 30-min auto-cancel fired, then the customer completed a slow UPI payment).
        // Goods are gone/stock released — record the payment truthfully, then refund.
        if (order.status === 'cancelled') {
          paidOnCancelledOrder = true;
        }
        order.paymentStatus = 'paid';
        order.isPaid = true;
        if (razorpayPaymentId) order.paymentId = razorpayPaymentId;
        await mgr.getRepository(Order).save(order);
      }
    });

    // Outside the transaction (createRefund has its own lock/transaction): auto-refund
    // a payment that confirmed on an order we can no longer fulfil. Idempotent via the
    // fixed key, so webhook + reconciler both landing here can't double-refund.
    if (paidOnCancelledOrder) {
      try {
        await this.createRefund({
          orderId: payment.orderId,
          userId: payment.userId,
          actorUserId: payment.userId,
          reason: 'late_payment_on_cancelled_order',
          idempotencyKey: `late-cancel-${payment.orderId}`,
        });
        console.log(`[payment] auto-refund issued for late payment on cancelled order #${payment.orderId}`);
      } catch (e) {
        console.error(`[payment] auto-refund failed for cancelled order #${payment.orderId}`, e);
      }
    }
  }

  /**
   * Demote a payment to failed and release reserved inventory.
   * Idempotent — bails on rows that are already terminal, and only restores stock
   * when the order is still pending (so duplicate calls can't double-credit inventory).
   * Shared between the webhook handler, the amount-mismatch path, and the reconciler.
   */
  static async markPaymentFailed(
    payment: Payment,
    code: string,
    rawPayload: Record<string, unknown> | null = null
  ): Promise<void> {
    if (payment.status === 'failed' || payment.status === 'refunded') return;
    if (!this.canTransition(payment.status, 'failed')) return;

    // Atomic: marking the payment failed, restoring reserved stock, and cancelling
    // the order all commit together. Otherwise a crash after the payment-save would
    // leave payment 'failed' (terminal → reconciler skips it) with stock still
    // reserved and the order stuck pending.
    await AppDataSource.transaction(async (mgr) => {
      payment.status = 'failed';
      payment.failureCode = code;
      if (rawPayload) payment.rawWebhookJson = rawPayload;
      await mgr.getRepository(Payment).save(payment);

      const order = await mgr.getRepository(Order).findOne({
        where: { id: payment.orderId },
        relations: ['items', 'items.product', 'items.variant'],
      });
      if (order && order.status === 'pending') {
        await OrderInventoryService.restoreReservedStockForItems(order.items, mgr);
        order.status = 'cancelled';
        order.paymentStatus = 'failed';
        await mgr.getRepository(Order).save(order);
      }
    });
  }

  /**
   * Run `fn` while holding the per-razorpay-order lock used by the webhook handler.
   * Lets external callers (the reconciler) coordinate with live webhook processing
   * so they don't race on the same payment row.
   * Returns { ran: false } if the lock is busy — caller should retry next tick.
   */
  static async withPaymentLock<T>(
    razorpayOrderId: string,
    fn: () => Promise<T>
  ): Promise<{ ran: true; result: T } | { ran: false }> {
    const lockKey = `lock:payment:${razorpayOrderId}`;
    const lockToken = await acquireLock(lockKey, 30);
    if (!lockToken) return { ran: false };
    try {
      const result = await fn();
      return { ran: true, result };
    } finally {
      await releaseLock(lockKey, lockToken);
    }
  }

  private static async onPaymentCaptured(payload: Record<string, unknown>): Promise<void> {
    const entity = readPaymentEntity(payload);
    if (!entity) return;

    const paymentRepo = AppDataSource.getRepository(Payment);
    const payment = await paymentRepo.findOne({
      where: { razorpayOrderId: entity.order_id },
    });
    if (!payment) {
      console.warn('[webhook] payment.captured for unknown rzp_order_id', entity.order_id);
      return;
    }

    // Amount check — refuse to confirm if Razorpay says a different amount than we priced.
    if (String(entity.amount) !== payment.amountPaise) {
      console.error('[webhook] AMOUNT MISMATCH', {
        rzpOrder: entity.order_id,
        expected: payment.amountPaise,
        received: entity.amount,
      });
      await this.markPaymentFailed(payment, 'AMOUNT_MISMATCH', payload);
      return;
    }

    await this.markPaymentPaid(payment, entity.id ?? null, payload);
  }

  private static async onPaymentFailed(payload: Record<string, unknown>): Promise<void> {
    const entity = readPaymentEntity(payload);
    if (!entity) return;

    const paymentRepo = AppDataSource.getRepository(Payment);
    const payment = await paymentRepo.findOne({
      where: { razorpayOrderId: entity.order_id },
    });
    if (!payment) return;

    const code = (entity.error_code as string | undefined) ?? 'PAYMENT_FAILED';
    await this.markPaymentFailed(payment, code, payload);
  }

  private static async onRefundProcessed(payload: Record<string, unknown>): Promise<void> {
    const entity = readRefundEntity(payload);
    if (!entity) return;

    const refundRepo = AppDataSource.getRepository(Refund);
    const refund = await refundRepo.findOne({ where: { razorpayRefundId: entity.id } });
    if (!refund) {
      console.warn('[webhook] refund.processed for unknown razorpay_refund_id', entity.id);
      return;
    }

    refund.status = 'processed';
    await refundRepo.save(refund);

    await this.markPaymentRefunded(refund.paymentId);
  }

  /**
   * Transition payment + order to `refunded` and notify the customer.
   * Idempotent — if the payment is already `refunded`, returns without re-saving or re-notifying.
   * Called from both the webhook (`refund.processed`) and the reconciler path.
   */
  static async markPaymentRefunded(paymentId: string): Promise<void> {
    const paymentRepo = AppDataSource.getRepository(Payment);
    const payment = await paymentRepo.findOne({ where: { id: paymentId } });
    if (!payment) return;

    // Already terminal → no-op. Guards against double notifications when the webhook
    // and the reconciler both discover the refund around the same time.
    if (payment.status === 'refunded') return;
    if (!this.canTransition(payment.status, 'refunded')) return;

    // Atomic: payment + order move to refunded together. If only the payment save
    // landed and the order update threw, the payment would be terminal (reconciler
    // skips it) while the order still shows the old paymentStatus.
    await AppDataSource.transaction(async (mgr) => {
      payment.status = 'refunded';
      await mgr.getRepository(Payment).save(payment);
      await mgr.getRepository(Order).update(
        { id: payment.orderId },
        { paymentStatus: 'refunded' }
      );
    });

    // Notify the customer their refund has completed. Enqueued AFTER the commit so a
    // rolled-back transaction can never fire a "refund completed" notification.
    const order = await AppDataSource.getRepository(Order).findOne({
      where: { id: payment.orderId },
      relations: ['user'],
    });
    const user = order?.user;
    if (user?.id != null) {
      const amountRupees = (Number(payment.amountPaise) / 100).toFixed(2);
      FCMService.enqueue(
        () =>
          FCMService.sendNotificationToUser(
            user.id,
            '💰 Refund Completed',
            `₹${amountRupees} has been refunded for order #${payment.orderId}. It should reflect in your account within 2–7 working days.`,
            {
              orderId: String(payment.orderId),
              paymentId: String(payment.id),
              type: 'refund_completed',
            }
          ),
        `notify refund completed order=#${payment.orderId} user=${user.id}`
      );
    }
  }

  private static async onRefundFailed(payload: Record<string, unknown>): Promise<void> {
    const entity = readRefundEntity(payload);
    if (!entity) return;
    const refundRepo = AppDataSource.getRepository(Refund);
    await refundRepo.update({ razorpayRefundId: entity.id }, { status: 'failed' });
  }

  // -----------------------------------------------------------------------
  // 4. Refund
  // -----------------------------------------------------------------------

  static async createRefund(params: {
    orderId: number;
    userId: number;
    actorUserId: number;
    reason?: string;
    idempotencyKey: string;
  }): Promise<
    | { ok: true; refundId: string; razorpayRefundId: string | null }
    | { ok: false; reason: string; code: number }
  > {
    type RefundResult =
      | { ok: true; refundId: string; razorpayRefundId: string | null }
      | { ok: false; reason: string; code: number };

    const paymentRepo = AppDataSource.getRepository(Payment);
    const refundRepo = AppDataSource.getRepository(Refund);

    const payment = await paymentRepo.findOne({
      where: { orderId: params.orderId, userId: params.userId, status: 'paid' },
      order: { id: 'DESC' },
    });
    if (!payment || !payment.razorpayPaymentId) {
      return { ok: false, reason: 'No paid payment found for order', code: 404 };
    }
    const razorpayPaymentId = payment.razorpayPaymentId;

    // Fast path: idempotent retry from the same client with the same key.
    // The cross-flow guard below uses the same lookup but inside the lock; this
    // outer check saves a lock acquisition for the common retry case.
    const existing = await refundRepo.findOne({
      where: { paymentId: payment.id, idempotencyKey: params.idempotencyKey },
    });
    if (existing) {
      return {
        ok: true,
        refundId: existing.id,
        razorpayRefundId: existing.razorpayRefundId,
      };
    }

    // Hold the payment-level lock while we check the invariant and create the
    // refund. Without this lock, two simultaneous calls with *different* keys
    // (e.g. customer-initiated + admin-cancel) could both read sum=0, both
    // create refund rows, and both call Razorpay → customer is refunded twice.
    const locked = await this.withPaymentLock(
      payment.razorpayOrderId,
      async (): Promise<RefundResult> => {
        // Re-check same-key existence inside the lock: a parallel caller with
        // the same key may have completed between our outer check and lock acquire.
        const sameKey = await refundRepo.findOne({
          where: { paymentId: payment.id, idempotencyKey: params.idempotencyKey },
        });
        if (sameKey) {
          return {
            ok: true,
            refundId: sameKey.id,
            razorpayRefundId: sameKey.razorpayRefundId,
          };
        }

        // Invariant: total non-failed refunds (pending + processed) for a payment
        // must never exceed payment.amountPaise. This catches the double-refund
        // race regardless of what idempotency key the second caller used.
        const sumRow = await refundRepo
          .createQueryBuilder('r')
          .select('COALESCE(SUM(r.amountPaise), 0)', 'sum')
          .where('r.paymentId = :pid', { pid: payment.id })
          .andWhere('r.status IN (:...statuses)', { statuses: ['pending', 'processed'] })
          .getRawOne<{ sum: string | null }>();
        const activeSum = Number(sumRow?.sum ?? 0);
        const newAmount = Number(payment.amountPaise);
        const cap = Number(payment.amountPaise);
        if (activeSum + newAmount > cap) {
          return {
            ok: false,
            reason: 'Refund already issued or in progress for this payment',
            code: 409,
          };
        }

        // Insert refund row first (pending). If the DB write wins but Razorpay
        // call loses, the reconciler will pick it up.
        const refund = refundRepo.create({
          paymentId: payment.id,
          userId: params.userId,
          razorpayRefundId: null,
          amountPaise: payment.amountPaise,
          status: 'pending',
          reason: params.reason ?? null,
          idempotencyKey: params.idempotencyKey,
        });
        try {
          await refundRepo.save(refund);
        } catch (err) {
          if (isDuplicateKeyError(err)) {
            const again = await refundRepo.findOne({
              where: { paymentId: payment.id, idempotencyKey: params.idempotencyKey },
            });
            if (again) {
              return {
                ok: true,
                refundId: again.id,
                razorpayRefundId: again.razorpayRefundId,
              };
            }
          }
          throw err;
        }

        // Transition payment → refund_pending (best-effort, idempotent).
        if (this.canTransition(payment.status, 'refund_pending')) {
          payment.status = 'refund_pending';
          await paymentRepo.save(payment);
          await AppDataSource.getRepository(Order).update(
            { id: payment.orderId },
            { paymentStatus: 'refund_pending' }
          );
        }

        // Call Razorpay.
        try {
          const rzpRefund = await RazorpayService.createRefund({
            razorpayPaymentId,
            amountPaise: Number(payment.amountPaise),
            notes: { refund_id: refund.id, order_id: String(params.orderId) },
            idempotencyKey: params.idempotencyKey,
          });
          refund.razorpayRefundId = (rzpRefund as { id: string }).id;
          await refundRepo.save(refund);
        } catch (err) {
          console.error('[refund] razorpay call failed — reconciler will retry', err);
          // Don't mark failed here; reconciler will verify actual Razorpay state.
        }

        return {
          ok: true,
          refundId: refund.id,
          razorpayRefundId: refund.razorpayRefundId,
        };
      }
    );

    if (!locked.ran) {
      return {
        ok: false,
        reason: 'Another refund operation is in progress for this payment. Please retry shortly.',
        code: 409,
      };
    }
    return locked.result;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function extractRazorpayOrderId(payload: Record<string, unknown>): string | null {
  const p = readPaymentEntity(payload);
  if (p?.order_id) return p.order_id;
  const r = readRefundEntity(payload);
  return r?.order_id ?? null;
}

function readPaymentEntity(
  payload: Record<string, unknown>
): { id: string; order_id: string; amount: number; error_code?: string } | null {
  const payloadObj = payload.payload as Record<string, unknown> | undefined;
  const wrapper = payloadObj?.payment as Record<string, unknown> | undefined;
  const entity = wrapper?.entity as Record<string, unknown> | undefined;
  if (!entity) return null;
  return {
    id: entity.id as string,
    order_id: entity.order_id as string,
    amount: Number(entity.amount),
    error_code: entity.error_code as string | undefined,
  };
}

function readRefundEntity(
  payload: Record<string, unknown>
): { id: string; payment_id: string; order_id?: string; amount: number } | null {
  const payloadObj = payload.payload as Record<string, unknown> | undefined;
  const wrapper = payloadObj?.refund as Record<string, unknown> | undefined;
  const entity = wrapper?.entity as Record<string, unknown> | undefined;
  if (!entity) return null;
  return {
    id: entity.id as string,
    payment_id: entity.payment_id as string,
    order_id: entity.order_id as string | undefined,
    amount: Number(entity.amount),
  };
}

function isDuplicateKeyError(err: unknown): boolean {
  const e = err as { code?: string; errno?: number } | null;
  return e?.code === 'ER_DUP_ENTRY' || e?.errno === 1062;
}

async function acquireLock(key: string, ttlSeconds: number): Promise<string | null> {
  const token = crypto.randomBytes(16).toString('hex');
  const client = await RedisService.getClient();
  const ok = await client.set(key, token, { NX: true, EX: ttlSeconds });
  return ok === 'OK' ? token : null;
}

async function releaseLock(key: string, _token: string): Promise<void> {
  // TTL-bounded (30s) so stale locks self-heal. Plain DEL is safe here because the
  // handler path is sub-second; in the worst case another holder's release no-ops.
  try {
    await RedisService.del(key);
  } catch {
    // ignore
  }
}
