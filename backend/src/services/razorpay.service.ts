import crypto from 'crypto';
import Razorpay from 'razorpay';

/**
 * Thin wrapper around the Razorpay SDK.
 *
 * Two separate secrets:
 *   - RAZORPAY_KEY_SECRET    → signs the client-side verify callback
 *   - RAZORPAY_WEBHOOK_SECRET → signs server→server webhook POSTs
 *
 * Never log either.
 */
export class RazorpayService {
  private static instance: Razorpay | null = null;

  static init(): void {
    const id = process.env.RAZORPAY_KEY_ID;
    const secret = process.env.RAZORPAY_KEY_SECRET;
    if (!id || !secret) {
      console.warn('[Razorpay] KEY_ID / KEY_SECRET not set — payment init will fail');
      return;
    }
    this.instance = new Razorpay({ key_id: id, key_secret: secret });
    console.log('[Razorpay] initialized');
  }

  static client(): Razorpay {
    if (!this.instance) {
      throw new Error('Razorpay not initialized (missing RAZORPAY_KEY_ID/SECRET)');
    }
    return this.instance;
  }

  /** Returns the Razorpay order object. amountPaise must be an integer. */
  static async createOrder(params: {
    amountPaise: number;
    currency?: string;
    receipt: string;
    notes?: Record<string, string>;
  }) {
    return this.client().orders.create({
      amount: params.amountPaise,
      currency: params.currency ?? 'INR',
      receipt: params.receipt,
      notes: params.notes,
    });
  }

  /** Paginated fetch of all payments attempted against a Razorpay order. */
  static async fetchPaymentsForOrder(razorpayOrderId: string) {
    return this.client().orders.fetchPayments(razorpayOrderId);
  }

  static async fetchPayment(razorpayPaymentId: string) {
    return this.client().payments.fetch(razorpayPaymentId);
  }

  static async fetchRefund(razorpayRefundId: string) {
    return this.client().refunds.fetch(razorpayRefundId);
  }

  static async createRefund(params: {
    razorpayPaymentId: string;
    amountPaise: number;
    notes?: Record<string, string>;
    idempotencyKey: string;
  }) {
    // Razorpay supports speed 'normal' by default. Pass notes for our refund id.
    return this.client().payments.refund(params.razorpayPaymentId, {
      amount: params.amountPaise,
      notes: params.notes,
      // receipt acts like an idempotency hint on Razorpay side
      receipt: params.idempotencyKey,
    } as unknown as Parameters<Razorpay['payments']['refund']>[1]);
  }

  /**
   * Verify the signature returned to the client after checkout:
   *   HMAC_SHA256(razorpay_order_id + "|" + razorpay_payment_id, key_secret)
   * Constant-time compare — never use ===.
   */
  static verifyCheckoutSignature(params: {
    razorpayOrderId: string;
    razorpayPaymentId: string;
    signature: string;
  }): boolean {
    const secret = process.env.RAZORPAY_KEY_SECRET;
    if (!secret) return false;
    const expected = crypto
      .createHmac('sha256', secret)
      .update(`${params.razorpayOrderId}|${params.razorpayPaymentId}`)
      .digest('hex');
    return safeEqualHex(expected, params.signature);
  }

  /**
   * Verify the X-Razorpay-Signature header on an incoming webhook.
   * Requires the RAW request body (string or Buffer) — parsed JSON will NOT match.
   */
  static verifyWebhookSignature(rawBody: string | Buffer, signatureHeader: string): boolean {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret || !signatureHeader) return false;
    const body = Buffer.isBuffer(rawBody) ? rawBody : Buffer.from(rawBody, 'utf8');
    const expected = crypto.createHmac('sha256', secret).update(body).digest('hex');
    return safeEqualHex(expected, signatureHeader);
  }
}

function safeEqualHex(a: string, b: string): boolean {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  if (a.length !== b.length) return false;
  try {
    return crypto.timingSafeEqual(Buffer.from(a, 'hex'), Buffer.from(b, 'hex'));
  } catch {
    return false;
  }
}

RazorpayService.init();
