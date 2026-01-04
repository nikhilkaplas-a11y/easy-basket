import { AppDataSource } from '../config/database';
import { AuthRequest } from '../middleware/auth.middleware';
import { Category } from '../entities/Category';
import { FCMService } from '../services/fcm.service';
import { Order } from '../entities/Order';
import { Product } from '../entities/Product';
import { Response } from 'express';
import { User } from '../entities/User';

export class AdminController {
  static async getAllOrders(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { status } = req.query;
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const skip = (page - 1) * limit;

      const orderRepository = AppDataSource.getRepository(Order);
      const queryBuilder = orderRepository
        .createQueryBuilder('order')
        .leftJoinAndSelect('order.user', 'user')
        .leftJoinAndSelect('order.items', 'items')
        .leftJoinAndSelect('items.product', 'product')
        .leftJoinAndSelect('items.variant', 'variant')
        .leftJoinAndSelect('order.deliveryAddress', 'deliveryAddress')
        .leftJoinAndSelect('order.deliveryBoy', 'deliveryBoy')
        .orderBy('order.createdAt', 'DESC');

      if (status) {
        queryBuilder.where('order.status = :status', { status });
      }

      const [orders, total] = await queryBuilder.skip(skip).take(limit).getManyAndCount();

      res.json({
        orders,
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
      res.status(500).json({ message: 'Error fetching orders' });
    }
  }

  static async getOrderById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id) },
        relations: ['user', 'items', 'items.product', 'items.variant', 'deliveryAddress', 'deliveryBoy'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      res.json(order);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching order' });
    }
  }

  static async updateOrderStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { status, deliveryBoyId, notes } = req.body;

      if (!status) {
        res.status(400).json({ message: 'Status is required' });
        return;
      }

      const validStatuses = ['pending', 'accepted', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'];
      if (!validStatuses.includes(status)) {
        res.status(400).json({ message: 'Invalid status' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id) },
        relations: ['user', 'deliveryBoy'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      order.status = status;

      if (notes) {
        order.notes = notes;
      }

      // Allow assigning delivery boy when accepting, preparing, or out_for_delivery
      if (deliveryBoyId && ['accepted', 'preparing', 'out_for_delivery'].includes(status)) {
        const userRepository = AppDataSource.getRepository(User);
        const deliveryBoy = await userRepository.findOneBy({
          id: deliveryBoyId,
          role: 'delivery',
        });

        if (!deliveryBoy) {
          res.status(404).json({ message: 'Delivery boy not found' });
          return;
        }

        order.deliveryBoy = deliveryBoy;

        // Notify delivery boy
        if (deliveryBoy.fcmToken) {
          await FCMService.sendNotification(
            deliveryBoy.fcmToken,
            'New Delivery Assignment',
            `Order #${order.id} assigned to you`,
            { orderId: order.id.toString(), type: 'order_assigned' }
          );
        }
      }

      await orderRepository.save(order);

      // Notify customer
      if (order.user.fcmToken) {
        let notificationTitle = 'Order Update';
        let notificationBody = `Your order #${order.id} status: ${status}`;

        if (status === 'accepted') {
          notificationTitle = 'Order Accepted';
          notificationBody = `Your order #${order.id} has been accepted and is being prepared`;
        } else if (status === 'out_for_delivery') {
          notificationTitle = 'Out for Delivery';
          notificationBody = `Your order #${order.id} is out for delivery`;
        } else if (status === 'delivered') {
          notificationTitle = 'Order Delivered';
          notificationBody = `Your order #${order.id} has been delivered. Thank you!`;
        }

        await FCMService.sendNotification(
          order.user.fcmToken,
          notificationTitle,
          notificationBody,
          { orderId: order.id.toString(), status, type: 'order_status_update' }
        );
      }

      res.json(order);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating order status' });
    }
  }

  static async getAllUsers(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { role } = req.query;
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const skip = (page - 1) * limit;

      const userRepository = AppDataSource.getRepository(User);
      const queryBuilder = userRepository.createQueryBuilder('user').where('user.isActive = :isActive', { isActive: true });

      if (role) {
        queryBuilder.andWhere('user.role = :role', { role });
      }

      const [users, total] = await queryBuilder.skip(skip).take(limit).getManyAndCount();

      res.json({
        users,
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
      res.status(500).json({ message: 'Error fetching users' });
    }
  }

  static async updateUser(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { name, email, role, isActive } = req.body;

      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOneBy({ id: Number(id) });

      if (!user) {
        res.status(404).json({ message: 'User not found' });
        return;
      }

      if (name) user.name = name;
      if (email) user.email = email;
      if (role) user.role = role;
      if (isActive !== undefined) user.isActive = isActive;

      await userRepository.save(user);
      res.json(user);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating user' });
    }
  }

  static async getDashboardStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const orderRepository = AppDataSource.getRepository(Order);
      const userRepository = AppDataSource.getRepository(User);
      const productRepository = AppDataSource.getRepository(Product);

      const [
        totalOrders,
        pendingOrders,
        todayOrders,
        totalUsers,
        totalProducts,
        lowStockProducts,
      ] = await Promise.all([
        orderRepository.count(),
        orderRepository.count({ where: { status: 'pending' } }),
        orderRepository
          .createQueryBuilder('order')
          .where('DATE(order.createdAt) = CURDATE()')
          .getCount(),
        userRepository.count({ where: { isActive: true } }),
        productRepository.count({ where: { isAvailable: true } }),
        productRepository
          .createQueryBuilder('product')
          .where('product.stock < :stock', { stock: 10 })
          .andWhere('product.isAvailable = :isAvailable', { isAvailable: true })
          .getCount(),
      ]);

      // Calculate today's revenue
      const todayRevenueResult = await orderRepository
        .createQueryBuilder('order')
        .select('SUM(order.totalAmount)', 'total')
        .where('DATE(order.createdAt) = CURDATE()')
        .andWhere('order.status = :status', { status: 'delivered' })
        .getRawOne();

      const todayRevenue = todayRevenueResult?.total || 0;

      res.json({
        orders: {
          total: totalOrders,
          pending: pendingOrders,
          today: todayOrders,
        },
        users: {
          total: totalUsers,
        },
        products: {
          total: totalProducts,
          lowStock: lowStockProducts,
        },
        revenue: {
          today: parseFloat(todayRevenue),
        },
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching dashboard stats' });
    }
  }

  static async getAllProducts(req: AuthRequest, res: Response): Promise<void> {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const skip = (page - 1) * limit;

      const productRepository = AppDataSource.getRepository(Product);
      const [products, total] = await productRepository.findAndCount({
        relations: ['category'],
        order: { createdAt: 'DESC' },
        skip,
        take: limit,
      });

      res.json({
        products,
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
      res.status(500).json({ message: 'Error fetching products' });
    }
  }

  static async createProduct(req: AuthRequest, res: Response): Promise<void> {
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
        isAvailable: true,
        tags,
      });

      await productRepository.save(product);
      res.status(201).json(product);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error creating product' });
    }
  }

  static async updateProduct(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { name, description, price, imageUrl, categoryId, stock, unit, isAvailable, tags } = req.body;

      const productRepository = AppDataSource.getRepository(Product);
      const product = await productRepository.findOne({
        where: { id: Number(id) },
        relations: ['category'],
      });

      if (!product) {
        res.status(404).json({ message: 'Product not found' });
        return;
      }

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
      res.json(product);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating product' });
    }
  }

  static async deleteProduct(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const productRepository = AppDataSource.getRepository(Product);
      const product = await productRepository.findOneBy({ id: Number(id) });

      if (!product) {
        res.status(404).json({ message: 'Product not found' });
        return;
      }

      // Soft delete - set isAvailable to false instead of deleting
      product.isAvailable = false;
      await productRepository.save(product);

      res.json({ message: 'Product deleted successfully' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error deleting product' });
    }
  }

  // Get list of delivery agents for assignment
  static async getDeliveryAgents(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userRepository = AppDataSource.getRepository(User);
      
      // Use query builder for more control and better null handling
      // MySQL doesn't support NULLS LAST, so we use ISNULL to put nulls at the end
      const deliveryAgents = await userRepository
        .createQueryBuilder('user')
        .select(['user.id', 'user.name', 'user.phoneNumber', 'user.email'])
        .where('user.role = :role', { role: 'delivery' })
        .andWhere('user.isActive = :isActive', { isActive: true })
        .orderBy('ISNULL(user.name)', 'ASC') // NULLs will be last (ISNULL returns 1 for null, 0 for not null)
        .addOrderBy('user.name', 'ASC')
        .addOrderBy('user.phoneNumber', 'ASC')
        .getMany();

      console.log(`✅ Found ${deliveryAgents.length} active delivery agents`);
      
      if (deliveryAgents.length === 0) {
        console.log('⚠️ No active delivery agents found. Checking all users with delivery role...');
        const allDeliveryUsers = await userRepository.find({
          where: { role: 'delivery' },
          select: ['id', 'name', 'phoneNumber', 'email', 'isActive'],
        });
        console.log(`📊 Total users with delivery role: ${allDeliveryUsers.length}`);
        if (allDeliveryUsers.length > 0) {
          console.log('Delivery users found:');
          allDeliveryUsers.forEach(user => {
            console.log(`  - ID: ${user.id}, Phone: ${user.phoneNumber}, Name: ${user.name || 'N/A'}, Active: ${user.isActive}`);
          });
          console.log('💡 Tip: Make sure isActive = true for delivery agents');
        } else {
          console.log('❌ No users found with role="delivery"');
          console.log('💡 Tip: Update user role to "delivery" in database or via Admin Dashboard');
        }
      } else {
        deliveryAgents.forEach(agent => {
          console.log(`  ✓ ${agent.name || 'N/A'} (${agent.phoneNumber})`);
        });
      }

      res.json(deliveryAgents);
    } catch (error) {
      console.error('❌ Error fetching delivery agents:', error);
      res.status(500).json({ 
        message: 'Error fetching delivery agents',
        error: error instanceof Error ? error.message : 'Unknown error'
      });
    }
  }
}

