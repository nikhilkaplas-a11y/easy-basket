import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';
import { authenticate } from '../middleware/auth.middleware';

/**
 * NOTE: the webhook route is NOT registered here — it's mounted separately in index.ts
 * BEFORE the global express.json() middleware so that the HMAC verification can read
 * the raw request body byte-for-byte.  Do not add /webhook/razorpay to this router.
 */
const router = Router();

router.post('/create-order', authenticate, PaymentController.createRazorpayOrder);
router.post('/verify', authenticate, PaymentController.verifyPayment);
router.post('/refund', authenticate, PaymentController.refund);

export default router;
