"use client";

import { useEffect, useRef } from "react";

export function Particles({
  count = 40,
  className,
}: {
  count?: number;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.innerHTML = "";
    for (let i = 0; i < count; i++) {
      const dot = document.createElement("span");
      const size = Math.random() * 2 + 1;
      const left = Math.random() * 100;
      const top = Math.random() * 100;
      const delay = Math.random() * 8;
      const dur = 6 + Math.random() * 8;
      dot.style.cssText = `
        position:absolute;
        left:${left}%;
        top:${top}%;
        width:${size}px;
        height:${size}px;
        background:rgba(255,255,255,${Math.random() * 0.4 + 0.2});
        border-radius:9999px;
        animation: float ${dur}s ease-in-out ${delay}s infinite;
      `;
      el.appendChild(dot);
    }
  }, [count]);

  return (
    <div
      ref={ref}
      aria-hidden
      className={`pointer-events-none absolute inset-0 overflow-hidden ${className || ""}`}
    />
  );
}
