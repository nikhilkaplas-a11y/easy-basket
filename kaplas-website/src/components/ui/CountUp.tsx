"use client";

import { useEffect, useRef, useState } from "react";
import { animate, useInView } from "framer-motion";

type Parsed = {
  prefix: string;
  number: number;
  decimals: number;
  suffix: string;
};

function parse(value: string): Parsed {
  const match = value.match(/^(\D*)(\d+(?:\.\d+)?)(.*)$/);
  if (!match) {
    return { prefix: value, number: 0, decimals: 0, suffix: "" };
  }
  const [, prefix = "", numStr, suffix = ""] = match;
  const decimals = numStr.includes(".") ? numStr.split(".")[1].length : 0;
  return { prefix, number: parseFloat(numStr), decimals, suffix };
}

export function CountUp({
  value,
  duration = 1.6,
  className,
}: {
  value: string;
  duration?: number;
  className?: string;
}) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "-20%" });
  const [display, setDisplay] = useState<string>("");
  const parsed = useRef<Parsed>(parse(value));

  useEffect(() => {
    parsed.current = parse(value);
    setDisplay(`${parsed.current.prefix}0${parsed.current.suffix}`);
  }, [value]);

  useEffect(() => {
    if (!inView) return;
    const { prefix, number, decimals, suffix } = parsed.current;
    const controls = animate(0, number, {
      duration,
      ease: [0.21, 0.47, 0.32, 0.98],
      onUpdate(v) {
        const n =
          decimals > 0 ? v.toFixed(decimals) : Math.round(v).toLocaleString();
        setDisplay(`${prefix}${n}${suffix}`);
      },
    });
    return () => controls.stop();
  }, [inView, duration]);

  return (
    <span ref={ref} className={className}>
      {display || value}
    </span>
  );
}
