"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowRight, ShoppingBasket, Truck, Wallet, MapPin } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { Pill } from "@/components/ui/Pill";
import { GlowOrb } from "@/components/ui/GlowOrb";

export function FeaturedProject() {
  return (
    <section className="relative overflow-hidden py-28 md:py-36">
      <GlowOrb size="xl" color="primary" className="-right-40 top-1/3 opacity-30" />
      <GlowOrb size="lg" color="cyan" className="-left-20 bottom-1/4 opacity-25" />

      <Container className="relative">
        <div className="grid items-center gap-16 lg:grid-cols-2">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.7 }}
            className="flex flex-col items-start"
          >
            <Pill variant="live">Featured · Live</Pill>
            <h2 className="mt-5 text-balance text-4xl font-semibold leading-[1.1] tracking-tight md:text-5xl lg:text-6xl">
              <span className="text-gradient">Hyperlocal grocery,</span>
              <br />
              <span className="text-gradient-primary italic font-display">
                shipped end-to-end.
              </span>
            </h2>
            <p className="mt-6 max-w-lg text-lg leading-relaxed text-[#8B91A1]">
              Easy Basket is a full-stack grocery delivery platform we designed,
              built, and shipped — three apps, one backend, real-time tracking,
              and rock-solid COD reconciliation.
            </p>

            <ul className="mt-8 space-y-3">
              {[
                "Customer app, rider app, merchant dashboard",
                "Real-time order tracking with live rider location",
                "OTP-verified delivery + COD reconciliation",
                "Twilio + FCM + Razorpay integrations",
              ].map((point) => (
                <li
                  key={point}
                  className="flex items-start gap-3 text-sm text-[#E8EAF0]"
                >
                  <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-[#4F46E5]" />
                  <span>{point}</span>
                </li>
              ))}
            </ul>

            <Link
              href="/projects/easy-basket"
              className="group mt-10 inline-flex items-center gap-2 text-sm font-medium text-white"
            >
              Read the case study
              <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-1" />
            </Link>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.94 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true, margin: "-100px" }}
            transition={{ duration: 0.8, ease: [0.21, 0.47, 0.32, 0.98] }}
            className="relative"
          >
            <div className="glow-border relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-white/5 to-transparent p-1">
              <div className="rounded-xl bg-[#0A0D17] p-6 md:p-8">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-500/10 text-emerald-400">
                      <ShoppingBasket className="h-4 w-4" />
                    </div>
                    <p className="text-sm font-semibold text-white">Easy Basket</p>
                  </div>
                  <Pill variant="live">Live</Pill>
                </div>

                <div className="mt-6 space-y-3">
                  <OrderRow
                    icon={<Truck className="h-3.5 w-3.5" />}
                    title="Order #EB-3284"
                    sub="Out for delivery · 2 items"
                    status="On the way"
                    color="text-amber-300 bg-amber-500/10 border-amber-500/30"
                  />
                  <OrderRow
                    icon={<MapPin className="h-3.5 w-3.5" />}
                    title="Order #EB-3283"
                    sub="Picked up · Sec 47"
                    status="Tracking"
                    color="text-cyan-300 bg-cyan-500/10 border-cyan-500/30"
                  />
                  <OrderRow
                    icon={<Wallet className="h-3.5 w-3.5" />}
                    title="COD reconciled"
                    sub="₹2,840 · 14 orders"
                    status="Settled"
                    color="text-emerald-300 bg-emerald-500/10 border-emerald-500/30"
                  />
                </div>

                <div className="mt-6 grid grid-cols-3 gap-3 border-t border-white/5 pt-5">
                  <Stat label="Orders / day" value="240+" />
                  <Stat label="Delivery time" value="22m" />
                  <Stat label="OTP success" value="99.4%" />
                </div>
              </div>
            </div>

            <div
              aria-hidden
              className="pointer-events-none absolute -inset-x-10 -bottom-6 h-20 bg-gradient-to-t from-[#05070D] to-transparent"
            />
          </motion.div>
        </div>
      </Container>
    </section>
  );
}

function OrderRow({
  icon,
  title,
  sub,
  status,
  color,
}: {
  icon: React.ReactNode;
  title: string;
  sub: string;
  status: string;
  color: string;
}) {
  return (
    <div className="flex items-center justify-between rounded-lg border border-white/5 bg-white/[0.02] p-3">
      <div className="flex items-center gap-3">
        <div className="flex h-8 w-8 items-center justify-center rounded-md border border-white/10 bg-white/5 text-[#A5B4FC]">
          {icon}
        </div>
        <div>
          <p className="text-xs font-semibold text-white">{title}</p>
          <p className="text-[11px] text-[#5C6275]">{sub}</p>
        </div>
      </div>
      <span className={`rounded-full border px-2.5 py-0.5 text-[10px] font-medium ${color}`}>
        {status}
      </span>
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-lg font-semibold text-white">{value}</p>
      <p className="text-[10px] uppercase tracking-wide text-[#5C6275]">{label}</p>
    </div>
  );
}
