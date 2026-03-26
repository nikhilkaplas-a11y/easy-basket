import { Response } from 'express';
import { AuthRequest } from '../middleware/auth.middleware';
import { S3Service } from '../services/s3.service';
import { AppDataSource } from '../config/database';
import { Product } from '../entities/Product';
import { Category } from '../entities/Category';

export class UploadController {
  /**
   * Upload image for product or category
   * POST /api/admin/upload-image
   */
  static async uploadImage(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      // Check if file was uploaded
      if (!req.file) {
        res.status(400).json({ message: 'No file uploaded' });
        return;
      }

      // Get form data
      const { type, id, name } = req.body;

      // Validate type
      if (!type || !['product', 'category'].includes(type)) {
        res.status(400).json({ message: 'Invalid type. Must be "product" or "category"' });
        return;
      }

      // Validate ID
      const entityId = parseInt(id, 10);
      if (!entityId || isNaN(entityId)) {
        res.status(400).json({ message: 'Invalid ID' });
        return;
      }

      // Verify entity exists and belongs to admin (or is accessible)
      let entityName: string | undefined;

      if (type === 'product') {
        const productRepository = AppDataSource.getRepository(Product);
        const product = await productRepository.findOneBy({ id: entityId });
        if (!product) {
          res.status(404).json({ message: 'Product not found' });
          return;
        }
        entityName = product.name;
      } else if (type === 'category') {
        const categoryRepository = AppDataSource.getRepository(Category);
        const category = await categoryRepository.findOneBy({ id: entityId });
        if (!category) {
          res.status(404).json({ message: 'Category not found' });
          return;
        }
        entityName = category.name;
      }

      // Upload to S3
      const result = await S3Service.uploadImage(
        req.file,
        type as 'product' | 'category',
        entityId,
        name, // Admin-provided name (optional)
        entityName // Entity name for auto-generation
      );

      res.status(200).json({
        success: true,
        url: result.url,
        filename: result.filename,
        path: result.path,
        size: req.file.size,
        mimetype: req.file.mimetype,
      });
    } catch (error) {
      console.error('Error uploading image:', error);
      const errorMessage = error instanceof Error ? error.message : 'Error uploading image';
      res.status(500).json({ message: errorMessage });
    }
  }

  /**
   * Delete image from S3
   * DELETE /api/admin/delete-image
   */
  static async deleteImage(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { url } = req.body;

      if (!url) {
        res.status(400).json({ message: 'Image URL is required' });
        return;
      }

      // Extract S3 key from URL
      const key = S3Service.extractKeyFromUrl(url);
      if (!key) {
        res.status(400).json({ message: 'Invalid image URL' });
        return;
      }

      // Delete from S3
      await S3Service.deleteImage(key);

      res.status(200).json({
        success: true,
        message: 'Image deleted successfully',
      });
    } catch (error) {
      console.error('Error deleting image:', error);
      const errorMessage = error instanceof Error ? error.message : 'Error deleting image';
      res.status(500).json({ message: errorMessage });
    }
  }
}
