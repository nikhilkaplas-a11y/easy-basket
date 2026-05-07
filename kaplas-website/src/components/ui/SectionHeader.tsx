"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

export function SectionHeader({
  eyebrow,
  title,
  subtitle,
  align = "center",
  className,
}: {
  eyebrow?: string;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  align?: "center" | "left";
  className?: string;
}) {
  return (
    <div
      className={cn(
        "flex flex-col gap-4",
        align === "center" ? "items-center text-center" : "items-start text-left",
        className
      )}
    >
      {eyebrow && (
        <motion.span
          initial={{ opacity: 0, y: 8 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-50px" }}
          transition={{ duration: 0.5 }}
          className="inline-flex items-center gap-2 rounded-full border border-[#4F46E5]/30 bg-[#4F46E5]/10 px-3 py-1 text-xs font-medium uppercase tracking-[0.18em] text-[#A5B4FC]"
        >
          <span className="h-1 w-1 rounded-full bg-[#A5B4FC]" />
          {eyebrow}
        </motion.span>
      )}
      <motion.h2
        initial={{ opacity: 0, y: 12 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-50px" }}
        transition={{ duration: 0.6, delay: 0.05 }}
        className={cn(
          "text-balance text-4xl font-semibold tracking-tight text-gradient md:text-5xl lg:text-[3.5rem]",
          align === "center" && "max-w-3xl"
        )}
      >
        {title}
      </motion.h2>
      {subtitle && (
        <motion.p
          initial={{ opacity: 0, y: 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-50px" }}
          transition={{ duration: 0.6, delay: 0.1 }}
          className={cn(
            "text-balance text-lg leading-relaxed text-[#8B91A1]",
            align === "center" ? "max-w-2xl" : "max-w-2xl"
          )}
        >
          {subtitle}
        </motion.p>
      )}
    </div>
  );
}
