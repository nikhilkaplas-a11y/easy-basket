import { cn } from "@/lib/utils";

export function Container({
  children,
  className,
  size = "default",
}: {
  children: React.ReactNode;
  className?: string;
  size?: "default" | "narrow" | "wide";
}) {
  const sizes = {
    narrow: "max-w-4xl",
    default: "max-w-6xl",
    wide: "max-w-7xl",
  };
  return (
    <div className={cn("mx-auto w-full px-6 md:px-8", sizes[size], className)}>
      {children}
    </div>
  );
}
