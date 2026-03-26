import Razorpay from 'razorpay';

export class PaymentService {
  private static razorpayInstance: Razorpay | null = null;

  static initialize(): void {
    if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
      this.razorpayInstance = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
      });
      console.log('Razorpay initialized');
    } else {
      console.warn('Razorpay credentials not configured');
    }
  }

  static async createOrder(amount: number, currency: string = 'INR', orderId: string) {
    if (!this.razorpayInstance) {
      throw new Error('Razorpay not initialized');
    }

    try {
      const options = {
        amount: amount * 100, // Convert to paise
        currency,
        receipt: orderId,
        notes: {
          orderId,
        },
      };

      const razorpayOrder = await this.razorpayInstance.orders.create(options);
      return razorpayOrder;
    } catch (error) {
      console.error('Error creating Razorpay order:', error);
      throw error;
    }
  }

  static async verifyPayment(
    paymentId: string,
    orderId: string,
    signature: string
  ): Promise<boolean> {
    if (!this.razorpayInstance) {
      return false;
    }

    const crypto = require('crypto');
    const generatedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '')
      .update(orderId + '|' + paymentId)
      .digest('hex');

    return generatedSignature === signature;
  }

  // Cashfree integration (placeholder - implement based on Cashfree SDK)
  static async createCashfreeOrder(amount: number, orderId: string) {
    // TODO: Implement Cashfree integration
    console.log('Cashfree integration not implemented yet');
    return null;
  }
}

// Initialize on module load
PaymentService.initialize();
