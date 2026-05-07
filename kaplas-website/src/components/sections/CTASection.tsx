"use client";

import { motion } from "framer-motion";
import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";
import { GridBg } from "@/components/ui/GridBg";

export function CTASection() {
  return (
    <section className="relative pb-32">
      <Container>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-80px" }}
          transition={{ duration: 0.7 }}
          className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#0F1322] via-[#0A0D17] to-[#0F1322]"
        >
          <GridBg variant="full" className="opacity-40" />

          <div
            aria-hidden
            className="pointer-events-none absolute left-1/2 top-0 h-[400px] w-[800px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#4F46E5]/30 blur-[120px]"
          />
          <div
            aria-hidden
            className="pointer-events-none absolute -bottom-20 left-1/4 h-64 w-64 rounded-full bg-[#06B6D4]/25 blur-[100px]"
          />

          <div className="relative px-8 py-20 text-center md:px-16 md:py-28">
            <h2 className="mx-auto max-w-3xl text-balance text-4xl font-semibold leading-[1.1] tracking-tight md:text-5xl lg:text-6xl">
              <span className="text-gradient">Ready to build something</span>{" "}
              <span className="text-gradient-primary italic font-display">
                that lasts?
              </span>
            </h2>
            <p className="mx-auto mt-6 max-w-xl text-lg text-[#8B91A1]">
              Whether you&apos;re shipping a v1 or scaling to your next million users,
              we&apos;re ready when you are.
            </p>
            <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <Button href="/contact" size="lg" withArrow>
                Start a project
              </Button>
              <Button href="/services" variant="secondary" size="lg">
                See services
              </Button>
            </div>
          </div>
        </motion.div>
      </Container>
    </section>
  );
}
