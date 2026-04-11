import { createHash } from 'crypto';
import { Request, Response } from 'express';

import { AppDataSource } from '../config/database';
import { Category } from '../entities/Category';
import { Product } from '../entities/Product';
import { RedisService } from '../services/redis.service';

import { Brackets } from 'typeorm';

/** Public product list GET /api/products — cache in Redis; invalidate on product/variant/stock changes */
const PRODUCT_LIST_CACHE_PREFIX = 'cache:products:list:v1:';
const PRODUCT_LIST_CACHE_PATTERN = 'cache:products:list:*';
const PRODUCT_LIST_TTL_SEC = 300; // 5 minutes (shorter than categories; safety net if invalidation misses)

function productListCacheKey(query: Request['query']): string {
  const { categoryId, search, limit, page } = query;
  const cat = categoryId ? String(Number(categoryId)) : '_';
  const q =
    search && String(search).trim()
      ? createHash('sha256')
          .update(String(search).trim().toLowerCase())
          .digest('hex')
          .slice(0, 16)
      : '_';
  const takeLimit = limit ? Number(limit) : search ? 50 : undefined;
  const lim = takeLimit ? String(takeLimit) : 'all';
  const pageKey =
    takeLimit && page ? String(Math.max(1, Number(page))) : takeLimit ? '1' : '1';
  return `${PRODUCT_LIST_CACHE_PREFIX}${cat}:${q}:${lim}:${pageKey}`;
}

export class ProductController {
  /** Wipe all product list cache entries (any query variant). */
  static async invalidateProductListCache(): Promise<void> {
    try {
      const n = await RedisService.deleteKeysMatching(PRODUCT_LIST_CACHE_PATTERN);
      if (n > 0) {
        console.log(`🗑️ Product list cache invalidated (${n} key(s))`);
      }
    } catch (e) {
      console.warn('Product list cache invalidation failed:', e);
    }
  }

  static async getSuggestions(req: Request, res: Response): Promise<void> {
    try {
      const { search } = req.query;

      if (!search || String(search).length < 2) {
        res.json([]);
        return;
      }

      const productRepository = AppDataSource.getRepository(Product);

      // Use raw query for performance and flexibility
      // We want to return unique names that match the search
      // Split query into words and require all of them (AND logic)
      const searchTerms = String(search)
        .trim()
        .split(/\s+/)
        .map((term) => {
          // If term is very short, don't force it with + as it might not be indexed
          return term.length <= 2 ? `${term}*` : `+${term}*`;
        })
        .join(' ');

      const suggestions = await productRepository
        .createQueryBuilder('product')
        .select('product.name', 'name')
        .addSelect('MAX(product.imageUrl)', 'imageUrl') // Pick one image for the name
        .where('product.isAvailable = :isAvailable', { isAvailable: true })
        .andWhere(
          new Brackets((qb) => {
            qb.where(
              `MATCH(product.name, product.tags, product.description) AGAINST(:search IN BOOLEAN MODE)`,
              { search: searchTerms }
            ).orWhere('product.name LIKE :likeSearch', { likeSearch: `%${search}%` });
          })
        )
        .groupBy('product.name') // Group by name to get distinct names
        .limit(8)
        .getRawMany();

      res.json(suggestions.map((s, index) => ({ id: index, name: s.name, imageUrl: s.imageUrl })));
    } catch (error) {
      console.error('Error fetching suggestions:', error);
      res.status(500).json({ message: 'Error fetching suggestions' });
    }
  }

  static async getAllProducts(req: Request, res: Response): Promise<void> {
    try {
      const { categoryId, search, limit, page } = req.query;
      const cacheKey = productListCacheKey(req.query);
      try {
        const cached = await RedisService.getJson<unknown[]>(cacheKey);
        if (cached) {
          res.json(cached);
          return;
        }
      } catch {
        // Redis hiccup — fall through to DB
      }

      const productRepository = AppDataSource.getRepository(Product);
      const queryBuilder = productRepository
        .createQueryBuilder('product')
        .select([
          'product.id',
          'product.name',
          'product.price',
          'product.imageUrl',
          'product.stock',
          'product.unit',
          'product.isAvailable',
          'product.hasVariants',
          'product.baseUnit',
          'product.minQuantity',
          'product.maxQuantity',
          'product.categoryId',
          'product.tags',
        ])
        .leftJoinAndSelect('product.category', 'category')
        .leftJoinAndSelect('product.variants', 'variants')
        .where('product.isAvailable = :isAvailable', { isAvailable: true });

      if (categoryId) {
        queryBuilder.andWhere('product.categoryId = :categoryId', { categoryId });
      }

      if (search) {
        // Use Full-Text Search with Boolean Mode for better matching
        // Split query into words and require all of them (AND logic)
        // e.g. "Chia Seeds" -> "+Chia* +Seeds*"
        const searchTerms = String(search)
          .trim()
          .split(/\s+/)
          .map((term) => {
            // If term is very short, don't force it with + as it might not be indexed
            // Exception: if the query ONLY has short words, we might need to rely on LIKE mostly
            return term.length <= 2 ? `${term}*` : `+${term}*`;
          })
          .join(' ');

        // Combine FTS with LIKE to catch short words/numbers (e.g., "1L") that FTS might miss
        queryBuilder.andWhere(
          new Brackets((qb) => {
            qb.where(
              `MATCH(product.name, product.tags, product.description) AGAINST(:search IN BOOLEAN MODE)`,
              { search: searchTerms }
            ).orWhere('product.name LIKE :likeSearch', { likeSearch: `%${search}%` });
          })
        );
      }

      // Pagination support
      // limit = kitne products ek page mein (default: all, search: 50)
      // page = kaunsa page (1, 2, 3...) — offset calculate hota hai: (page-1) * limit
      const takeLimit = limit ? Number(limit) : search ? 50 : undefined;
      if (takeLimit) {
        queryBuilder.take(takeLimit);
        if (page) {
          const pageNum = Math.max(1, Number(page));
          queryBuilder.skip((pageNum - 1) * takeLimit);
        }
      }

      const products = await queryBuilder.getMany();

      // Sort variants by displayOrder for each product
      products.forEach((product) => {
        if (product.variants) {
          product.variants.sort((a, b) => {
            if (a.displayOrder !== b.displayOrder) {
              return a.displayOrder - b.displayOrder;
            }
            return a.quantity - b.quantity;
          });
        }
      });

      try {
        await RedisService.setJson(cacheKey, products, PRODUCT_LIST_TTL_SEC);
      } catch (e) {
        console.warn('Product list cache set failed:', e);
      }

      res.json(products);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching products' });
    }
  }

  static async getProductById(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const productRepository = AppDataSource.getRepository(Product);
      const product = await productRepository.findOne({
        where: { id: Number(id) },
        relations: ['category', 'variants'],
      });

      if (!product) {
        res.status(404).json({ message: 'Product not found' });
        return;
      }

      // Sort variants by displayOrder
      if (product.variants) {
        product.variants.sort((a, b) => {
          if (a.displayOrder !== b.displayOrder) {
            return a.displayOrder - b.displayOrder;
          }
          return a.quantity - b.quantity;
        });
      }

      res.json(product);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching product' });
    }
  }

  static async createProduct(req: Request, res: Response): Promise<void> {
    try {
      const { name, description, price, imageUrl, categoryId, stock, unit, tags } = req.body;

      if (!name || !price || !categoryId) {
        res.status(400).json({ message: 'Name, price, and category are required' });
        return;
      }

      const categoryRepository = AppDataSource.getRepository(Category);
      const category = await categoryRepository.findOneBy({ id: categoryId });

      if (!category) {
        res.status(404).json({ message: 'Category not found' });
        return;
      }

      const productRepository = AppDataSource.getRepository(Product);
      const product = productRepository.create({
        name,
        description,
        price,
        imageUrl,
        category,
        stock: stock || 0,
        unit: unit || 'piece',
        tags,
      });

      await productRepository.save(product);
      await ProductController.invalidateProductListCache();
      res.status(201).json(product);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error creating product' });
    }
  }

  static async updateProduct(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const productRepository = AppDataSource.getRepository(Product);
      const product = await productRepository.findOneBy({ id: Number(id) });

      if (!product) {
        res.status(404).json({ message: 'Product not found' });
        return;
      }

      const { name, description, price, imageUrl, categoryId, stock, unit, isAvailable, tags } =
        req.body;

      if (name) product.name = name;
      if (description !== undefined) product.description = description;
      if (price) product.price = price;
      if (imageUrl !== undefined) product.imageUrl = imageUrl;
      if (stock !== undefined) product.stock = stock;
      if (unit) product.unit = unit;
      if (isAvailable !== undefined) product.isAvailable = isAvailable;
      if (tags !== undefined) product.tags = tags;

      if (categoryId) {
        const categoryRepository = AppDataSource.getRepository(Category);
        const category = await categoryRepository.findOneBy({ id: categoryId });
        if (category) {
          product.category = category;
        }
      }

      await productRepository.save(product);
      await ProductController.invalidateProductListCache();
      res.json(product);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating product' });
    }
  }

  static async deleteProduct(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const productRepository = AppDataSource.getRepository(Product);
      const product = await productRepository.findOneBy({ id: Number(id) });

      if (!product) {
        res.status(404).json({ message: 'Product not found' });
        return;
      }

      await productRepository.remove(product);
      await ProductController.invalidateProductListCache();
      res.json({ message: 'Product deleted successfully' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error deleting product' });
    }
  }
}
