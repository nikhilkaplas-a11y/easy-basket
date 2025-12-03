import { Router } from 'express';
import { OrderController } from '../controllers/order.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Public route (for order tracking without auth)
router.get('/status/:id', OrderController.getOrderStatus);

// Authenticated routes
router.use(authenticate);

router.post('/', OrderController.createOrder);
router.get('/', OrderController.getUserOrders);
router.get('/:id', OrderController.getOrderById);
router.put('/:id/cancel', OrderController.cancelOrder);

export default router;
