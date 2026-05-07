import type { Metadata } from "next";
import { Mail, MapPin, Phone, Clock } from "lucide-react";
import { PageHero } from "@/components/sections/PageHero";
import { Container } from "@/components/ui/Container";
import { Reveal } from "@/components/ui/Reveal";
import { ContactForm } from "@/components/sections/ContactForm";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Contact",
  description:
    "Start a project, apply for an internship, or just say hello. We respond within 24 hours.",
};

const contactInfo = [
  {
    icon: Mail,
    label: "Email",
    value: site.email,
    href: `mailto:${site.email}`,
  },
  {
    icon: Phone,
    label: "Phone",
    value: site.phone,
    href: `tel:${site.phone.replace(/\s/g, "")}`,
  },
  {
    icon: MapPin,
    label: "Location",
    value: site.location,
  },
  {
    icon: Clock,
    label: "Response time",
    value: "Within 24 hours",
  },
];

export default function ContactPage() {
  return (
    <>
      <PageHero
        eyebrow="Get in touch"
        title="Let's build something"
        highlight="worth shipping."
        subtitle="Drop a line about what you're working on. Whether it's a fresh idea, an existing system that needs care, or you're looking to join a training cohort — we'd love to hear from you."
      />

      <section className="relative pb-28">
        <Container>
          <div className="mx-auto grid max-w-6xl gap-10 lg:grid-cols-12">
            <Reveal className="lg:col-span-7">
              <ContactForm />
            </Reveal>

            <div className="space-y-5 lg:col-span-5">
              <Reveal delay={0.1}>
                <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-7">
                  <h3 className="text-lg font-semibold text-white">Direct contact</h3>
                  <ul className="mt-5 space-y-4">
                    {contactInfo.map((item) => {
                      const Icon = item.icon;
                      const Content = (
                        <>
                          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                            <Icon className="h-4 w-4" />
                          </div>
                          <div className="min-w-0 flex-1">
                            <p className="text-xs font-medium uppercase tracking-wider text-[#5C6275]">
                              {item.label}
                            </p>
                            <p className="mt-0.5 truncate text-sm font-medium text-white">
                              {item.value}
                            </p>
                          </div>
                        </>
                      );
                      return (
                        <li key={item.label}>
                          {item.href ? (
                            <a
                              href={item.href}
                              className="flex items-center gap-3 transition-opacity hover:opacity-80"
                            >
                              {Content}
                            </a>
                          ) : (
                            <div className="flex items-center gap-3">{Content}</div>
                          )}
                        </li>
                      );
                    })}
                  </ul>
                </div>
              </Reveal>

              <Reveal delay={0.15}>
                <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-[#0F1322] to-[#0A0D17] p-7">
                  <h3 className="text-lg font-semibold text-white">
                    What happens next
                  </h3>
                  <ol className="mt-5 space-y-4">
                    {[
                      {
                        n: "1",
                        title: "We read your note",
                        body: "Within 24 hours — usually same day.",
                      },
                      {
                        n: "2",
                        title: "Quick discovery call",
                        body: "30-minute zoom to understand the goal and scope.",
                      },
                      {
                        n: "3",
                        title: "Written proposal",
                        body: "Scope, timeline, and fixed price — no fluff.",
                      },
                    ].map((s) => (
                      <li key={s.n} className="flex items-start gap-3">
                        <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full border border-[#4F46E5]/30 bg-[#4F46E5]/10 font-mono text-xs font-bold text-[#A5B4FC]">
                          {s.n}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-white">{s.title}</p>
                          <p className="text-xs text-[#8B91A1]">{s.body}</p>
                        </div>
                      </li>
                    ))}
                  </ol>
                </div>
              </Reveal>
            </div>
          </div>
        </Container>
      </section>
    </>
  );
}
