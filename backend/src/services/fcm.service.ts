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
      console.warn('⚠️ [FCM] FCM not initialized, skipping notification');
      return false;
    }

    try {
      console.log(`📤 [FCM] Sending notification to token: ${fcmToken.substring(0, 20)}...`);
      const response = await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: data || {},
      });
      console.log(`✅ [FCM] Notification sent successfully. Message ID: ${response}`);
      return true;
    } catch (error: any) {
      console.error('❌ [FCM] Error sending notification:', error);
      if (error.code) {
        console.error(`❌ [FCM] Error code: ${error.code}`);
      }
      if (error.message) {
        console.error(`❌ [FCM] Error message: ${error.message}`);
      }
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
    console.log(`📤 [FCM] Sending notification to role: ${role}`);
    console.log(`📤 [FCM] Title: ${title}, Body: ${body}`);
    
    if (!this.initialized) {
      console.warn('⚠️ [FCM] FCM not initialized, skipping notification');
      return 0;
    }

    const userRepository = AppDataSource.getRepository(User);
    const users = await userRepository.find({
      where: { role, isActive: true },
    });

    console.log(`📤 [FCM] Found ${users.length} ${role} users`);
    
    let successCount = 0;
    let tokenCount = 0;
    
    for (const user of users) {
      if (user.fcmToken) {
        tokenCount++;
        console.log(`📤 [FCM] Sending to user ${user.id} (${user.phoneNumber}), token: ${user.fcmToken.substring(0, 20)}...`);
        const sent = await this.sendNotification(user.fcmToken, title, body, data);
        if (sent) {
          successCount++;
          console.log(`✅ [FCM] Notification sent successfully to user ${user.id}`);
        } else {
          console.error(`❌ [FCM] Failed to send notification to user ${user.id}`);
        }
      } else {
        console.warn(`⚠️ [FCM] User ${user.id} (${user.phoneNumber}) has no FCM token`);
      }
    }

    console.log(`📤 [FCM] Summary: ${successCount}/${tokenCount} notifications sent successfully`);
    return successCount;
  }
}

// Initialize on module load
FCMService.initialize();

