"use client";

import { motion, type HTMLMotionProps } from "framer-motion";
import { cn } from "@/lib/utils";

type RevealProps = {
  children: React.ReactNode;
  className?: string;
  delay?: number;
  y?: number;
} & Omit<HTMLMotionProps<"div">, "initial" | "animate" | "whileInView">;

export function Reveal({
  children,
  className,
  delay = 0,
  y = 16,
  ...rest
}: RevealProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-60px" }}
      transition={{ duration: 0.6, delay, ease: [0.21, 0.47, 0.32, 0.98] }}
      className={cn(className)}
      {...rest}
    >
      {children}
    </motion.div>
  );
}
