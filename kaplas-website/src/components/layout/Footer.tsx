import Link from "next/link";
import { Mail, MapPin, Phone } from "lucide-react";
import { Logo } from "./Logo";

function LinkedinIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden>
      <path d="M20.45 20.45h-3.55v-5.57c0-1.33-.02-3.04-1.85-3.04-1.86 0-2.14 1.45-2.14 2.95v5.66H9.36V9h3.41v1.56h.05c.48-.9 1.64-1.85 3.37-1.85 3.6 0 4.27 2.37 4.27 5.46v6.28zM5.34 7.43a2.06 2.06 0 1 1 0-4.12 2.06 2.06 0 0 1 0 4.12zM7.12 20.45H3.56V9h3.56v11.45zM22.23 0H1.77C.79 0 0 .77 0 1.72v20.56C0 23.23.79 24 1.77 24h20.46c.98 0 1.77-.77 1.77-1.72V1.72C24 .77 23.21 0 22.23 0z" />
    </svg>
  );
}

function GithubIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden>
      <path d="M12 .3a12 12 0 0 0-3.79 23.4c.6.1.82-.26.82-.58v-2.04c-3.34.72-4.04-1.6-4.04-1.6-.55-1.39-1.34-1.76-1.34-1.76-1.09-.74.08-.73.08-.73 1.21.08 1.85 1.24 1.85 1.24 1.07 1.84 2.81 1.31 3.5 1 .1-.78.42-1.31.76-1.61-2.66-.3-5.47-1.34-5.47-5.96 0-1.32.47-2.4 1.24-3.24-.13-.3-.54-1.53.12-3.18 0 0 1.01-.32 3.31 1.24a11.46 11.46 0 0 1 6.03 0c2.3-1.56 3.31-1.24 3.31-1.24.66 1.65.25 2.88.12 3.18.77.84 1.24 1.92 1.24 3.24 0 4.63-2.81 5.65-5.49 5.95.43.37.82 1.1.82 2.22v3.29c0 .32.22.69.83.58A12 12 0 0 0 12 .3" />
    </svg>
  );
}

function TwitterIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden>
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
  );
}
import { Container } from "@/components/ui/Container";
import { site, nav } from "@/lib/site";

export function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="relative mt-24 border-t border-white/5 bg-gradient-to-b from-transparent to-[#04060B]">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 top-0 mx-auto h-px max-w-3xl bg-gradient-to-r from-transparent via-[#4F46E5]/40 to-transparent"
      />

      <Container className="py-16">
        <div className="grid gap-12 lg:grid-cols-12">
          <div className="lg:col-span-5">
            <Logo size={36} />
            <p className="mt-5 max-w-sm text-sm leading-relaxed text-[#8B91A1]">
              {site.description}
            </p>
            <div className="mt-6 flex items-center gap-3">
              <a
                href={site.social.linkedin}
                aria-label="LinkedIn"
                target="_blank"
                rel="noopener noreferrer"
                className="flex h-10 w-10 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-[#8B91A1] transition-all hover:border-[#4F46E5]/40 hover:bg-[#4F46E5]/10 hover:text-white"
              >
                <LinkedinIcon className="h-4 w-4" />
              </a>
              <a
                href={site.social.github}
                aria-label="GitHub"
                target="_blank"
                rel="noopener noreferrer"
                className="flex h-10 w-10 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-[#8B91A1] transition-all hover:border-[#4F46E5]/40 hover:bg-[#4F46E5]/10 hover:text-white"
              >
                <GithubIcon className="h-4 w-4" />
              </a>
              <a
                href={site.social.twitter}
                aria-label="Twitter / X"
                target="_blank"
                rel="noopener noreferrer"
                className="flex h-10 w-10 items-center justify-center rounded-lg border border-white/10 bg-white/5 text-[#8B91A1] transition-all hover:border-[#4F46E5]/40 hover:bg-[#4F46E5]/10 hover:text-white"
              >
                <TwitterIcon className="h-4 w-4" />
              </a>
            </div>
          </div>

          <div className="lg:col-span-3">
            <h3 className="text-xs font-semibold uppercase tracking-[0.18em] text-white">
              Navigate
            </h3>
            <ul className="mt-5 space-y-3">
              {nav.map((item) => (
                <li key={item.href}>
                  <Link
                    href={item.href}
                    className="text-sm text-[#8B91A1] transition-colors hover:text-white"
                  >
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div className="lg:col-span-4">
            <h3 className="text-xs font-semibold uppercase tracking-[0.18em] text-white">
              Get in touch
            </h3>
            <ul className="mt-5 space-y-3 text-sm text-[#8B91A1]">
              <li className="flex items-center gap-3">
                <Mail className="h-4 w-4 text-[#4F46E5]" />
                <a
                  href={`mailto:${site.email}`}
                  className="transition-colors hover:text-white"
                >
                  {site.email}
                </a>
              </li>
              <li className="flex items-center gap-3">
                <Phone className="h-4 w-4 text-[#4F46E5]" />
                <a
                  href={`tel:${site.phone.replace(/\s/g, "")}`}
                  className="transition-colors hover:text-white"
                >
                  {site.phone}
                </a>
              </li>
              <li className="flex items-center gap-3">
                <MapPin className="h-4 w-4 text-[#4F46E5]" />
                {site.location}
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-14 flex flex-col items-start justify-between gap-4 border-t border-white/5 pt-8 text-xs text-[#5C6275] sm:flex-row sm:items-center">
          <p>© {year} Kaplas Technology. All rights reserved.</p>
          <p className="font-mono">
            Built with care in Gurugram · Next.js · Tailwind · Framer Motion
          </p>
        </div>
      </Container>
    </footer>
  );
}
