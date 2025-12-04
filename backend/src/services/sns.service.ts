import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

export class SNSService {
  private static snsClient: SNSClient | null = null;
  private static isInitialized = false;

  static initialize(): void {
    if (this.isInitialized) return;

    const region = process.env.AWS_REGION || 'eu-north-1';
    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

    if (!accessKeyId || !secretAccessKey) {
      console.warn('AWS SNS credentials not configured. OTP SMS will be disabled.');
      return;
    }

    this.snsClient = new SNSClient({
      region,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
    });

    this.isInitialized = true;
    console.log('AWS SNS initialized successfully');
  }

  /**
   * Send OTP via SMS using AWS SNS
   * @param phoneNumber - Phone number in E.164 format (e.g., +919876543210)
   * @param otp - The OTP code to send
   * @returns Promise<boolean> - true if sent successfully, false otherwise
   */
  static async sendOTP(phoneNumber: string, otp: string): Promise<boolean> {
    if (!this.snsClient) {
      console.warn('AWS SNS not initialized. OTP not sent.');
      return false;
    }

    try {
      // Format phone number to E.164 format if needed
      let formattedNumber = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Assume Indian number if no country code
        if (phoneNumber.length === 10) {
          formattedNumber = `+91${phoneNumber}`;
        } else {
          formattedNumber = `+${phoneNumber}`;
        }
      }

      // Create SMS message
      const message = `Your Easy Basket OTP is ${otp}. Valid for 5 minutes. Do not share this OTP with anyone.`;

      const command = new PublishCommand({
        PhoneNumber: formattedNumber,
        Message: message,
        MessageAttributes: {
          'AWS.SNS.SMS.SMSType': {
            DataType: 'String',
            StringValue: 'Transactional', // Use 'Promotional' for marketing messages
          },
        },
      });

      const response = await this.snsClient.send(command);

      if (response.MessageId) {
        console.log(`OTP SMS sent successfully to ${formattedNumber}. MessageId: ${response.MessageId}`);
        return true;
      }

      return false;
    } catch (error: any) {
      console.error('Error sending OTP via AWS SNS:', error);
      console.error('Error details:', {
        code: error.code,
        message: error.message,
        phoneNumber,
      });
      return false;
    }
  }

  /**
   * Check if SNS is configured and available
   */
  static isAvailable(): boolean {
    return this.snsClient !== null && this.isInitialized;
  }
}

// Initialize on module load
SNSService.initialize();

