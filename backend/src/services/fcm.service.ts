import * as admin from 'firebase-admin';
import { AppDataSource } from '../config/database';
import { User } from '../entities/User';

export class FCMService {
  private static initialized = false;

  static initialize(): void {
    if (this.initialized) {
      return;
    }

    if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
      console.warn('Firebase service account not configured. FCM notifications will be disabled.');
      return;
    }

    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      this.initialized = true;
      console.log('Firebase Admin initialized');
    } catch (error) {
      console.error('Firebase initialization error:', error);
    }
  }

  static async sendNotification(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<boolean> {
    if (!this.initialized) {
      console.warn('FCM not initialized, skipping notification');
      return false;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: data || {},
      });
      return true;
    } catch (error) {
      console.error('Error sending FCM notification:', error);
      return false;
    }
  }

  static async sendNotificationToUser(
    userId: number,
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<boolean> {
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOneBy({ id: userId });

    if (!user || !user.fcmToken) {
      return false;
    }

    return this.sendNotification(user.fcmToken, title, body, data);
  }

  static async sendNotificationToRole(
    role: string,
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<number> {
    const userRepository = AppDataSource.getRepository(User);
    const users = await userRepository.find({
      where: { role, isActive: true },
    });

    let successCount = 0;
    for (const user of users) {
      if (user.fcmToken) {
        const sent = await this.sendNotification(user.fcmToken, title, body, data);
        if (sent) successCount++;
      }
    }

    return successCount;
  }
}

// Initialize on module load
FCMService.initialize();

