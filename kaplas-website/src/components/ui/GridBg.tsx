import { cn } from "@/lib/utils";

export function GridBg({
  className,
  variant = "fade",
}: {
  className?: string;
  variant?: "fade" | "full";
}) {
  return (
    <div
      aria-hidden
      className={cn(
        "pointer-events-none absolute inset-0",
        variant === "fade" ? "grid-bg" : "grid-bg-full",
        className
      )}
    />
  );
}
