"use client";

import { motion } from "framer-motion";
import { CheckCircle2, Code2, Users, Zap } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { SectionHeader } from "@/components/ui/SectionHeader";

const reasons = [
  {
    icon: Code2,
    title: "Engineers, not freelancers",
    body:
      "Our team has shipped production systems at Amazon, Zupee, and FinTech platforms processing millions in daily volume. We know what production-grade actually means.",
  },
  {
    icon: Zap,
    title: "Speed without shortcuts",
    body:
      "We move fast — but we don't trade off testing, observability, or scale-readiness. Code we write is code we'd ship at our day job.",
  },
  {
    icon: Users,
    title: "Direct line to senior engineers",
    body:
      "No account managers, no junior subcontractors. You talk to the engineers building your system. Decisions in hours, not weeks.",
  },
  {
    icon: CheckCircle2,
    title: "Outcomes over hours",
    body:
      "Latency cut by 60%. Cost down by $10K/month. Onboarding 70% faster. Every engagement ships with measurable results we put in writing.",
  },
];

export function WhyKaplas() {
  return (
    <section className="relative py-28 md:py-36">
      <Container>
        <SectionHeader
          eyebrow="Why Kaplas Technology"
          title={
            <>
              Built by engineers who&apos;ve
              <br />
              <span className="text-gradient-primary italic font-display">
                been on the other side.
              </span>
            </>
          }
          subtitle="We've sat in your seat. We know what 'just ship it' costs at 3am when the load balancer falls over. That's why we build it right the first time."
        />

        <div className="mt-20 grid gap-5 md:grid-cols-2">
          {reasons.map((reason, i) => {
            const Icon = reason.icon;
            return (
              <motion.div
                key={reason.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{
                  duration: 0.6,
                  delay: i * 0.08,
                  ease: [0.21, 0.47, 0.32, 0.98],
                }}
                className="group relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-8 transition-all duration-500 hover:border-white/20"
              >
                <div className="flex items-center gap-4">
                  <div className="flex h-11 w-11 items-center justify-center rounded-xl border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                    <Icon className="h-5 w-5" />
                  </div>
                  <h3 className="text-xl font-semibold tracking-tight text-white">
                    {reason.title}
                  </h3>
                </div>
                <p className="mt-5 text-[15px] leading-relaxed text-[#8B91A1]">
                  {reason.body}
                </p>
              </motion.div>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
