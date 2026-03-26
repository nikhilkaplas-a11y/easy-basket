import { Router } from 'express';
import { authenticate, authorize } from '../middleware/auth.middleware';
import { UploadController } from '../controllers/upload.controller';
import { uploadSingle } from '../middleware/upload.middleware';

const router = Router();

// All upload routes require authentication and admin role
router.use(authenticate);
router.use(authorize('admin'));

// Upload image
router.post('/upload-image', uploadSingle, UploadController.uploadImage);

// Delete image
router.delete('/delete-image', UploadController.deleteImage);

export default router;
