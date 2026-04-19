import { Request, Response } from 'express';
import crypto from 'crypto';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { PaymentsV2Service } from '../services/payments-v2.service';
import { RazorpayService } from '../services/razorpay.service';
import { AuthRequest } from '../middleware/auth.middleware';

export class PaymentController {
  /**
   * POST /api/payment/create-order
   * Authenticated. Creates (or returns the existing in-flight) Razorpay order for a given
   * internal order id. Server prices the order — the amount on the request is ignored.
   */
  static async createRazorpayOrder(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { orderId } = req.body as { orderId?: string | number };
      if (orderId == null) {
        res.status(400).json({ message: 'orderId is required' });
        return;
      }

      const orderIdNum = typeof orderId === 'number' ? orderId : parseInt(String(orderId), 10);
      if (!Number.isFinite(orderIdNum)) {
        res.status(400).json({ message: 'Invalid orderId' });
        return;
      }

      const order = await AppDataSource.getRepository(Order).findOne({
        where: { id: orderIdNum },
        relations: ['user'],
      });

      if (!order || order.user.id !== userId) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      if (order.status === 'cancelled' || order.status === 'delivered') {
        res.status(409).json({ message: `Cannot pay for order in status ${order.status}` });
        return;
      }

      const amountPaise = PaymentsV2Service.toPaise(order.totalAmount);
      const out = await PaymentsV2Service.initiatePayment({
        orderId: orderIdNum,
        userId,
        amountPaise,
      });

      res.json({
        razorpayOrderId: out.razorpayOrderId,
        amount: out.amountPaise,
        currency: out.currency,
        key: out.keyId,
      });
    } catch (error) {
      console.error('[payment] createRazorpayOrder error', error);
      res.status(500).json({ message: 'Error creating payment order' });
    }
  }

  /**
   * POST /api/payment/verify
   * Authenticated. Verifies the HMAC signature Razorpay returns to the client after
   * Checkout succeeds, then advances payment state to `success_unverified`.
   * The webhook (or reconciler) is what finally promotes it to `paid`.
   */
  static async verifyPayment(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const body = req.body as {
        razorpayOrderId?: string;
        razorpayPaymentId?: string;
        razorpaySignature?: string;
        // legacy param names from the old mobile client
        paymentId?: string;
        signature?: string;
        orderId?: number | string;
      };

      const razorpayOrderId = body.razorpayOrderId;
      const razorpayPaymentId = body.razorpayPaymentId ?? body.paymentId;
      const signature = body.razorpaySignature ?? body.signature;

      if (!razorpayOrderId || !razorpayPaymentId || !signature) {
        res.status(400).json({
          message: 'razorpayOrderId, razorpayPaymentId and signature are required',
        });
        return;
      }

      const result = await PaymentsV2Service.handleVerify({
        userId,
        razorpayOrderId,
        razorpayPaymentId,
        signature,
      });

      if (!result.ok) {
        res.status(result.code).json({ message: result.reason });
        return;
      }

      res.json({ message: 'Payment verified', paymentStatus: result.status });
    } catch (error) {
      console.error('[payment] verifyPayment error', error);
      res.status(500).json({ message: 'Error verifying payment' });
    }
  }

  /**
   * POST /api/payment/webhook/razorpay
   * Unauthenticated from client POV — the X-Razorpay-Signature header is the auth.
   * IMPORTANT: this route MUST be mounted with express.raw({ type: 'application/json' })
   * BEFORE the global express.json() middleware, otherwise signature verification fails.
   * See index.ts.
   */
  static async razorpayWebhook(req: Request, res: Response): Promise<void> {
    try {
      const sig = req.header('x-razorpay-signature') ?? '';
      const rawBody: Buffer = Buffer.isBuffer(req.body)
        ? req.body
        : Buffer.from(typeof req.body === 'string' ? req.body : JSON.stringify(req.body), 'utf8');

      if (!RazorpayService.verifyWebhookSignature(rawBody, sig)) {
        console.warn('[webhook] signature verification FAILED');
        res.status(401).json({ message: 'Invalid signature' });
        return;
      }

      const parsed = JSON.parse(rawBody.toString('utf8')) as {
        event?: string;
        payload?: unknown;
      };
      const eventType = parsed.event;
      if (!eventType) {
        res.status(400).json({ message: 'Missing event' });
        return;
      }

      // Prefer Razorpay's event id if present; fall back to a stable hash of the body.
      const eventId =
        (req.header('x-razorpay-event-id') as string | undefined) ??
        deriveEventIdFromBody(rawBody);

      const result = await PaymentsV2Service.handleWebhook({
        eventId,
        eventType,
        payload: parsed as unknown as Record<string, unknown>,
      });

      // Always 200 unless signature / body is invalid — Razorpay retries on non-2xx.
      res.status(200).json({ received: true, ...result });
    } catch (error) {
      console.error('[webhook] handler error', error);
      // Return 500 so Razorpay retries; our dedupe ensures safety.
      res.status(500).json({ message: 'Webhook processing error' });
    }
  }

  /**
   * POST /api/payment/refund
   * Authenticated. Owner or admin can request a refund for a paid order.
   * Idempotency-Key header required.
   */
  static async refund(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { orderId, reason } = req.body as { orderId?: number; reason?: string };
      const idem = (req.header('idempotency-key') ?? '').trim();
      if (!orderId || !idem) {
        res.status(400).json({ message: 'orderId and Idempotency-Key header are required' });
        return;
      }
      if (!/^[A-Za-z0-9_\-:]{8,64}$/.test(idem)) {
        res.status(400).json({ message: 'Invalid Idempotency-Key' });
        return;
      }

      const order = await AppDataSource.getRepository(Order).findOne({
        where: { id: orderId },
        relations: ['user'],
      });
      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      const isOwner = order.user.id === userId;
      const isAdmin = req.user?.role === 'admin';
      if (!isOwner && !isAdmin) {
        res.status(403).json({ message: 'Forbidden' });
        return;
      }

      const result = await PaymentsV2Service.createRefund({
        orderId,
        userId: order.user.id,
        actorUserId: userId,
        reason,
        idempotencyKey: idem,
      });

      if (!result.ok) {
        res.status(result.code).json({ message: result.reason });
        return;
      }

      res.json({
        refundId: result.refundId,
        razorpayRefundId: result.razorpayRefundId,
        status: 'pending',
      });
    } catch (error) {
      console.error('[payment] refund error', error);
      res.status(500).json({ message: 'Error processing refund' });
    }
  }
}

function deriveEventIdFromBody(buf: Buffer): string {
  // Fallback when Razorpay doesn't send x-razorpay-event-id. Hash of body is stable per event.
  return 'derived:' + crypto.createHash('sha256').update(buf).digest('hex').slice(0, 48);
}
