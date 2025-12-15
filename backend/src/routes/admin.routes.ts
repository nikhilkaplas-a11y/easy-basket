import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import { authenticate, authorize } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);
router.use(authorize('admin'));

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

export default router;

