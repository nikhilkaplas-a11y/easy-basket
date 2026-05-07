"use client";

import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence, useMotionValue, useSpring } from "framer-motion";
import { ArrowRight, Sparkles } from "lucide-react";
import Link from "next/link";
import { Container } from "@/components/ui/Container";
import { Button } from "@/components/ui/Button";
import { GridBg } from "@/components/ui/GridBg";
import { GlowOrb } from "@/components/ui/GlowOrb";
import { Particles } from "@/components/ui/Particles";

const ROTATING_WORDS = ["scale.", "ship.", "last.", "grow."];

export function Hero() {
  const [wordIndex, setWordIndex] = useState(0);
  const heroRef = useRef<HTMLElement>(null);

  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);
  const springX = useSpring(mouseX, { stiffness: 80, damping: 20, mass: 0.6 });
  const springY = useSpring(mouseY, { stiffness: 80, damping: 20, mass: 0.6 });

  useEffect(() => {
    const id = setInterval(() => {
      setWordIndex((i) => (i + 1) % ROTATING_WORDS.length);
    }, 2400);
    return () => clearInterval(id);
  }, []);

  useEffect(() => {
    const el = heroRef.current;
    if (!el) return;
    function onMove(e: MouseEvent) {
      const rect = el!.getBoundingClientRect();
      mouseX.set(e.clientX - rect.left);
      mouseY.set(e.clientY - rect.top);
    }
    el.addEventListener("mousemove", onMove);
    return () => el.removeEventListener("mousemove", onMove);
  }, [mouseX, mouseY]);

  return (
    <section
      ref={heroRef}
      className="relative overflow-hidden pt-20 pb-32 md:pt-28 md:pb-40"
    >
      <GridBg />

      <motion.div
        aria-hidden
        style={{
          x: springX,
          y: springY,
          translateX: "-50%",
          translateY: "-50%",
        }}
        className="pointer-events-none absolute h-[520px] w-[520px] rounded-full bg-[#4F46E5]/15 blur-[100px] mix-blend-screen"
      />

      <GlowOrb
        size="xl"
        color="primary"
        className="left-1/2 top-0 -translate-x-1/2 -translate-y-1/3 opacity-70 animate-orb-1"
      />
      <GlowOrb size="lg" color="cyan" className="-left-20 top-1/3 opacity-40 animate-orb-2" />
      <GlowOrb size="lg" color="purple" className="-right-20 top-1/4 opacity-40 animate-orb-3" />
      <Particles count={50} />

      <Container className="relative">
        <div className="flex flex-col items-center text-center">
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <Link
              href="/projects/easy-basket"
              className="group inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-1.5 text-xs font-medium text-[#A5B4FC] backdrop-blur-sm transition-all hover:border-[#4F46E5]/40 hover:bg-[#4F46E5]/10"
            >
              <Sparkles className="h-3 w-3" />
              <span>Now live: Easy Basket case study</span>
              <ArrowRight className="h-3 w-3 transition-transform group-hover:translate-x-0.5" />
            </Link>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.1 }}
            className="mt-8 max-w-5xl text-balance text-5xl font-semibold leading-[1.05] tracking-tight md:text-7xl lg:text-[5.5rem]"
          >
            <span className="text-gradient">Engineering products </span>
            <span className="block text-gradient">that actually </span>
            <span className="relative inline-block">
              <AnimatePresence mode="wait">
                <motion.span
                  key={wordIndex}
                  initial={{ opacity: 0, y: 24, filter: "blur(8px)" }}
                  animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
                  exit={{ opacity: 0, y: -24, filter: "blur(8px)" }}
                  transition={{ duration: 0.5, ease: [0.21, 0.47, 0.32, 0.98] }}
                  className="inline-block text-gradient-primary italic font-display"
                >
                  {ROTATING_WORDS[wordIndex]}
                </motion.span>
              </AnimatePresence>
              <span aria-hidden className="invisible italic font-display">
                ship.&nbsp;
              </span>
            </span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.2 }}
            className="mt-7 max-w-2xl text-balance text-lg leading-relaxed text-[#8B91A1] md:text-xl"
          >
            We build production-grade web, mobile, and backend systems for fast-moving startups —
            and train the next generation of engineers through hands-on internships.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.3 }}
            className="mt-10 flex flex-col items-center gap-3 sm:flex-row"
          >
            <Button href="/contact" size="lg" withArrow>
              Start a project
            </Button>
            <Button href="/projects" variant="secondary" size="lg">
              See our work
            </Button>
          </motion.div>

          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.7, delay: 0.5 }}
            className="mt-8 text-xs uppercase tracking-[0.2em] text-[#5C6275]"
          >
            Trusted by founders · Built by engineers from
            <span className="ml-2 text-[#8B91A1]">Zupee</span>
            <span className="mx-2">·</span>
            <span className="text-[#8B91A1]">Amazon</span>
          </motion.p>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 30, scale: 0.96 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.9, delay: 0.4, ease: [0.21, 0.47, 0.32, 0.98] }}
          className="relative mx-auto mt-20 max-w-5xl"
        >
          <div className="glow-border relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-b from-white/[0.04] to-transparent p-1 shadow-2xl">
            <div className="rounded-xl bg-[#0A0D17] p-6 md:p-10">
              <div className="grid gap-6 md:grid-cols-3">
                <div className="animate-float-slow">
                  <FloatingCard
                    label="Payment routing"
                    metric="+25%"
                    sublabel="Transaction success"
                    bars
                  />
                </div>
                <div className="animate-float">
                  <FloatingCard
                    label="API latency"
                    metric="60% ↓"
                    sublabel="14 calls → 1"
                    pin
                  />
                </div>
                <div className="animate-float-medium">
                  <FloatingCard
                    label="Daily payouts"
                    metric="100K+"
                    sublabel="Async via SQS"
                    trend
                  />
                </div>
              </div>
            </div>
          </div>
          <div
            aria-hidden
            className="pointer-events-none absolute -inset-x-20 -bottom-10 h-40 bg-gradient-to-t from-[#05070D] via-[#05070D]/60 to-transparent"
          />
        </motion.div>
      </Container>
    </section>
  );
}

function FloatingCard({
  label,
  metric,
  sublabel,
  bars,
  pin,
  trend,
}: {
  label: string;
  metric: string;
  sublabel: string;
  bars?: boolean;
  pin?: boolean;
  trend?: boolean;
}) {
  return (
    <div className="relative overflow-hidden rounded-xl border border-white/10 bg-[#0D1120] p-5">
      <div
        aria-hidden
        className="pointer-events-none absolute -bottom-8 left-1/2 h-32 w-32 -translate-x-1/2 rounded-full bg-[#4F46E5]/20 blur-3xl animate-pulse-glow"
      />
      <div className="relative">
        <p className="font-mono text-xs italic text-[#8B91A1]">{label}</p>
        <p className="mt-3 text-3xl font-semibold tracking-tight text-white">
          {metric}
        </p>
        <p className="mt-1 text-xs text-[#5C6275]">{sublabel}</p>

        {bars && (
          <div className="mt-5 flex h-14 items-end gap-1.5">
            {[40, 24, 56, 32, 68, 48, 80].map((h, i) => (
              <motion.div
                key={i}
                initial={{ height: 0 }}
                animate={{ height: `${h}%` }}
                transition={{
                  duration: 1.4,
                  delay: 0.6 + i * 0.08,
                  ease: [0.21, 0.47, 0.32, 0.98],
                  repeat: Infinity,
                  repeatType: "reverse",
                  repeatDelay: 3,
                }}
                className="flex-1 rounded-sm bg-gradient-to-t from-[#4F46E5]/80 to-[#4F46E5]/30"
              />
            ))}
          </div>
        )}
        {pin && (
          <div className="mt-5 grid grid-cols-4 gap-1.5">
            {[4, 7, 4, 9].map((n, i) => (
              <motion.div
                key={i}
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{
                  duration: 0.4,
                  delay: 0.8 + i * 0.1,
                  repeat: Infinity,
                  repeatType: "reverse",
                  repeatDelay: 4,
                }}
                className="flex h-9 items-center justify-center rounded-md border border-white/10 bg-white/5 font-mono text-sm font-semibold text-white"
              >
                {n}
              </motion.div>
            ))}
          </div>
        )}
        {trend && (
          <svg
            viewBox="0 0 100 40"
            className="mt-5 h-14 w-full"
            preserveAspectRatio="none"
          >
            <defs>
              <linearGradient id="t-grad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#4F46E5" stopOpacity="0.4" />
                <stop offset="100%" stopColor="#4F46E5" stopOpacity="0" />
              </linearGradient>
            </defs>
            <path
              d="M0,30 Q15,20 25,22 T50,15 T75,8 T100,5 L100,40 L0,40 Z"
              fill="url(#t-grad)"
            />
            <motion.path
              d="M0,30 Q15,20 25,22 T50,15 T75,8 T100,5"
              stroke="#818cf8"
              strokeWidth="1.5"
              fill="none"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              transition={{
                duration: 2.2,
                delay: 0.7,
                ease: [0.21, 0.47, 0.32, 0.98],
                repeat: Infinity,
                repeatType: "reverse",
                repeatDelay: 2.5,
              }}
            />
          </svg>
        )}
      </div>
    </div>
  );
}
