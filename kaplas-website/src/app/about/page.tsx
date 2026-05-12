import type { Metadata } from "next";
import { Briefcase, GraduationCap, MapPin, Code2 } from "lucide-react";
import { PageHero } from "@/components/sections/PageHero";
import { Container } from "@/components/ui/Container";
import { Reveal } from "@/components/ui/Reveal";
import { Button } from "@/components/ui/Button";
import { GlowOrb } from "@/components/ui/GlowOrb";
import { CTASection } from "@/components/sections/CTASection";
import { founderStats } from "@/lib/data";

export const metadata: Metadata = {
  title: "About",
  description:
    "Kaplas Technology is led by Nikhil Kaplas — Engineering Manager at Zupee, building production FinTech platforms that handle millions in daily volume.",
};

const career = [
  {
    role: "Engineering Manager",
    company: "Zupee",
    period: "Apr 2025 – Present",
    location: "Gurgaon",
    points: [
      "Leading 20-member cross-functional team across backend, frontend, and QA",
      "Architected centralized payout orchestration — 70% faster PG onboarding",
      "Launched UPI AutoPay driving 90% payment conversion",
    ],
  },
  {
    role: "Tech Lead",
    company: "Zupee",
    period: "Jan 2024 – Mar 2025",
    location: "Gurgaon",
    points: [
      "Intelligent payment routing — 25% transaction success uplift",
      "Unified PG abstraction over PhonePe + Razorpay — saved $10K/month",
      "Async credit settlement via SQS — handles 100K+ payouts reliably",
    ],
  },
  {
    role: "SDE-2",
    company: "Zupee",
    period: "Jan 2023 – Dec 2023",
    location: "Gurgaon",
    points: [
      "Delivered 30% TDS compliance in 10 days — zero customer impact",
      "Stabilized wallet microservice — error rate 10% → 0.1%",
      "Cashback framework lifting retention by 15% at 1% utilization",
    ],
  },
  {
    role: "SDE-1",
    company: "Zupee",
    period: "Jul 2021 – Dec 2022",
    location: "Gurgaon",
    points: [
      "Built sub-wallet system saving ₹2 Cr annually",
      "Re-engineered invoicing — 2-3 days down to under 1 minute",
      "Serverless MapReduce on AWS — cut reconciliation by 80%",
    ],
  },
  {
    role: "Software Engineer",
    company: "Amazon",
    period: "Jan 2020 – Jun 2021",
    location: "Bangalore",
    points: [
      "Instituted 4-hour delivery windows for Retail and Fresh — 20% higher order success",
      "Developed UFG Fresh order pages — enabled 3P stores on Amazon IN",
      "Cross-team incident resolution — alert noise down 50%",
    ],
  },
  {
    role: "Software Engineer",
    company: "Josh Technology",
    period: "Jul 2018 – Jan 2020",
    location: "Gurugram",
    points: [
      "Directed MentorCloud program — user engagement up 25%",
      "Django 1.8 → 1.11 migration — 15% performance improvement",
      "New Relic monitoring with caching — API latency cut by 30%",
    ],
  },
];

export default function AboutPage() {
  return (
    <>
      <PageHero
        eyebrow="About"
        title="Built by an engineer who's"
        highlight="been on the other side."
        subtitle="Kaplas Technology is the next chapter for Nikhil Kaplas — Engineering Manager at Zupee, leading a 20-person team building FinTech that processes millions in daily volume."
      />

      <section className="relative py-12 md:py-20">
        <GlowOrb size="lg" color="primary" className="-left-40 top-0 opacity-30" />
        <GlowOrb size="lg" color="cyan" className="-right-40 bottom-0 opacity-25" />

        <Container size="narrow" className="relative">
          <Reveal>
            <div className="grid items-center gap-12 md:grid-cols-12">
              <div className="md:col-span-4">
                <div className="relative mx-auto h-56 w-56 overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-[#0F1322] to-[#0A0D17] md:mx-0">
                  <div
                    aria-hidden
                    className="pointer-events-none absolute inset-0 bg-gradient-to-br from-[#4F46E5]/20 to-transparent"
                  />
                  <div className="relative flex h-full items-center justify-center font-display text-7xl font-bold text-gradient-primary">
                    NK
                  </div>
                </div>
              </div>
              <div className="md:col-span-8">
                <p className="font-mono text-xs uppercase tracking-[0.2em] text-[#A5B4FC]">
                  Founder
                </p>
                <h2 className="mt-3 text-4xl font-semibold tracking-tight text-white md:text-5xl">
                  Nikhil Kaplas
                </h2>
                <p className="mt-2 text-lg text-[#A5B4FC]">
                  Engineering Manager · Payments &amp; Wallet Platform
                </p>
                <p className="mt-5 text-[15px] leading-relaxed text-[#8B91A1]">
                  Eight years of engineering across Josh Technology, Amazon, and Zupee —
                  with a sharp focus on payments, distributed systems, and high-availability
                  infrastructure. Currently mentoring a 20-engineer team while running
                  Kaplas Technology on the side.
                </p>
                <div className="mt-6 flex flex-wrap items-center gap-3">
                  <span className="inline-flex items-center gap-2 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-[#E8EAF0]">
                    <GraduationCap className="h-3.5 w-3.5 text-[#A5B4FC]" />
                    B.Tech Computer Engineering, Thapar University
                  </span>
                  <span className="inline-flex items-center gap-2 rounded-lg border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-[#E8EAF0]">
                    <MapPin className="h-3.5 w-3.5 text-[#A5B4FC]" />
                    Gurugram, India
                  </span>
                </div>
              </div>
            </div>
          </Reveal>
        </Container>
      </section>

      <section className="relative py-12 md:py-20">
        <Container size="narrow">
          <Reveal>
            <div className="grid grid-cols-2 gap-px overflow-hidden rounded-2xl border border-white/10 bg-white/5 md:grid-cols-4">
              {founderStats.map((stat) => (
                <div
                  key={stat.label}
                  className="bg-[#0A0D17] px-4 py-8 text-center"
                >
                  <p className="text-gradient-primary text-3xl font-bold tracking-tight md:text-4xl">
                    {stat.value}
                  </p>
                  <p className="mt-2 text-[11px] leading-relaxed text-[#8B91A1] md:text-xs">
                    {stat.label}
                  </p>
                </div>
              ))}
            </div>
          </Reveal>
        </Container>
      </section>

      <section className="relative py-12 md:py-20">
        <Container size="narrow">
          <Reveal>
            <div className="text-center">
              <h2 className="text-balance text-4xl font-semibold tracking-tight md:text-5xl">
                <span className="text-gradient">Career </span>
                <span className="text-gradient-primary italic font-display">timeline.</span>
              </h2>
              <p className="mt-5 text-lg text-[#8B91A1]">
                From SDE-1 to Engineering Manager — 7 years of shipping production systems.
              </p>
            </div>
          </Reveal>

          <div className="relative mt-16">
            <div
              aria-hidden
              className="absolute left-4 top-2 bottom-2 w-px bg-gradient-to-b from-[#4F46E5]/40 via-white/10 to-transparent md:left-1/2 md:-translate-x-1/2"
            />
            <div className="space-y-10">
              {career.map((c, i) => (
                <Reveal key={`${c.role}-${c.period}`} delay={i * 0.04}>
                  <div className="relative grid gap-6 md:grid-cols-2 md:gap-12">
                    <div
                      className={`pl-12 md:pl-0 ${
                        i % 2 === 0 ? "md:text-right md:pr-12" : "md:order-2 md:pl-12"
                      }`}
                    >
                      <div
                        className={`absolute left-2.5 top-1.5 h-3 w-3 rounded-full border-2 border-[#4F46E5] bg-[#05070D] md:left-1/2 md:-translate-x-1/2`}
                      />
                      <p className="font-mono text-xs uppercase tracking-[0.18em] text-[#5C6275]">
                        {c.period}
                      </p>
                      <h3 className="mt-2 text-xl font-semibold tracking-tight text-white">
                        {c.role}
                      </h3>
                      <p className="mt-1 inline-flex items-center gap-2 text-sm text-[#A5B4FC]">
                        <Briefcase className="h-3.5 w-3.5" />
                        {c.company} · <span className="text-[#5C6275]">{c.location}</span>
                      </p>
                    </div>
                    <div
                      className={`pl-12 md:pl-12 ${
                        i % 2 === 0 ? "" : "md:order-1 md:pr-12 md:pl-0 md:text-right"
                      }`}
                    >
                      <ul className="space-y-2">
                        {c.points.map((p) => (
                          <li
                            key={p}
                            className={`flex items-start gap-2 text-sm text-[#8B91A1] ${
                              i % 2 !== 0 ? "md:flex-row-reverse" : ""
                            }`}
                          >
                            <span className="mt-1.5 h-1 w-1 shrink-0 rounded-full bg-[#A5B4FC]" />
                            <span>{p}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </Reveal>
              ))}
            </div>
          </div>
        </Container>
      </section>

      <section className="relative py-20">
        <Container size="narrow">
          <Reveal>
            <div className="rounded-3xl border border-white/10 bg-gradient-to-br from-[#0F1322] to-[#0A0D17] p-10 md:p-14">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                <Code2 className="h-5 w-5" />
              </div>
              <h2 className="mt-6 text-balance text-3xl font-semibold tracking-tight md:text-4xl">
                <span className="text-gradient">Why Kaplas Technology </span>
                <span className="text-gradient-primary italic font-display">exists.</span>
              </h2>
              <div className="mt-6 space-y-4 text-lg leading-relaxed text-[#8B91A1]">
                <p>
                  Most agencies are run by salespeople. The work is subcontracted to
                  whoever&apos;s cheapest — and you find out only when the system falls
                  over in production.
                </p>
                <p>
                  Kaplas Technology is run by an engineer. The work is done by engineers.
                  We pick projects we&apos;d be proud to put on our resume — and we treat
                  every engagement like our own product.
                </p>
                <p>
                  And on the training side — when someone asks &quot;how do I become a
                  great engineer?&quot;, the honest answer is: &quot;learn from a great
                  engineer who&apos;s shipping production code today.&quot; That&apos;s
                  what we offer.
                </p>
              </div>
              <div className="mt-10">
                <Button href="/contact" size="lg" withArrow>
                  Work with us
                </Button>
              </div>
            </div>
          </Reveal>
        </Container>
      </section>

      <CTASection />
    </>
  );
}
