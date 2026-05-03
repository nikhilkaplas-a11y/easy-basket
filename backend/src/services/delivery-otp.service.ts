import crypto from 'crypto';
import { AppDataSource } from '../config/database';
import { Order } from '../entities/Order';
import { TwilioService } from './twilio.service';

/**
 * Delivery-doorstep OTP — delegated to Twilio Verify (the same provider used
 * for login OTP). Twilio holds the verification state for us; we never see the
 * plaintext code. The customer receives it via SMS to the phone on their
 * account.
 *
 * Bypass:
 *   `DELIVERY_OTP_BYPASS_CODE` env var (e.g. "123456") is accepted as valid
 *   for ANY order, ahead of the Twilio call. Used in dev / QA so we don't
 *   burn SMS credits while testing. Disable on production by unsetting the
 *   env var (or scoping it behind NODE_ENV !== 'production' in deploy config).
 *
 * No FCM push for the OTP — SMS only. Customer apps that need a "delivery
 * started" nudge can subscribe to a separate non-OTP push.
 */
export class DeliveryOtpService {
  /** Send the OTP via Twilio SMS to the customer phone on the order. */
  static async generateForOrder(orderId: number): Promise<{ phoneNumber: string }> {
    const order = await AppDataSource.getRepository(Order).findOne({
      where: { id: orderId },
      relations: ['user'],
      select: { id: true, user: { id: true, phoneNumber: true } },
    });
    const phone = order?.user?.phoneNumber;
    if (!phone) {
      throw new Error(`Cannot send OTP: customer phone not found for order ${orderId}`);
    }
    if (!TwilioService.isConfigured()) {
      // Surface this loudly — we don't fall back to FCM by design.
      // Bypass code (DELIVERY_OTP_BYPASS_CODE) still works at verify-time so
      // dev/QA isn't blocked, but a real customer would never see an OTP.
      console.warn(
        `[OTP] Twilio not configured — verify will only accept the bypass code. Order ${orderId}.`
      );
      return { phoneNumber: phone };
    }
    await TwilioService.sendVerification(phone, 'sms');
    return { phoneNumber: phone };
  }

  /**
   * Verify an OTP supplied by the rider.
   *
   * Order of checks:
   *   1. Bypass code (`DELIVERY_OTP_BYPASS_CODE`) — accepted for any order.
   *   2. Twilio Verify check against the customer's phone.
   *
   * Returns true on either match. Twilio consumes its own verification on
   * success, so the same code can't be reused.
   */
  static async verify(orderId: number, code: string): Promise<boolean> {
    if (!/^\d{6}$/.test(code)) return false;

    // 1. Dev/QA bypass.
    const bypass = process.env.DELIVERY_OTP_BYPASS_CODE?.trim();
    if (bypass && bypass.length === 6 && constantTimeStringEqual(bypass, code)) {
      console.warn(
        `[OTP] BYPASS used for order ${orderId} — DELIVERY_OTP_BYPASS_CODE is set; ` +
          `unset on production once SMS is fully rolled out.`
      );
      return true;
    }

    // 2. Real check — Twilio.
    if (!TwilioService.isConfigured()) {
      console.warn(`[OTP] Twilio not configured; rejecting non-bypass OTP for order ${orderId}.`);
      return false;
    }
    const order = await AppDataSource.getRepository(Order).findOne({
      where: { id: orderId },
      relations: ['user'],
      select: { id: true, user: { id: true, phoneNumber: true } },
    });
    const phone = order?.user?.phoneNumber;
    if (!phone) return false;

    try {
      return await TwilioService.checkVerification(phone, code);
    } catch (e) {
      console.error(`[OTP] Twilio check failed for order ${orderId}`, e);
      return false;
    }
  }

  /**
   * No-op kept for callers that invalidate on RTO/cancel. Twilio Verify
   * expires its own pending verifications; nothing to clear server-side.
   */
  static async invalidate(_orderId: number): Promise<void> {
    return;
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
