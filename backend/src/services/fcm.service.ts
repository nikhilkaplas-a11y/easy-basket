import * as admin from 'firebase-admin';
import { AppDataSource } from '../config/database';
import { User } from '../entities/User';

function formatFcmError(error: unknown): string {
  if (error instanceof Error) {
    return `${error.name}: ${error.message}${error.stack ? `\n${error.stack}` : ''}`;
  }
  if (typeof error === 'object' && error !== null) {
    try {
      const o = error as Record<string, unknown>;
      const code = o.code != null ? String(o.code) : '';
      const msg = o.message != null ? String(o.message) : '';
      const details = o.errorInfo ?? o.httpErrorCode ?? '';
      return JSON.stringify({ code, message: msg, details, raw: String(error) });
    } catch {
      return String(error);
    }
  }
  return String(error);
}

export class FCMService {
  private static initialized = false;

  /**
   * Run notification I/O off the request path. Failures are logged only and never reject callers.
   */
  static enqueue(task: () => Promise<unknown>, label: string): void {
    void Promise.resolve()
      .then(task)
      .catch((error) => {
        console.error(`❌ [FCM] Background task failed [${label}]: ${formatFcmError(error)}`);
      });
  }

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
    data?: Record<string, string>,
    context?: string
  ): Promise<boolean> {
    const ctx = context ? `[${context}] ` : '';

    if (!this.initialized) {
      console.warn(`⚠️ [FCM] ${ctx}FCM not initialized, skipping notification`);
      return false;
    }

    const tokenPreview =
      fcmToken.length >= 20 ? `${fcmToken.substring(0, 20)}...` : `${fcmToken} (short token?)`;

    try {
      console.log(`📤 [FCM] ${ctx}Sending notification to token: ${tokenPreview}`);
      const response = await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: data || {},
      });
      console.log(`✅ [FCM] ${ctx}Notification sent successfully. Message ID: ${response}`);
      return true;
    } catch (error: unknown) {
      // Always one line + structured detail so PM2 / log aggregators never show an "empty" error
      console.error(`❌ [FCM] ${ctx}Send failed: ${formatFcmError(error)}`);
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

    return this.sendNotification(user.fcmToken, title, body, data, `userId=${userId}`);
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

    const tokensSeen = new Set<string>();
    let successCount = 0;
    let tokenCount = 0;

    for (const user of users) {
      if (user.fcmToken) {
        tokenCount++;
        if (tokensSeen.has(user.fcmToken)) {
          console.warn(
            `⚠️ [FCM] User ${user.id} (${user.phoneNumber}) shares the same FCM token as another admin — stale logins or test accounts; only one device will get pushes.`
          );
        }
        tokensSeen.add(user.fcmToken);
        console.log(
          `📤 [FCM] Sending to user ${user.id} (${user.phoneNumber}), token: ${user.fcmToken.substring(0, 20)}...`
        );
        const sent = await this.sendNotification(
          user.fcmToken,
          title,
          body,
          data,
          `role=${role} userId=${user.id}`
        );
        if (sent) {
          successCount++;
          console.log(`✅ [FCM] Notification sent successfully to user ${user.id}`);
        } else {
          console.error(
            `❌ [FCM] Notification failed for user ${user.id} (${user.phoneNumber}) — see Send failed line above for Firebase reason`
          );
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

