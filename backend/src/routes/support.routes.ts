import { Router } from 'express';
import { SupportController } from '../controllers/support.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticate);

// User
router.post('/', SupportController.create);

// Admin
router.get('/', SupportController.list);
router.patch('/:id/status', SupportController.updateStatus);

export default router;