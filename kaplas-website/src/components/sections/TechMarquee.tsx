"use client";

import { motion } from "framer-motion";
import { Container } from "@/components/ui/Container";

const ROW_1 = [
  "Next.js",
  "React",
  "TypeScript",
  "Node.js",
  "Python",
  "Flutter",
  "PostgreSQL",
  "Redis",
  "AWS",
  "Vercel",
  "Tailwind",
  "Framer Motion",
  "Razorpay",
  "Twilio",
  "Stripe",
];

const ROW_2 = [
  "Microservices",
  "Distributed Systems",
  "Real-time",
  "Payment Routing",
  "Queue Pipelines",
  "GraphQL",
  "tRPC",
  "WebSockets",
  "Edge Caching",
  "CI/CD",
  "Observability",
  "Kubernetes",
  "Docker",
  "Lambda",
  "DynamoDB",
];

function MarqueeRow({
  items,
  reverse,
  className,
}: {
  items: string[];
  reverse?: boolean;
  className?: string;
}) {
  const doubled = [...items, ...items];
  return (
    <div className="pause-on-hover relative overflow-hidden">
      <div
        aria-hidden
        className="pointer-events-none absolute left-0 top-0 z-10 h-full w-32 bg-gradient-to-r from-[#05070D] to-transparent"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute right-0 top-0 z-10 h-full w-32 bg-gradient-to-l from-[#05070D] to-transparent"
      />
      <div
        className={`flex w-max gap-3 ${className} ${
          reverse ? "[animation-direction:reverse]" : ""
        }`}
      >
        {doubled.map((item, i) => (
          <span
            key={`${item}-${i}`}
            className="inline-flex shrink-0 items-center gap-2 rounded-full border border-white/10 bg-white/[0.03] px-5 py-2.5 text-sm font-medium text-[#8B91A1] backdrop-blur-sm transition-colors hover:border-[#4F46E5]/30 hover:bg-[#4F46E5]/10 hover:text-white"
          >
            <span className="h-1.5 w-1.5 rounded-full bg-gradient-to-br from-[#4F46E5] to-[#06B6D4]" />
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}

export function TechMarquee() {
  return (
    <section className="relative overflow-hidden py-20">
      <Container>
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="mb-10 flex flex-col items-center text-center"
        >
          <p className="font-mono text-xs uppercase tracking-[0.22em] text-[#5C6275]">
            // tools, frameworks, and patterns we live in
          </p>
        </motion.div>
      </Container>

      <div className="space-y-4">
        <MarqueeRow items={ROW_1} className="animate-marquee" />
        <MarqueeRow items={ROW_2} reverse className="animate-marquee-slow" />
      </div>
    </section>
  );
}
