import { Router } from 'express';
import { PaymentController } from '../controllers/payment.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.post('/create-order', authenticate, PaymentController.createRazorpayOrder);
router.post('/verify', PaymentController.verifyPayment);
router.post('/webhook/razorpay', PaymentController.razorpayWebhook);

export default router;
