import { cn } from "@/lib/utils";

export function Card({
  children,
  className,
  hover = true,
  glow = false,
}: {
  children: React.ReactNode;
  className?: string;
  hover?: boolean;
  glow?: boolean;
}) {
  return (
    <div
      className={cn(
        "group relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-b from-white/[0.04] to-white/[0.01] backdrop-blur-sm transition-all duration-500",
        hover && "hover:border-white/20 hover:from-white/[0.06]",
        glow && "hover:shadow-[0_0_40px_-10px_rgba(79,70,229,0.4)]",
        className
      )}
    >
      {glow && (
        <div
          aria-hidden
          className="pointer-events-none absolute -top-20 left-1/2 h-40 w-40 -translate-x-1/2 rounded-full bg-[#4F46E5]/0 blur-3xl transition-all duration-500 group-hover:bg-[#4F46E5]/30"
        />
      )}
      <div className="relative">{children}</div>
    </div>
  );
}
