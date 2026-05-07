import { cn } from "@/lib/utils";

export function Pill({
  children,
  className,
  variant = "default",
}: {
  children: React.ReactNode;
  className?: string;
  variant?: "default" | "primary" | "live" | "beta" | "soon";
}) {
  const variants = {
    default: "bg-white/5 border-white/10 text-[#E8EAF0]",
    primary:
      "bg-[#4F46E5]/10 border-[#4F46E5]/30 text-[#A5B4FC]",
    live: "bg-emerald-500/10 border-emerald-500/30 text-emerald-300",
    beta: "bg-amber-500/10 border-amber-500/30 text-amber-300",
    soon: "bg-cyan-500/10 border-cyan-500/30 text-cyan-300",
  };

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-medium tracking-wide backdrop-blur-sm",
        variants[variant],
        className
      )}
    >
      {variant === "live" && (
        <span className="relative flex h-1.5 w-1.5">
          <span className="absolute inset-0 animate-ping rounded-full bg-emerald-400 opacity-75" />
          <span className="relative h-1.5 w-1.5 rounded-full bg-emerald-400" />
        </span>
      )}
      {children}
    </span>
  );
}
