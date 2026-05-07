"use client";

import { motion } from "framer-motion";
import { Container } from "@/components/ui/Container";
import { GridBg } from "@/components/ui/GridBg";
import { GlowOrb } from "@/components/ui/GlowOrb";
import { Pill } from "@/components/ui/Pill";

export function PageHero({
  eyebrow,
  title,
  highlight,
  subtitle,
}: {
  eyebrow: string;
  title: string;
  highlight: string;
  subtitle: string;
}) {
  return (
    <section className="relative overflow-hidden pt-24 pb-20 md:pt-28 md:pb-24">
      <GridBg />
      <GlowOrb size="xl" color="primary" className="left-1/2 top-0 -translate-x-1/2 -translate-y-1/2 opacity-50" />

      <Container className="relative">
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="flex flex-col items-center text-center"
        >
          <Pill variant="primary">{eyebrow}</Pill>
          <h1 className="mt-6 max-w-4xl text-balance text-5xl font-semibold leading-[1.05] tracking-tight md:text-6xl lg:text-7xl">
            <span className="text-gradient">{title}</span>{" "}
            <span className="text-gradient-primary italic font-display">{highlight}</span>
          </h1>
          <p className="mt-6 max-w-2xl text-balance text-lg leading-relaxed text-[#8B91A1]">
            {subtitle}
          </p>
        </motion.div>
      </Container>
    </section>
  );
}
