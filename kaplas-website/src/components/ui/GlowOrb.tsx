import { cn } from "@/lib/utils";

export function GlowOrb({
  className,
  color = "primary",
  size = "md",
}: {
  className?: string;
  color?: "primary" | "cyan" | "purple";
  size?: "sm" | "md" | "lg" | "xl";
}) {
  const sizes = {
    sm: "h-48 w-48",
    md: "h-72 w-72",
    lg: "h-[500px] w-[500px]",
    xl: "h-[800px] w-[800px]",
  };
  const colors = {
    primary: "bg-[#4F46E5]/30",
    cyan: "bg-[#06B6D4]/25",
    purple: "bg-[#8B5CF6]/25",
  };
  return (
    <div
      aria-hidden
      className={cn(
        "pointer-events-none absolute rounded-full blur-[120px]",
        sizes[size],
        colors[color],
        className
      )}
    />
  );
}
