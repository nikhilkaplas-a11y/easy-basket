import crypto from 'crypto';
import { In } from 'typeorm';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { Payment, PaymentStatus } from '../entities/Payment';
import { Refund, RefundStatus } from '../entities/Refund';
import { WebhookEvent } from '../entities/WebhookEvent';
import { RazorpayService } from './razorpay.service';
import { RedisService } from './redis.service';
import { OrderInventoryService } from './order-inventory.service';
import { FCMService } from './fcm.service';
import { enqueuePaymentCheck } from './queue/payment-queue';
import {
  enqueueRefundRetry,
  REFUND_RESCHEDULE_DELAY_MS,
  REFUND_RETRY_DELAY_MS,
} from './queue/refund-queue';

/**
 * Total times we will POST a given refund to Razorpay automatically:
 * the inline attempt during createRefund, plus one scheduled retry.
 * Once exhausted the refund row parks at status='failed' and an admin drives
 * further attempts from the "Retry refund" button (one click = one attempt).
 */
export const MAX_REFUND_ATTEMPTS = Number(process.env.MAX_REFUND_ATTEMPTS) || 2;

export interface RefundSuccess {
  ok: true;
  refundId: string;
  razorpayRefundId: string | null;
  refundStatus: RefundStatus;
  attemptCount: number;
  lastError: string | null;
}

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
    // A refund is in flight. `canTransition` permits refund_pending → paid (that edge
    // exists so a *failed* refund can release the payment), but reaching it from here
    // would silently un-refund a live refund and, on the auto-refund path, ping-pong
    // the payment between paid and refund_pending on every reconciler tick.
    if (payment.status === 'refund_pending') return;
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

  /**
   * Razorpay accepted the refund but it later failed (bank rejected it, account
   * frozen, …). No money moved, so this feeds the same retry budget as a failed
   * API call: retry once automatically, then park at 'failed' for the admin button
   * and release the payment back to `paid`.
   *
   * Previously this only stamped the refund row `failed`, leaving the payment and
   * order pinned at `refund_pending` with nothing able to move them again.
   */
  private static async onRefundFailed(payload: Record<string, unknown>): Promise<void> {
    const entity = readRefundEntity(payload);
    if (!entity) return;

    const refundRepo = AppDataSource.getRepository(Refund);
    const refund = await refundRepo.findOne({ where: { razorpayRefundId: entity.id } });
    if (!refund) {
      console.warn('[webhook] refund.failed for unknown razorpay_refund_id', entity.id);
      return;
    }
    if (refund.status === 'processed') return; // already settled — ignore a stale event

    const payment = await AppDataSource.getRepository(Payment).findOne({
      where: { id: refund.paymentId },
    });
    if (!payment) {
      await refundRepo.update({ id: refund.id }, { status: 'failed' });
      return;
    }

    await this.recordRefundFailure(refund, payment, 'Razorpay reported refund.failed');
  }

  // -----------------------------------------------------------------------
  // 4. Refund
  // -----------------------------------------------------------------------

  /**
   * POST one refund attempt to Razorpay, with the bookkeeping that makes retrying safe.
   *
   * CRITICAL — adopt before create. Razorpay does NOT treat `receipt` as an
   * idempotency key, so if a previous attempt timed out *after* Razorpay created
   * the refund, blindly POSTing again would issue a SECOND real refund. We first
   * ask Razorpay what refunds already exist for this payment and adopt any that
   * carries our refund id in `notes.refund_id`.
   *
   * Mutates and saves `refund`. Never throws — failure is recorded on the row.
   */
  private static async attemptRazorpayRefund(
    refund: Refund,
    payment: Payment,
    razorpayPaymentId: string
  ): Promise<void> {
    const refundRepo = AppDataSource.getRepository(Refund);

    refund.attemptCount += 1;
    refund.lastAttemptAt = new Date();

    try {
      // 1) Adopt an existing Razorpay refund for this row, if one is already there.
      const adopted = await this.findExistingRazorpayRefund(razorpayPaymentId, refund.id);
      if (adopted) {
        console.warn(
          `[refund] adopted existing Razorpay refund ${adopted.id} for refund ${refund.id} — previous attempt succeeded despite erroring`
        );
        refund.razorpayRefundId = adopted.id;
        refund.lastError = null;
        refund.nextRetryAt = null;
        if (adopted.status === 'processed') refund.status = 'processed';
        else if (adopted.status === 'failed') refund.status = 'failed';
        await refundRepo.save(refund);
        if (refund.status === 'processed') await this.markPaymentRefunded(refund.paymentId);
        return;
      }

      // 2) No existing refund — safe to create one.
      const rzpRefund = await RazorpayService.createRefund({
        razorpayPaymentId,
        amountPaise: Number(refund.amountPaise),
        notes: { refund_id: refund.id, order_id: String(payment.orderId) },
        idempotencyKey: refund.idempotencyKey,
      });

      refund.razorpayRefundId = (rzpRefund as { id: string }).id;
      refund.status = 'pending';
      refund.lastError = null;
      refund.nextRetryAt = null;
      await refundRepo.save(refund);
      console.log(
        `[refund] created Razorpay refund ${refund.razorpayRefundId} for order #${payment.orderId} (attempt ${refund.attemptCount})`
      );
    } catch (err) {
      await this.recordRefundFailure(refund, payment, describeError(err));
    }
  }

  /**
   * Look up a refund Razorpay already holds for this payment that belongs to our row.
   * Matches on `notes.refund_id` (which we always send), falling back to `receipt`.
   * Returns null if the lookup itself fails — the caller then treats the attempt as
   * failed rather than risking a duplicate refund.
   */
  private static async findExistingRazorpayRefund(
    razorpayPaymentId: string,
    refundId: string
  ): Promise<{ id: string; status?: string } | null> {
    const list = (await RazorpayService.fetchRefundsForPayment(razorpayPaymentId)) as unknown as {
      items?: Array<{ id: string; status?: string; receipt?: string | null; notes?: unknown }>;
    };
    for (const item of list.items ?? []) {
      const notes = (item.notes ?? {}) as Record<string, unknown>;
      if (String(notes.refund_id ?? '') !== String(refundId)) continue;
      // A refund Razorpay itself marked `failed` moved no money (bank rejected it,
      // account frozen, …). Adopting it would make the retry a no-op that re-reports
      // the same failure forever, so we skip it and let a fresh refund be created.
      if (item.status === 'failed') continue;
      return item;
    }
    return null;
  }

  /**
   * Record a failed refund attempt: schedule the automatic retry if budget remains,
   * otherwise park the row at 'failed' for the admin button.
   *
   * When retries are exhausted the payment is released back to `paid` — no money
   * moved, so `refund_pending` would be a lie, and leaving it there is what used to
   * pin the order forever. `canTransition` already permits refund_pending → paid.
   */
  private static async recordRefundFailure(
    refund: Refund,
    payment: Payment,
    message: string
  ): Promise<void> {
    const refundRepo = AppDataSource.getRepository(Refund);
    refund.lastError = message.slice(0, 255);

    const hasBudget = refund.attemptCount < MAX_REFUND_ATTEMPTS;
    if (hasBudget) {
      refund.status = 'pending';
      refund.nextRetryAt = new Date(Date.now() + REFUND_RETRY_DELAY_MS);
      await refundRepo.save(refund);
      console.error(
        `[refund] attempt ${refund.attemptCount}/${MAX_REFUND_ATTEMPTS} failed for refund ${refund.id} — retrying in ${REFUND_RETRY_DELAY_MS}ms: ${message}`
      );
      // Best-effort: if Redis is down the 30-min reconciler sweep still picks this
      // row up via next_retry_at, so a queue outage delays the retry, never drops it.
      enqueueRefundRetry(
        refund.id,
        payment.razorpayOrderId,
        refund.attemptCount + 1
      ).catch((e) => console.error('[refund] enqueue retry failed', e));
      return;
    }

    refund.status = 'failed';
    refund.nextRetryAt = null;
    await refundRepo.save(refund);
    console.error(
      `[refund] refund ${refund.id} for order #${payment.orderId} FAILED after ${refund.attemptCount} attempts — awaiting admin retry: ${message}`
    );

    await this.releasePaymentFromRefundPending(payment);
    await this.notifyAdminsRefundFailed(payment, refund);
    await this.notifyCustomerRefundDelayed(payment, refund);
  }

  /**
   * Tell the customer their refund has not gone through.
   *
   * They were already told "refund is being processed — 2–7 working days" when the
   * cancellation was approved. Without this they would simply wait out that window
   * for money that is never coming. The copy deliberately does not blame the bank
   * or promise a date we cannot keep — it confirms we know and are acting.
   */
  private static async notifyCustomerRefundDelayed(
    payment: Payment,
    refund: Refund
  ): Promise<void> {
    const order = await AppDataSource.getRepository(Order).findOne({
      where: { id: payment.orderId },
      relations: ['user'],
    });
    const userId = order?.user?.id;
    if (userId == null) return;

    const amountRupees = (Number(refund.amountPaise) / 100).toFixed(2);
    FCMService.enqueue(
      () =>
        FCMService.sendNotificationToUser(
          userId,
          '⚠️ Refund Delayed',
          `We could not complete your ₹${amountRupees} refund for order #${payment.orderId}. Our team has been alerted and is sorting it out — you do not need to do anything.`,
          {
            orderId: String(payment.orderId),
            refundId: String(refund.id),
            type: 'refund_delayed',
          }
        ),
      `notify customer refund delayed order=#${payment.orderId} user=${userId}`
    );
  }

  /**
   * Move a payment out of `refund_pending` back to `paid` after a refund could not
   * be completed. Keeps the state machine honest (no money left the account) and
   * un-blocks a future refund attempt.
   */
  private static async releasePaymentFromRefundPending(payment: Payment): Promise<void> {
    if (payment.status !== 'refund_pending') return;
    if (!this.canTransition(payment.status, 'paid')) return;
    await AppDataSource.transaction(async (mgr) => {
      payment.status = 'paid';
      await mgr.getRepository(Payment).save(payment);
      await mgr
        .getRepository(Order)
        .update({ id: payment.orderId }, { paymentStatus: 'paid' });
    });
  }

  /**
   * Retry a refund that previously failed.
   *
   * Used by both the automatic retry worker and the admin "Retry refund" button.
   * `manual` clicks bypass the attempt budget (one click = one attempt) but still
   * go through the same adopt-before-create guard, so an admin mashing the button
   * cannot double-refund a customer.
   *
   * Returns `rescheduled` when the payment lock was busy — that is NOT a consumed
   * attempt, so a contended lock can never eat the customer's automatic retry.
   */
  static async retryRefund(params: {
    refundId: string;
    manual: boolean;
  }): Promise<
    | { ok: true; status: RefundStatus; razorpayRefundId: string | null }
    | { ok: false; reason: string; code: number }
    | { ok: false; rescheduled: true; reason: string; code: number }
  > {
    const refundRepo = AppDataSource.getRepository(Refund);
    const paymentRepo = AppDataSource.getRepository(Payment);

    const refund = await refundRepo.findOne({ where: { id: params.refundId } });
    if (!refund) return { ok: false, reason: 'Refund not found', code: 404 };

    // Terminal success — nothing to do. This is what disables the admin button.
    if (refund.status === 'processed') {
      return { ok: true, status: refund.status, razorpayRefundId: refund.razorpayRefundId };
    }

    if (!params.manual && refund.attemptCount >= MAX_REFUND_ATTEMPTS) {
      return { ok: false, reason: 'Automatic retries exhausted', code: 409 };
    }

    const payment = await paymentRepo.findOne({ where: { id: refund.paymentId } });
    if (!payment || !payment.razorpayPaymentId) {
      return { ok: false, reason: 'Parent payment missing a Razorpay payment id', code: 409 };
    }
    const razorpayPaymentId = payment.razorpayPaymentId;

    const locked = await this.withPaymentLock(payment.razorpayOrderId, async () => {
      // Re-read inside the lock: a concurrent webhook or retry may have resolved it.
      const fresh = await refundRepo.findOne({ where: { id: params.refundId } });
      if (!fresh || fresh.status === 'processed') return;
      await this.attemptRazorpayRefund(fresh, payment, razorpayPaymentId);
      return fresh;
    });

    if (!locked.ran) {
      // Busy lock is a reschedule, not an attempt — budget is untouched.
      await refundRepo.update(
        { id: refund.id },
        { nextRetryAt: new Date(Date.now() + REFUND_RESCHEDULE_DELAY_MS) }
      );
      enqueueRefundRetry(
        refund.id,
        payment.razorpayOrderId,
        refund.attemptCount + 1,
        REFUND_RESCHEDULE_DELAY_MS
      ).catch((e) => console.error('[refund] enqueue reschedule failed', e));
      return {
        ok: false,
        rescheduled: true,
        reason: 'Another payment operation is in progress — retry rescheduled.',
        code: 409,
      };
    }

    const after = locked.result ?? (await refundRepo.findOne({ where: { id: params.refundId } }));
    if (!after) return { ok: false, reason: 'Refund not found', code: 404 };
    return { ok: true, status: after.status, razorpayRefundId: after.razorpayRefundId };
  }

  /**
   * Degraded-mode refund: durably record that a refund is owed when we could not
   * take the payment lock because Redis is unreachable.
   *
   * Safety without the lock comes from `UNIQUE (payment_id, idempotency_key)` —
   * every caller on this path (admin-cancel, approve-cancel, RTO, late-payment)
   * uses a fixed per-order key, so a concurrent duplicate collides on insert and
   * is resolved to the same row rather than creating a second refund.
   *
   * The row lands `pending` with attempt_count 0, so the reconciler's backstop
   * sweep drives the actual Razorpay call once Redis recovers.
   */
  private static async recordRefundOwed(
    payment: Payment,
    params: { orderId: number; userId: number; reason?: string; idempotencyKey: string },
    cause: unknown
  ): Promise<RefundSuccess | { ok: false; reason: string; code: number }> {
    const refundRepo = AppDataSource.getRepository(Refund);
    const message = `Deferred — lock unavailable: ${describeError(cause)}`;
    console.error(
      `[refund] could not lock payment ${payment.id} for order #${params.orderId}; recording refund as owed`,
      cause
    );

    const refund = refundRepo.create({
      paymentId: payment.id,
      userId: params.userId,
      razorpayRefundId: null,
      amountPaise: payment.amountPaise,
      status: 'pending',
      reason: params.reason ?? null,
      idempotencyKey: params.idempotencyKey,
      attemptCount: 0,
      lastError: message.slice(0, 255),
      nextRetryAt: new Date(),
      lastAttemptAt: null,
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
            refundStatus: again.status,
            attemptCount: again.attemptCount,
            lastError: again.lastError,
          };
        }
      }
      // Could not even record it — let the caller see a real failure rather than
      // reporting a refund that does not exist anywhere.
      console.error('[refund] failed to record owed refund', err);
      return { ok: false, reason: 'Could not record refund — please retry', code: 503 };
    }

    // Mirror the normal path so the order reads as refunding rather than paid.
    // Best-effort: a DB-only write, no Redis involved.
    if (this.canTransition(payment.status, 'refund_pending')) {
      payment.status = 'refund_pending';
      await AppDataSource.getRepository(Payment).save(payment);
      await AppDataSource.getRepository(Order).update(
        { id: payment.orderId },
        { paymentStatus: 'refund_pending' }
      );
    }

    return {
      ok: true,
      refundId: refund.id,
      razorpayRefundId: null,
      refundStatus: refund.status,
      attemptCount: refund.attemptCount,
      lastError: refund.lastError,
    };
  }

  /**
   * Customer-facing refund view for one order.
   *
   * Deliberately narrower than `getRefundStateForOrder`: attempt counts and raw
   * Razorpay error strings are operational detail for admins, not something to
   * put in front of the person waiting for their money. What a customer needs is
   * how much, how far along, roughly when, and a reference they can quote.
   */
  static async getCustomerRefundForOrder(orderId: number): Promise<{
    status: RefundStatus;
    amountPaise: string;
    initiatedAt: string;
    /** Razorpay refund id — the reference a customer's bank will ask for. */
    referenceId: string | null;
    /** Razorpay has the refund; the 2–7 working day window applies from here. */
    acceptedByProvider: boolean;
    /** Automatic retries are spent and our team is on it. */
    needsAttention: boolean;
  } | null> {
    const state = await this.getRefundStateForOrder(orderId);
    if (!state) return null;
    return {
      status: state.status,
      amountPaise: state.amountPaise,
      initiatedAt: state.createdAt,
      referenceId: state.razorpayRefundId,
      acceptedByProvider: state.razorpayRefundId != null,
      needsAttention: state.status === 'failed',
    };
  }

  /**
   * Refund flags for a page of orders, in a single query.
   *
   * The orders list needs to show which orders have a broken refund — otherwise
   * the "Retry refund" button on the detail screen is only discoverable by
   * opening every order one at a time. Batched deliberately: a per-order lookup
   * here would be an N+1 across the whole admin list.
   *
   * Only the newest refund per order is reported, matching the detail screen.
   */
  static async getRefundFlagsForOrders(
    orderIds: number[]
  ): Promise<Map<number, { refundStatus: RefundStatus; refundNeedsAttention: boolean }>> {
    const out = new Map<number, { refundStatus: RefundStatus; refundNeedsAttention: boolean }>();
    if (orderIds.length === 0) return out;

    const rows = await AppDataSource.getRepository(Refund)
      .createQueryBuilder('r')
      .innerJoin(Payment, 'p', 'p.id = r.paymentId')
      .select('p.orderId', 'orderId')
      .addSelect('r.status', 'status')
      .addSelect('r.razorpayRefundId', 'razorpayRefundId')
      .addSelect('r.attemptCount', 'attemptCount')
      .where('p.orderId IN (:...ids)', { ids: orderIds })
      .orderBy('r.id', 'DESC')
      .getRawMany<{
        orderId: number;
        status: RefundStatus;
        razorpayRefundId: string | null;
        attemptCount: number;
      }>();

    for (const row of rows) {
      const orderId = Number(row.orderId);
      if (out.has(orderId)) continue; // rows are newest-first; keep the latest refund
      out.set(orderId, {
        refundStatus: row.status,
        // 'failed' is the state that needs a human: automatic retries are spent.
        refundNeedsAttention: row.status === 'failed',
      });
    }
    return out;
  }

  /**
   * Refund state for an order, shaped for the admin UI.
   *
   * `canRetry` is the single source of truth for the "Retry refund" button:
   * it is false once the refund is `processed` (which is what disables the
   * button), and false while an automatic retry is still pending, so an admin
   * cannot fire a manual attempt on top of a scheduled one.
   */
  static async getRefundStateForOrder(orderId: number): Promise<{
    refundId: string;
    status: RefundStatus;
    amountPaise: string;
    razorpayRefundId: string | null;
    attemptCount: number;
    maxAutoAttempts: number;
    lastError: string | null;
    nextRetryAt: string | null;
    reason: string | null;
    canRetry: boolean;
    createdAt: string;
  } | null> {
    const payments = await AppDataSource.getRepository(Payment).find({
      where: { orderId },
      select: ['id'],
    });
    if (payments.length === 0) return null;

    const refund = await AppDataSource.getRepository(Refund).findOne({
      where: payments.map((p) => ({ paymentId: p.id })),
      order: { id: 'DESC' },
    });
    if (!refund) return null;

    const autoRetryPending =
      refund.status === 'pending' &&
      refund.razorpayRefundId == null &&
      refund.attemptCount < MAX_REFUND_ATTEMPTS;

    return {
      refundId: refund.id,
      status: refund.status,
      amountPaise: refund.amountPaise,
      razorpayRefundId: refund.razorpayRefundId,
      attemptCount: refund.attemptCount,
      maxAutoAttempts: MAX_REFUND_ATTEMPTS,
      lastError: refund.lastError,
      nextRetryAt: refund.nextRetryAt ? refund.nextRetryAt.toISOString() : null,
      reason: refund.reason,
      canRetry: refund.status !== 'processed' && !autoRetryPending,
      createdAt: refund.createdAt.toISOString(),
    };
  }

  /** Tell admins a refund needs manual intervention. */
  private static async notifyAdminsRefundFailed(
    payment: Payment,
    refund: Refund
  ): Promise<void> {
    const amountRupees = (Number(refund.amountPaise) / 100).toFixed(2);
    FCMService.enqueue(
      () =>
        FCMService.sendNotificationToRole(
          'admin',
          '⚠️ Refund Failed',
          `Refund of ₹${amountRupees} for order #${payment.orderId} failed after ${refund.attemptCount} attempts. Open the order to retry.`,
          {
            orderId: String(payment.orderId),
            refundId: String(refund.id),
            type: 'refund_failed',
          }
        ),
      `notify admins refund failed order=#${payment.orderId}`
    );
  }

  static async createRefund(params: {
    orderId: number;
    userId: number;
    actorUserId: number;
    reason?: string;
    idempotencyKey: string;
  }): Promise<
    | RefundSuccess
    | { ok: false; reason: string; code: number }
  > {
    type RefundResult = RefundSuccess | { ok: false; reason: string; code: number };

    const paymentRepo = AppDataSource.getRepository(Payment);
    const refundRepo = AppDataSource.getRepository(Refund);

    // Find the latest settled payment for this order — deliberately NOT filtered to
    // `status: 'paid'`. Issuing a refund moves the payment to `refund_pending`, so a
    // status-filtered lookup here made every retry of a *successful* refund fall out
    // as "No paid payment found" — a 404 that reads like the order doesn't exist —
    // before the idempotency check below ever got a chance to replay it.
    const payment = await paymentRepo.findOne({
      where: {
        orderId: params.orderId,
        userId: params.userId,
        status: In(['paid', 'refund_pending', 'refunded']),
      },
      order: { id: 'DESC' },
    });
    if (!payment) {
      return { ok: false, reason: 'No completed payment found for order', code: 404 };
    }

    // Fast path: idempotent retry from the same client with the same key.
    // This MUST come before the refundability assertion below, otherwise a caller
    // retrying after a timeout can never be handed back the refund it already made.
    // The cross-flow guard inside the lock repeats this lookup; the outer check
    // saves a lock acquisition for the common retry case.
    const existing = await refundRepo.findOne({
      where: { paymentId: payment.id, idempotencyKey: params.idempotencyKey },
    });
    if (existing) {
      return {
        ok: true,
        refundId: existing.id,
        razorpayRefundId: existing.razorpayRefundId,
        refundStatus: existing.status,
        attemptCount: existing.attemptCount,
        lastError: existing.lastError,
      };
    }

    // Not a replay — this is a genuinely new refund, so the payment must actually
    // be refundable. A payment already refunding or refunded is a conflict, not a
    // missing record, and says so.
    if (payment.status !== 'paid') {
      return {
        ok: false,
        reason:
          payment.status === 'refunded'
            ? 'Payment has already been refunded'
            : 'A refund is already in progress for this payment',
        code: 409,
      };
    }
    if (!payment.razorpayPaymentId) {
      return { ok: false, reason: 'Payment has no Razorpay payment id', code: 409 };
    }
    const razorpayPaymentId = payment.razorpayPaymentId;

    // Hold the payment-level lock while we check the invariant and create the
    // refund. Without this lock, two simultaneous calls with *different* keys
    // (e.g. customer-initiated + admin-cancel) could both read sum=0, both
    // create refund rows, and both call Razorpay → customer is refunded twice.
    let locked: { ran: true; result: RefundResult } | { ran: false };
    try {
      locked = await this.withPaymentLock(
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
            refundStatus: sameKey.status,
            attemptCount: sameKey.attemptCount,
            lastError: sameKey.lastError,
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
                refundStatus: again.status,
                attemptCount: again.attemptCount,
                lastError: again.lastError,
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

        // Attempt 1 of MAX_REFUND_ATTEMPTS. On failure this schedules the single
        // automatic retry (or parks the row at 'failed' for the admin button) —
        // it never silently swallows the error the way the old code did.
        await this.attemptRazorpayRefund(refund, payment, razorpayPaymentId);

        return {
          ok: true,
          refundId: refund.id,
          razorpayRefundId: refund.razorpayRefundId,
          refundStatus: refund.status,
          attemptCount: refund.attemptCount,
          lastError: refund.lastError,
        };
      }
    );
    } catch (lockErr) {
      // Redis is unreachable, so we cannot serialise this refund. Previously the
      // throw propagated to the admin-cancel / RTO callers, which only logged it —
      // the order was cancelled, stock restored, and the refund vanished with no
      // record that one was ever owed. Record it durably instead and let the
      // reconciler drive it once Redis is back.
      return this.recordRefundOwed(payment, params, lockErr);
    }

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

/**
 * Compact, log-safe description of a Razorpay/network failure for `refunds.last_error`.
 * Razorpay SDK errors carry `error.description`; everything else falls back to message.
 * Never include the full payload — it can contain key material.
 */
function describeError(err: unknown): string {
  const e = err as
    | { error?: { description?: string; code?: string }; message?: string; statusCode?: number }
    | null
    | undefined;
  const desc = e?.error?.description ?? e?.message ?? 'Unknown error';
  const code = e?.error?.code ?? (e?.statusCode != null ? `HTTP_${e.statusCode}` : null);
  return code ? `${code}: ${desc}` : desc;
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
