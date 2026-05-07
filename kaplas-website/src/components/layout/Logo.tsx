import Link from "next/link";
import Image from "next/image";

export function Logo({ size = 32 }: { size?: number }) {
  return (
    <Link
      href="/"
      className="group flex items-center gap-2.5 transition-opacity hover:opacity-90"
      aria-label="Kaplas Technology"
    >
      <Image
        src="/logo.png"
        alt="Kaplas Technology"
        width={size}
        height={size}
        priority
        className="rounded-md"
      />
      <span className="hidden flex-col leading-none sm:flex">
        <span className="text-sm font-bold tracking-tight text-white">KAPLAS</span>
        <span className="text-[10px] font-medium tracking-[0.2em] text-[#8B91A1]">
          TECHNOLOGY
        </span>
      </span>
    </Link>
  );
}
