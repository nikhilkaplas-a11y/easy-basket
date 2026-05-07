"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { GraduationCap, Users, Trophy, Code2 } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";
import { Pill } from "@/components/ui/Pill";

export function TrainingPreview() {
  const stats = [
    { icon: GraduationCap, label: "4 specialized tracks" },
    { icon: Users, label: "1:1 mentorship" },
    { icon: Code2, label: "Real production projects" },
    { icon: Trophy, label: "Placement assistance" },
  ];
  return (
    <section className="relative overflow-hidden py-28 md:py-36">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-gradient-to-b from-transparent via-[#080B14] to-transparent"
      />
      <div className="absolute left-1/2 top-1/2 h-[600px] w-[600px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#8B5CF6]/10 blur-[140px]" />

      <Container className="relative">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.7 }}
          className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#0F1322] via-[#0A0D17] to-[#0F1322] p-10 md:p-16"
        >
          <div
            aria-hidden
            className="pointer-events-none absolute -right-32 -top-32 h-96 w-96 rounded-full bg-[#4F46E5]/30 blur-[100px]"
          />
          <div
            aria-hidden
            className="pointer-events-none absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-[#06B6D4]/20 blur-[100px]"
          />

          <div className="relative grid items-center gap-12 lg:grid-cols-2">
            <div>
              <Pill variant="primary">For students & engineers</Pill>
              <h2 className="mt-5 text-balance text-4xl font-semibold leading-[1.1] tracking-tight md:text-5xl lg:text-6xl">
                <span className="text-gradient">Learn from engineers who&apos;ve</span>{" "}
                <span className="text-gradient-primary italic font-display">
                  shipped at scale.
                </span>
              </h2>
              <p className="mt-6 max-w-lg text-lg leading-relaxed text-[#8B91A1]">
                DSA, backend, full-stack, system design — taught by the same engineers who lead
                production teams at companies like Zupee. Real projects, real mentorship,
                real outcomes.
              </p>

              <div className="mt-8 grid grid-cols-2 gap-3">
                {stats.map(({ icon: Icon, label }) => (
                  <div
                    key={label}
                    className="flex items-center gap-3 rounded-lg border border-white/10 bg-white/[0.03] px-4 py-3"
                  >
                    <Icon className="h-4 w-4 shrink-0 text-[#A5B4FC]" />
                    <span className="text-xs text-[#E8EAF0]">{label}</span>
                  </div>
                ))}
              </div>

              <div className="mt-10 flex flex-col gap-3 sm:flex-row">
                <Button href="/internships" size="lg" withArrow>
                  Explore tracks
                </Button>
                <Button href="/contact" variant="secondary" size="lg">
                  Talk to a mentor
                </Button>
              </div>
            </div>

            <div className="relative">
              <div className="space-y-3">
                {[
                  { code: "// week 1", title: "Big-O & complexity", glow: "primary" },
                  { code: "// week 4", title: "Trees & recursion", glow: "cyan" },
                  { code: "// week 8", title: "Dynamic programming", glow: "primary" },
                  { code: "// week 12", title: "System design capstone", glow: "purple" },
                ].map((item, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: 30 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true, margin: "-50px" }}
                    transition={{ duration: 0.5, delay: i * 0.1 }}
                    className="flex items-center gap-4 rounded-xl border border-white/10 bg-[#05070D]/60 p-4 backdrop-blur-sm"
                  >
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-[#4F46E5]/15 font-mono text-xs font-bold text-[#A5B4FC]">
                      0{i + 1}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-mono text-[10px] uppercase tracking-wider text-[#5C6275]">
                        {item.code}
                      </p>
                      <p className="mt-0.5 text-sm font-medium text-white">
                        {item.title}
                      </p>
                    </div>
                    <div className="font-mono text-[10px] text-[#5C6275]">
                      ✓
                    </div>
                  </motion.div>
                ))}
              </div>
              <Link
                href="/internships"
                className="group mt-4 flex items-center justify-center gap-2 rounded-xl border border-dashed border-white/10 bg-white/[0.02] py-3 text-xs font-medium text-[#8B91A1] transition-all hover:border-[#4F46E5]/40 hover:text-white"
              >
                + 10 more weeks of structured learning
              </Link>
            </div>
          </div>
        </motion.div>
      </Container>
    </section>
  );
}
