import { Worker, type Job } from 'bullmq';
import { AppDataSource } from '../../config/database';
import { Payment, type PaymentStatus } from '../../entities/Payment';
import { PaymentsReconcilerService } from '../payments-reconciler.service';
import { buildBullConnection } from './connection';
import { PAYMENT_QUEUE_NAME, type PaymentReconcileJobData } from './payment-queue';

const TERMINAL: PaymentStatus[] = ['paid', 'failed', 'refunded'];
const CONCURRENCY = Number(process.env.PAYMENT_WORKER_CONCURRENCY) || 5;

/**
 * BullMQ worker that confirms a payment quickly when the webhook is missed.
 *
 * It reuses the reconciler's per-payment logic (asks Razorpay, then applies the
 * same idempotent, Redis-lock-guarded transition the webhook would). If the
 * payment is still non-terminal after the check, it throws so BullMQ retries
 * with exponential backoff. No double-processing: the shared lock + idempotent
 * markPaymentPaid mean the worker and a live webhook can't conflict.
 */
export function startPaymentWorker(): Worker<PaymentReconcileJobData> {
  const worker = new Worker<PaymentReconcileJobData>(
    PAYMENT_QUEUE_NAME,
    async (job: Job<PaymentReconcileJobData>) => {
      const repo = AppDataSource.getRepository(Payment);
      const payment = await repo.findOne({ where: { id: job.data.paymentId } });
      if (!payment) return; // row gone — nothing to do
      if (TERMINAL.includes(payment.status)) return; // webhook already confirmed it

      await PaymentsReconcilerService.reconcileOnePayment(payment);

      // Still not terminal (authorized/created/lock-was-busy)? throw → retry with backoff.
      const after = await repo.findOne({ where: { id: job.data.paymentId } });
      if (after && !TERMINAL.includes(after.status)) {
        throw new Error(`payment ${job.data.paymentId} still ${after.status} — retry`);
      }
    },
    { connection: buildBullConnection(), concurrency: CONCURRENCY }
  );

  worker.on('failed', (job, err) =>
    console.error(`[payment-worker] job ${job?.id} failed: ${err.message}`)
  );

  console.log(`[payment-worker] started (concurrency=${CONCURRENCY})`);
  return worker;
}
