import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { OrderItem } from '../entities/OrderItem';
import { Product } from '../entities/Product';
import { Address } from '../entities/Address';
import { User } from '../entities/User';
import { AuthRequest } from '../middleware/auth.middleware';
import { PaymentService } from '../services/payment.service';
import { FCMService } from '../services/fcm.service';

export class OrderController {
  static async createOrder(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const { items, addressId, paymentMethod, notes } = req.body;

      if (!items || !Array.isArray(items) || items.length === 0) {
        res.status(400).json({ message: 'Order items are required' });
        return;
      }

      if (!addressId) {
        res.status(400).json({ message: 'Delivery address is required' });
        return;
      }

      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOneBy({ id: userId });

      if (!user) {
        res.status(404).json({ message: 'User not found' });
        return;
      }

      const addressRepository = AppDataSource.getRepository(Address);
      const address = await addressRepository.findOne({
        where: { id: addressId, user: { id: userId } },
      });

      if (!address) {
        res.status(404).json({ message: 'Address not found' });
        return;
      }

      const productRepository = AppDataSource.getRepository(Product);
      let totalAmount = 0;
      const orderItems: OrderItem[] = [];

      // Validate items and calculate total
      for (const item of items) {
        const product = await productRepository.findOneBy({ id: item.productId });

        if (!product) {
          res.status(404).json({ message: `Product ${item.productId} not found` });
          return;
        }

        if (!product.isAvailable) {
          res.status(400).json({ message: `Product ${product.name} is not available` });
          return;
        }

        if (product.stock < item.quantity) {
          res.status(400).json({
            message: `Insufficient stock for ${product.name}. Available: ${product.stock}`,
          });
          return;
        }

        const itemTotal = product.price * item.quantity;
        totalAmount += itemTotal;

        const orderItem = new OrderItem();
        orderItem.product = product;
        orderItem.quantity = item.quantity;
        orderItem.price = product.price;
        orderItem.total = itemTotal;

        orderItems.push(orderItem);
      }

      // Create order
      const orderRepository = AppDataSource.getRepository(Order);
      const order = orderRepository.create({
        user,
        deliveryAddress: address,
        items: orderItems,
        totalAmount,
        paymentMethod: paymentMethod || 'UPI',
        notes,
        status: 'pending',
      });

      await orderRepository.save(order);

      // Update product stock
      for (const item of items) {
        const product = await productRepository.findOneBy({ id: item.productId });
        if (product) {
          product.stock -= item.quantity;
          await productRepository.save(product);
        }
      }

      // Create payment order if UPI
      let paymentOrder = null;
      if (paymentMethod === 'UPI') {
        try {
          paymentOrder = await PaymentService.createOrder(
            totalAmount,
            'INR',
            `ORDER_${order.id}`
          );
        } catch (error) {
          console.error('Payment order creation error:', error);
        }
      }

      // Send notification to admin
      await FCMService.sendNotificationToRole(
        'admin',
        'New Order Received',
        `Order #${order.id} for ₹${totalAmount}`,
        { orderId: order.id.toString(), type: 'new_order' }
      );

      res.status(201).json({
        order,
        paymentOrder, // Razorpay order details if UPI
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error creating order' });
    }
  }

  static async getUserOrders(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const orders = await orderRepository.find({
        where: { user: { id: userId } },
        relations: ['user', 'items', 'items.product', 'deliveryAddress', 'deliveryBoy'],
        order: { createdAt: 'DESC' },
      });

      res.json(orders);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching orders' });
    }
  }

  static async getOrderById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id), user: { id: userId } },
        relations: ['user', 'items', 'items.product', 'deliveryAddress', 'deliveryBoy'],
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

  static async getOrderStatus(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id) },
        relations: ['items', 'items.product'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      res.json({
        id: order.id,
        status: order.status,
        totalAmount: order.totalAmount,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching order status' });
    }
  }

  static async cancelOrder(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOne({
        where: { id: Number(id), user: { id: userId } },
        relations: ['items', 'items.product'],
      });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      if (order.status === 'delivered' || order.status === 'cancelled') {
        res.status(400).json({ message: `Cannot cancel order with status: ${order.status}` });
        return;
      }

      // Restore product stock
      const productRepository = AppDataSource.getRepository(Product);
      for (const item of order.items) {
        const product = await productRepository.findOneBy({ id: item.product.id });
        if (product) {
          product.stock += item.quantity;
          await productRepository.save(product);
        }
      }

      order.status = 'cancelled';
      await orderRepository.save(order);

      // Notify admin
      await FCMService.sendNotificationToRole(
        'admin',
        'Order Cancelled',
        `Order #${order.id} has been cancelled`,
        { orderId: order.id.toString(), type: 'order_cancelled' }
      );

      res.json({ message: 'Order cancelled successfully', order });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error cancelling order' });
    }
  }
}

