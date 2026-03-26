import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { PaymentService } from '../services/payment.service';
import { AuthRequest } from '../middleware/auth.middleware';

export class PaymentController {
  static async createRazorpayOrder(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { amount, orderId } = req.body;

      if (!amount || !orderId) {
        res.status(400).json({ message: 'Amount and order ID are required' });
        return;
      }

      const razorpayOrder = await PaymentService.createOrder(
        parseFloat(amount),
        'INR',
        `ORDER_${orderId}`
      );

      res.json({
        razorpayOrderId: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency,
        key: process.env.RAZORPAY_KEY_ID,
      });
    } catch (error) {
      console.error('Error creating Razorpay order:', error);
      res.status(500).json({ message: 'Error creating payment order' });
    }
  }

  static async verifyPayment(req: Request, res: Response): Promise<void> {
    try {
      const { orderId, paymentId, signature, razorpayOrderId } = req.body;

      if (!orderId || !paymentId || !signature) {
        res.status(400).json({ message: 'Order ID, payment ID, and signature are required' });
        return;
      }

      const orderRepository = AppDataSource.getRepository(Order);
      const order = await orderRepository.findOneBy({ id: Number(orderId) });

      if (!order) {
        res.status(404).json({ message: 'Order not found' });
        return;
      }

      const isValid = await PaymentService.verifyPayment(
        paymentId,
        razorpayOrderId || `ORDER_${orderId}`,
        signature
      );

      if (isValid) {
        order.isPaid = true;
        order.paymentId = paymentId;
        await orderRepository.save(order);

        res.json({ message: 'Payment verified successfully', order });
      } else {
        res.status(400).json({ message: 'Invalid payment signature' });
      }
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error verifying payment' });
    }
  }

  static async razorpayWebhook(req: Request, res: Response): Promise<void> {
    try {
      // Handle Razorpay webhook events
      const event = req.body;

      if (event.event === 'payment.captured') {
        const paymentId = event.payload.payment.entity.id;
        const orderId = event.payload.payment.entity.notes?.orderId;

        if (orderId) {
          const orderRepository = AppDataSource.getRepository(Order);
          const order = await orderRepository.findOneBy({
            id: Number(orderId.replace('ORDER_', '')),
          });

          if (order) {
            order.isPaid = true;
            order.paymentId = paymentId;
            await orderRepository.save(order);
          }
        }
      }

      res.json({ received: true });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error processing webhook' });
    }
  }
}
