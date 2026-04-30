import crypto from 'crypto';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { RedisService } from './redis.service';

/**
 * Delivery-doorstep OTP.
 *
 * Generated when the rider taps "start delivery", sent to the customer, and
 * verified when the rider taps "collect cash" (or "arrived" for prepaid).
 *
 * Storage:
 *   - hash lives in Redis (TTL 30m) — fast-path
 *   - hash ALSO mirrored on `orders.delivery_otp_hash` — offline fallback when Redis is flaky
 *
 * We never store the plaintext; SHA-256 is enough because OTPs are single-use and
 * short-lived (rainbow tables on 6-digit codes are trivial, but a single-attempt TTL
 * makes that useless here).
 *
 * Verification uses `crypto.timingSafeEqual` — no `===` string compare.
 */
export class DeliveryOtpService {
  private static readonly TTL_SECONDS = 30 * 60; // 30 min

  /**
   * Generate a fresh 6-digit OTP, persist its hash on both Redis and the order row.
   * Returns the PLAINTEXT code so the caller can send it to the customer (SMS/FCM).
   */
  static async generateForOrder(orderId: number): Promise<string> {
    const code = this.randomSixDigit();
    const hash = this.hash(code);

    await RedisService.set(this.redisKey(orderId), hash, this.TTL_SECONDS);
    await AppDataSource.getRepository(Order).update(
      { id: orderId },
      { deliveryOtpHash: hash }
    );
    return code;
  }

  /**
   * Verify an OTP supplied by the rider. Returns true only on a match.
   * On success, the OTP is consumed (Redis key deleted + hash cleared on order)
   * so the same code can't be reused.
   *
   * Bypass mechanism (Phase 1.5 — temporary):
   *   If `DELIVERY_OTP_BYPASS_CODE` env var is set, that code is also accepted as
   *   valid for ANY order. Use this ONLY while the SMS/FCM OTP delivery channel
   *   is offline. Remove the env var once SMS is wired (do NOT ship to production
   *   with this enabled long-term — anyone with rider creds could fake-deliver).
   */
  static async verify(orderId: number, code: string): Promise<boolean> {
    if (!/^\d{6}$/.test(code)) return false;

    // --- Optional bypass ---
    const bypass = process.env.DELIVERY_OTP_BYPASS_CODE?.trim();
    if (bypass && bypass.length === 6 && constantTimeStringEqual(bypass, code)) {
      console.warn(
        `[OTP] BYPASS used for order ${orderId} — DELIVERY_OTP_BYPASS_CODE is set; ` +
          `disable in production once SMS is restored.`
      );
      // Bypass also consumes any real OTP so the rider can't reuse it later.
      await Promise.all([
        RedisService.del(this.redisKey(orderId)),
        AppDataSource.getRepository(Order).update({ id: orderId }, { deliveryOtpHash: null }),
      ]);
      return true;
    }

    const submittedHash = this.hash(code);

    const redisHash = await RedisService.get(this.redisKey(orderId));
    let matched = false;
    if (redisHash && constantTimeEqual(redisHash, submittedHash)) {
      matched = true;
    } else {
      // Redis miss or mismatch → fall back to persisted hash on the order row.
      const order = await AppDataSource.getRepository(Order).findOne({
        where: { id: orderId },
        select: ['id', 'deliveryOtpHash'],
      });
      if (order?.deliveryOtpHash && constantTimeEqual(order.deliveryOtpHash, submittedHash)) {
        matched = true;
      }
    }

    if (matched) {
      // Consume — one-time use.
      await Promise.all([
        RedisService.del(this.redisKey(orderId)),
        AppDataSource.getRepository(Order).update({ id: orderId }, { deliveryOtpHash: null }),
      ]);
    }
    return matched;
  }

  /** Remove a generated OTP without consuming (used on RTO / cancellation). */
  static async invalidate(orderId: number): Promise<void> {
    await Promise.all([
      RedisService.del(this.redisKey(orderId)),
      AppDataSource.getRepository(Order).update({ id: orderId }, { deliveryOtpHash: null }),
    ]);
  }

  // -----------------------------------------------------------------------

  private static redisKey(orderId: number): string {
    return `otp:delivery:${orderId}`;
  }

  private static hash(code: string): string {
    return crypto.createHash('sha256').update(code).digest('hex');
  }

  private static randomSixDigit(): string {
    // Uniformly random over 000000–999999 (crypto-safe).
    const n = crypto.randomInt(0, 1_000_000);
    return n.toString().padStart(6, '0');
  }
}

function constantTimeEqual(a: string, b: string): boolean {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false;
  try {
    return crypto.timingSafeEqual(Buffer.from(a, 'hex'), Buffer.from(b, 'hex'));
  } catch {
    return false;
  }
}

/** Constant-time compare for plain (non-hex) strings — used for the bypass code. */
function constantTimeStringEqual(a: string, b: string): boolean {
  if (typeof a !== 'string' || typeof b !== 'string' || a.length !== b.length) return false;
  try {
    return crypto.timingSafeEqual(Buffer.from(a, 'utf8'), Buffer.from(b, 'utf8'));
  } catch {
    return false;
  }
}
