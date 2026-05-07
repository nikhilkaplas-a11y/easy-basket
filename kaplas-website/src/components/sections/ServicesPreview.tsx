"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowUpRight } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { services } from "@/lib/data";

export function ServicesPreview() {
  return (
    <section className="relative py-28 md:py-36">
      <Container>
        <SectionHeader
          eyebrow="What we do"
          title={
            <>
              Engineering services
              <br />
              <span className="text-gradient-primary italic font-display">
                with measurable outcomes.
              </span>
            </>
          }
          subtitle="Four core practices, one philosophy: build it right the first time. Ship code that survives Black Friday traffic and outlives the next funding round."
        />

        <div className="mt-20 grid gap-5 md:grid-cols-2">
          {services.map((service, i) => {
            const Icon = service.icon;
            return (
              <motion.div
                key={service.slug}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{
                  duration: 0.6,
                  delay: i * 0.08,
                  ease: [0.21, 0.47, 0.32, 0.98],
                }}
              >
                <Link
                  href={`/services#${service.slug}`}
                  className="group relative block h-full overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-white/[0.01] p-7 transition-all duration-500 hover:border-[#4F46E5]/30 hover:bg-white/[0.06]"
                >
                  <div
                    aria-hidden
                    className="pointer-events-none absolute -right-10 -top-10 h-40 w-40 rounded-full bg-[#4F46E5]/0 blur-3xl transition-all duration-700 group-hover:bg-[#4F46E5]/30"
                  />

                  <div className="relative flex h-full flex-col">
                    <div className="flex items-start justify-between">
                      <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-white/10 bg-white/5 text-[#A5B4FC] transition-all duration-500 group-hover:border-[#4F46E5]/40 group-hover:bg-[#4F46E5]/10 group-hover:text-white">
                        <Icon className="h-5 w-5" />
                      </div>
                      <ArrowUpRight className="h-5 w-5 text-[#5C6275] transition-all duration-500 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-white" />
                    </div>

                    <h3 className="mt-7 text-2xl font-semibold tracking-tight text-white">
                      {service.title}
                    </h3>
                    <p className="mt-3 text-sm leading-relaxed text-[#8B91A1]">
                      {service.short}
                    </p>

                    <div className="mt-6 flex flex-wrap gap-2">
                      {service.stack.slice(0, 4).map((tech) => (
                        <span
                          key={tech}
                          className="rounded-full border border-white/10 bg-white/[0.03] px-2.5 py-1 text-[11px] font-medium text-[#8B91A1]"
                        >
                          {tech}
                        </span>
                      ))}
                    </div>
                  </div>
                </Link>
              </motion.div>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
