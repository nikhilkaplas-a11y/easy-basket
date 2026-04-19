import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';
import { RedisService } from '../services/redis.service';

const router = Router();

router.use(authenticate);
router.use(authorize('admin'));

// Admin: flush Redis cache (use to invalidate stale cached responses)
router.post('/cache/flush', async (_req, res) => {
  try {
    const deleted = await RedisService.deleteKeysMatching('cache:*');
    res.json({ success: true, keysDeleted: deleted });
  } catch (e) {
    res.status(500).json({ success: false, error: String(e) });
  }
});

router.get('/dashboard', AdminController.getDashboardStats);
router.get('/orders', AdminController.getAllOrders);
router.get('/orders/:id', AdminController.getOrderById);
router.put('/orders/:id/status', AdminController.updateOrderStatus);
router.get('/users', AdminController.getAllUsers);
router.get('/delivery-agents', AdminController.getDeliveryAgents);
router.put('/users/:id', AdminController.updateUser);
router.get('/products', AdminController.getAllProducts);
router.post('/products', AdminController.createProduct);
router.put('/products/:id', AdminController.updateProduct);
router.delete('/products/:id', AdminController.deleteProduct);
router.post('/notifications/send', AdminController.sendPromoNotification);

export default router;
