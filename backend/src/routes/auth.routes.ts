import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

router.post('/login', AuthController.login);
router.post('/verify', AuthController.verify);
router.post('/refresh', AuthController.refresh);
router.post('/fcm-token', authenticate, AuthController.updateFcmToken);
router.post('/logout', authenticate, AuthController.logout);
router.put('/profile', authenticate, AuthController.updateProfile);

export default router;
