import * as admin from 'firebase-admin';
import * as util from 'util';
import { AppDataSource } from '../config/database';
import { User } from '../entities/User';

/** PM2 / aggregators sometimes hide stderr; mirror critical lines to stdout too. */
function fcmEmitFailureLine(context: string, detail: string): void {
  const line = `[FCM][SEND_FAILED] ${context} | ${detail}`;
  process.stdout.write(`${line}\n`);
  process.stderr.write(`${line}\n`);
  console.error(line);
}

function formatFcmError(error: unknown): string {
  try {
    if (error instanceof Error) {
      return `${error.name}: ${error.message}${error.stack ? ` | ${error.stack}` : ''}`;
    }
    if (typeof error === 'object' && error !== null) {
      const o = error as Record<string, unknown>;
      const code = o.code != null ? String(o.code) : '';
      const msg = o.message != null ? String(o.message) : '';
      const details = o.errorInfo ?? o.httpErrorCode ?? '';
      return JSON.stringify({ code, message: msg, details }) + util.inspect(error, { depth: 3, breakLength: 120 });
    }
    return String(error);
  } catch {
    return util.inspect(error, { depth: 2 });
  }
}

/**
 * Token is not valid for this Firebase project (stale app install, wrong project, or truncated token).
 * Safe to clear DB token so the next app open registers a new one.
 */
function isPermanentFcmTokenFailure(error: unknown): boolean {
  const o = typeof error === 'object' && error !== null ? (error as { code?: string; message?: string }) : null;
  const code = o?.code ?? '';
  const msg = (o?.message ?? (error instanceof Error ? error.message : String(error))) as string;
  if (code === 'messaging/registration-token-not-registered') return true;
  if (code === 'messaging/invalid-registration-token') return true;
  if (code === 'messaging/unregistered') return true;
  // HTTP NOT_FOUND from FCM — common text when token does not exist for this sender/project
  if (/requested entity was not found/i.test(msg)) return true;
  if (/not a valid fcm registration token/i.test(msg)) return true;
  return false;
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

  /**
   * Low-level send; returns error object on failure so callers can clear stale DB tokens.
   */
  private static async deliverToToken(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
    context?: string
  ): Promise<{ ok: true } | { ok: false; error: unknown }> {
    const ctx = context ? `[${context}] ` : '';

    if (!this.initialized) {
      const msg = 'FCM not initialized (check FIREBASE_SERVICE_ACCOUNT on this PM2 instance)';
      console.warn(`⚠️ [FCM] ${ctx}${msg}`);
      fcmEmitFailureLine(ctx.trim() || 'send', msg);
      return { ok: false, error: new Error(msg) };
    }

    const token = fcmToken.trim();
    if (token.length < 120) {
      console.warn(
        `⚠️ [FCM] ${ctx}tokenLen=${token.length} is unusually short (typical FCM token ~140–180). Check MySQL column for fcmToken (use VARCHAR(512)+utf8mb4) — truncation causes Send failed.`
      );
    }
    if (token.length !== fcmToken.length) {
      console.warn(`⚠️ [FCM] ${ctx}Token had leading/trailing whitespace; trimmed before send`);
    }
    if (token.length < 10) {
      const msg = `token empty/invalid (len=${token.length})`;
      fcmEmitFailureLine(ctx.trim() || 'send', msg);
      return { ok: false, error: new Error(msg) };
    }

    const tokenPreview = token.length >= 20 ? `${token.substring(0, 20)}...` : token;

    try {
      console.log(
        `📤 [FCM] ${ctx}Sending notification tokenLen=${token.length} preview=${tokenPreview}`
      );
      const response = await admin.messaging().send({
        token,
        notification: {
          title,
          body,
        },
        data: data || {},
      });
      console.log(`✅ [FCM] ${ctx}Notification sent successfully. Message ID: ${response}`);
      return { ok: true };
    } catch (error: unknown) {
      const detail = formatFcmError(error);
      fcmEmitFailureLine(ctx.trim() || 'send', detail);
      return { ok: false, error };
    }
  }

  static async sendNotification(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
    context?: string
  ): Promise<boolean> {
    const r = await this.deliverToToken(fcmToken, title, body, data, context);
    return r.ok;
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
        const rawToken = user.fcmToken;
        const result = await this.deliverToToken(
          rawToken,
          title,
          body,
          data,
          `role=${role} userId=${user.id}`
        );
        if (result.ok) {
          successCount++;
          console.log(`✅ [FCM] Notification sent successfully to user ${user.id}`);
        } else {
          if (isPermanentFcmTokenFailure(result.error)) {
            try {
              const u = await userRepository.findOneBy({ id: user.id });
              if (u?.fcmToken && u.fcmToken.trim() === rawToken.trim()) {
                u.fcmToken = null;
                await userRepository.save(u);
                console.warn(
                  `[FCM] Cleared dead fcmToken for user ${user.id} (${user.phoneNumber}) — open app again to register push. If this repeats, verify mobile google-services.json project matches server FIREBASE_SERVICE_ACCOUNT.`
                );
              }
            } catch (e) {
              console.error('[FCM] Failed to clear stale fcmToken:', e);
            }
          }
          const hint =
            'See [FCM][SEND_FAILED] above. "Requested entity was not found" = token invalid for this Firebase project or stale; re-login on device or fix project mismatch.';
          console.error(
            `❌ [FCM] Notification failed for user ${user.id} (${user.phoneNumber}) — ${hint}`
          );
          process.stdout.write(
            `[FCM][USER_FAIL] userId=${user.id} phone=${user.phoneNumber} | ${hint}\n`
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

