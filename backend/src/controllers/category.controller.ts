import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { Category } from '../entities/Category';

export class CategoryController {
  static async getAllCategories(req: Request, res: Response): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const skip = (page - 1) * limit;

      const categoryRepository = AppDataSource.getRepository(Category);
      const [categories, total] = await categoryRepository.findAndCount({
        where: { isActive: true },
        relations: ['products'],
        skip,
        take: limit,
        order: { createdAt: 'DESC' },
      });

      res.json({
        categories,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
          hasMore: page * limit < total,
        },
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching categories' });
    }
  }

  static async getCategoryById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const categoryRepository = AppDataSource.getRepository(Category);
      const category = await categoryRepository.findOne({
        where: { id: Number(id) },
        relations: ['products'],
      });

      if (!category) {
        res.status(404).json({ message: 'Category not found' });
        return;
      }

      res.json(category);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching category' });
    }
  }

  static async createCategory(req: Request, res: Response): Promise<void> {
    try {
      const { name, description, imageUrl } = req.body;

      if (!name) {
        res.status(400).json({ message: 'Category name is required' });
        return;
      }

      const categoryRepository = AppDataSource.getRepository(Category);
      const category = categoryRepository.create({
        name,
        description,
        imageUrl,
      });

      await categoryRepository.save(category);
      res.status(201).json(category);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error creating category' });
    }
  }

  static async updateCategory(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const categoryRepository = AppDataSource.getRepository(Category);
      const category = await categoryRepository.findOneBy({ id: Number(id) });

      if (!category) {
        res.status(404).json({ message: 'Category not found' });
        return;
      }

      const { name, description, imageUrl, isActive } = req.body;

      if (name) category.name = name;
      if (description !== undefined) category.description = description;
      if (imageUrl !== undefined) category.imageUrl = imageUrl;
      if (isActive !== undefined) category.isActive = isActive;

      await categoryRepository.save(category);
      res.json(category);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating category' });
    }
  }

  static async deleteCategory(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const categoryRepository = AppDataSource.getRepository(Category);
      const category = await categoryRepository.findOneBy({ id: Number(id) });

      if (!category) {
        res.status(404).json({ message: 'Category not found' });
        return;
      }

      await categoryRepository.remove(category);
      res.json({ message: 'Category deleted successfully' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error deleting category' });
    }
  }
}

