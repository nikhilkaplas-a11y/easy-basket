import type { Metadata } from "next";
import Link from "next/link";
import {
  ArrowLeft,
  ShoppingBasket,
  Truck,
  Wallet,
  Smartphone,
  Server,
  Database,
  Bell,
  MessageSquare,
} from "lucide-react";
import { PageHero } from "@/components/sections/PageHero";
import { Container } from "@/components/ui/Container";
import { Pill } from "@/components/ui/Pill";
import { Reveal } from "@/components/ui/Reveal";
import { GlowOrb } from "@/components/ui/GlowOrb";
import { CTASection } from "@/components/sections/CTASection";

export const metadata: Metadata = {
  title: "Easy Basket — Case Study",
  description:
    "How Kaplas Technology built Easy Basket — a hyperlocal grocery delivery platform with three apps, real-time tracking, and rock-solid COD reconciliation.",
};

const stats = [
  { value: "240+", label: "Orders / day" },
  { value: "22m", label: "Avg delivery time" },
  { value: "99.4%", label: "OTP success rate" },
  { value: "3", label: "Apps shipped" },
];

const challenges = [
  {
    icon: ShoppingBasket,
    title: "Three apps, one source of truth",
    body: "Customer, delivery rider, and merchant — each with different needs but all working off the same order state. Required careful state machine design and event-driven sync across clients.",
  },
  {
    icon: Truck,
    title: "Real-time rider tracking at scale",
    body: "Rider location updates every 5 seconds, broadcast to customers watching their order. Solved with WebSocket-backed pub/sub on Redis and exponential back-off on weak networks.",
  },
  {
    icon: Wallet,
    title: "COD reconciliation without errors",
    body: "Cash-on-delivery means physical cash flows we have to track. Built a dedicated reconciliation service with rider wallet ledgers, so no rupee goes unaccounted for.",
  },
  {
    icon: Bell,
    title: "OTP-verified delivery",
    body: "Originally FCM-push, swapped to Twilio SMS at launch for higher reliability. 99.4% successful first-time OTP delivery now — even in low-network zones.",
  },
];

const stack = {
  Mobile: ["Flutter", "Riverpod", "Mapbox SDK"],
  Backend: ["Node.js", "TypeScript", "Express", "Redis Pub/Sub"],
  Database: ["PostgreSQL", "Redis"],
  Integrations: ["Twilio (SMS + OTP)", "Razorpay (Payments)", "FCM (Push)"],
  Infrastructure: ["AWS EC2", "S3", "CloudFront", "PM2"],
};

export default function EasyBasketCaseStudy() {
  return (
    <>
      <PageHero
        eyebrow="Case Study · Live"
        title="Easy Basket."
        highlight="Hyperlocal grocery, end-to-end."
        subtitle="Three apps, one backend, real-time tracking, COD reconciliation, and OTP-verified delivery — designed and shipped by Kaplas Technology."
      />

      <Container className="-mt-6">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <Link
            href="/projects"
            className="inline-flex items-center gap-2 text-sm font-medium text-[#8B91A1] transition-colors hover:text-white"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to projects
          </Link>
          <Pill variant="live">Live in production</Pill>
        </div>
      </Container>

      <section className="relative py-12 md:py-16">
        <GlowOrb size="lg" color="primary" className="-left-40 top-1/4 opacity-30" />
        <GlowOrb size="lg" color="cyan" className="-right-20 top-1/2 opacity-25" />

        <Container>
          <Reveal>
            <div className="mx-auto grid max-w-5xl grid-cols-2 gap-px overflow-hidden rounded-2xl border border-white/10 bg-white/5 md:grid-cols-4">
              {stats.map((stat) => (
                <div
                  key={stat.label}
                  className="bg-[#0A0D17] px-6 py-8 text-center"
                >
                  <p className="text-gradient-primary text-3xl font-bold tracking-tight md:text-4xl">
                    {stat.value}
                  </p>
                  <p className="mt-2 text-xs uppercase tracking-[0.15em] text-[#8B91A1]">
                    {stat.label}
                  </p>
                </div>
              ))}
            </div>
          </Reveal>
        </Container>
      </section>

      <section className="relative py-20">
        <Container size="narrow">
          <Reveal>
            <h2 className="text-3xl font-semibold tracking-tight text-white md:text-4xl">
              <span className="text-gradient-primary italic font-display">The brief.</span>
            </h2>
            <p className="mt-6 text-lg leading-relaxed text-[#8B91A1]">
              Build a hyperlocal grocery delivery platform from scratch — designed for tier-2
              Indian cities, with strong COD support, multilingual interfaces, and reliable
              delivery in patchy-network areas.
            </p>
            <p className="mt-4 text-lg leading-relaxed text-[#8B91A1]">
              The catch: ship three coordinated apps (customer, rider, merchant) and a
              backend that holds them all together — without burning months of runway.
            </p>
          </Reveal>
        </Container>
      </section>

      <section className="relative py-12 md:py-20">
        <Container>
          <Reveal>
            <h2 className="text-balance text-3xl font-semibold tracking-tight md:text-5xl">
              <span className="text-gradient">Four hard problems we </span>
              <span className="text-gradient-primary italic font-display">solved.</span>
            </h2>
          </Reveal>

          <div className="mt-14 grid gap-5 md:grid-cols-2">
            {challenges.map((c, i) => {
              const Icon = c.icon;
              return (
                <Reveal key={c.title} delay={i * 0.06}>
                  <div className="h-full rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-7">
                    <div className="flex h-11 w-11 items-center justify-center rounded-xl border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                      <Icon className="h-5 w-5" />
                    </div>
                    <h3 className="mt-5 text-xl font-semibold tracking-tight text-white">
                      {c.title}
                    </h3>
                    <p className="mt-3 text-[15px] leading-relaxed text-[#8B91A1]">
                      {c.body}
                    </p>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </Container>
      </section>

      <section className="relative py-12 md:py-20">
        <Container>
          <Reveal>
            <h2 className="text-balance text-3xl font-semibold tracking-tight md:text-5xl">
              <span className="text-gradient">Architecture & </span>
              <span className="text-gradient-primary italic font-display">stack.</span>
            </h2>
            <p className="mt-5 max-w-2xl text-lg text-[#8B91A1]">
              Modern, battle-tested choices — picked for reliability and the realities of
              shipping fast in a small team.
            </p>
          </Reveal>

          <div className="mt-12 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {Object.entries(stack).map(([category, items], i) => {
              const icons = [Smartphone, Server, Database, MessageSquare, Bell];
              const Icon = icons[i % icons.length];
              return (
                <Reveal key={category} delay={i * 0.05}>
                  <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-6">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                        <Icon className="h-4 w-4" />
                      </div>
                      <h3 className="text-base font-semibold text-white">
                        {category}
                      </h3>
                    </div>
                    <div className="mt-5 flex flex-wrap gap-2">
                      {items.map((item) => (
                        <span
                          key={item}
                          className="rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs text-[#E8EAF0]"
                        >
                          {item}
                        </span>
                      ))}
                    </div>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </Container>
      </section>

      <section className="relative py-20">
        <Container size="narrow">
          <Reveal>
            <div className="rounded-3xl border border-white/10 bg-gradient-to-br from-[#0F1322] to-[#0A0D17] p-10 md:p-14">
              <p className="font-mono text-xs uppercase tracking-[0.2em] text-[#5C6275]">
                Outcome
              </p>
              <h2 className="mt-4 text-balance text-3xl font-semibold tracking-tight md:text-4xl">
                <span className="text-gradient">Live, profitable, and </span>
                <span className="text-gradient-primary italic font-display">growing.</span>
              </h2>
              <p className="mt-6 text-lg leading-relaxed text-[#8B91A1]">
                Easy Basket runs in production today, processing hundreds of orders per day
                with 99.4% OTP delivery and a 22-minute average fulfillment time. The COD
                reconciliation system has yet to lose a single rupee.
              </p>
              <p className="mt-4 text-lg leading-relaxed text-[#8B91A1]">
                More importantly, the architecture handles 3× growth without changes — proving
                that getting the foundation right pays off when scale arrives.
              </p>
            </div>
          </Reveal>
        </Container>
      </section>

      <CTASection />
    </>
  );
}
