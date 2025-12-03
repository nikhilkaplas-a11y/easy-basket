import { Router } from 'express';
import { DeliveryController } from '../controllers/delivery.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);
router.use(authorize('delivery'));

router.get('/orders', DeliveryController.getAssignedOrders);
router.get('/orders/:id', DeliveryController.getOrderDetails);
router.put('/orders/:id/status', DeliveryController.updateOrderStatus);
router.get('/stats', DeliveryController.getDeliveryStats);
router.get('/earnings', DeliveryController.getEarnings);

export default router;

