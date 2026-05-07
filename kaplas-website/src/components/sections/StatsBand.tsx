"use client";

import { motion } from "framer-motion";
import { Container } from "@/components/ui/Container";
import { CountUp } from "@/components/ui/CountUp";
import { heroStats } from "@/lib/data";

export function StatsBand() {
  return (
    <section className="relative border-y border-white/5 bg-gradient-to-b from-transparent via-[#0A0D17] to-transparent py-16">
      <Container>
        <div className="grid grid-cols-2 gap-8 md:grid-cols-4">
          {heroStats.map((stat, i) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 12 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.5, delay: i * 0.08 }}
              className="text-center"
            >
              <CountUp
                value={stat.value}
                duration={1.6 + i * 0.15}
                className="text-gradient-primary text-4xl font-bold tracking-tight md:text-5xl"
              />
              <p className="mt-2 text-xs uppercase tracking-[0.15em] text-[#8B91A1] md:text-sm">
                {stat.label}
              </p>
            </motion.div>
          ))}
        </div>
      </Container>
    </section>
  );
}
