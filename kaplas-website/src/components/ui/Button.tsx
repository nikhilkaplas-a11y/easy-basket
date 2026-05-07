import Link from "next/link";
import { cn } from "@/lib/utils";
import { ArrowRight } from "lucide-react";

type Variant = "primary" | "secondary" | "ghost";
type Size = "sm" | "md" | "lg";

const base =
  "group relative inline-flex items-center justify-center gap-2 font-medium transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap";

const variants: Record<Variant, string> = {
  primary:
    "bg-[#4F46E5] text-white hover:bg-[#4338CA] shadow-[0_0_0_0_rgba(79,70,229,0.5)] hover:shadow-[0_0_30px_-5px_rgba(79,70,229,0.7)] border border-[#6366F1]/40",
  secondary:
    "bg-white/5 text-white hover:bg-white/10 border border-white/10 hover:border-white/20 backdrop-blur-sm",
  ghost:
    "text-[#E8EAF0] hover:text-white hover:bg-white/5 border border-transparent",
};

const sizes: Record<Size, string> = {
  sm: "h-9 px-4 text-sm rounded-lg",
  md: "h-11 px-5 text-sm rounded-xl",
  lg: "h-13 px-7 text-base rounded-xl",
};

type ButtonProps = {
  variant?: Variant;
  size?: Size;
  href?: string;
  external?: boolean;
  withArrow?: boolean;
  className?: string;
  children: React.ReactNode;
} & React.ButtonHTMLAttributes<HTMLButtonElement>;

export function Button({
  variant = "primary",
  size = "md",
  href,
  external,
  withArrow,
  className,
  children,
  ...props
}: ButtonProps) {
  const classes = cn(base, variants[variant], sizes[size], className);

  const content = (
    <>
      <span className="relative z-10 flex items-center gap-2">
        {children}
        {withArrow && (
          <ArrowRight className="h-4 w-4 transition-transform duration-300 group-hover:translate-x-0.5" />
        )}
      </span>
    </>
  );

  if (href) {
    if (external) {
      return (
        <a
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          className={classes}
        >
          {content}
        </a>
      );
    }
    return (
      <Link href={href} className={classes}>
        {content}
      </Link>
    );
  }

  return (
    <button className={classes} {...props}>
      {content}
    </button>
  );
}
