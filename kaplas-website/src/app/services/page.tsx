import type { Metadata } from "next";
import { Check } from "lucide-react";
import { PageHero } from "@/components/sections/PageHero";
import { Container } from "@/components/ui/Container";
import { Reveal } from "@/components/ui/Reveal";
import { CTASection } from "@/components/sections/CTASection";
import { services, techStack } from "@/lib/data";

export const metadata: Metadata = {
  title: "Services",
  description:
    "Backend engineering, mobile development, web development, and performance optimization — for startups that need production-grade execution.",
};

const process = [
  {
    step: "01",
    title: "Discovery & scoping",
    body: "Two-week deep dive: we map your technical landscape, business goals, and constraints. You leave with a written architecture proposal and a fixed-price scope.",
  },
  {
    step: "02",
    title: "Design & prototype",
    body: "Interactive prototypes, API contracts, and database schemas — reviewed with your team before a single line of production code is written.",
  },
  {
    step: "03",
    title: "Build & ship",
    body: "Two-week sprints with daily standups, weekly demos, and continuous deployment. You see progress in your own staging environment, not a slide deck.",
  },
  {
    step: "04",
    title: "Scale & optimize",
    body: "Once live, we monitor, optimize, and iterate. Observability dashboards, performance budgets, and on-call support — included.",
  },
];

export default function ServicesPage() {
  return (
    <>
      <PageHero
        eyebrow="Services"
        title="Engineering services."
        highlight="Built to ship."
        subtitle="From a v1 prototype to scaling past your first million users — pick a discipline below or combine them. We work as a focused team, embedded with yours."
      />

      <section className="relative py-12 md:py-20">
        <Container>
          <div className="space-y-12">
            {services.map((service, i) => {
              const Icon = service.icon;
              return (
                <Reveal
                  key={service.slug}
                  delay={i * 0.04}
                  id={service.slug}
                  className="scroll-mt-24"
                >
                  <div className="grid gap-10 rounded-3xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-8 md:grid-cols-12 md:p-12">
                    <div className="md:col-span-5">
                      <div className="flex h-14 w-14 items-center justify-center rounded-xl border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                        <Icon className="h-6 w-6" />
                      </div>
                      <h2 className="mt-6 text-3xl font-semibold tracking-tight text-white md:text-4xl">
                        {service.title}
                      </h2>
                      <p className="mt-4 text-[15px] leading-relaxed text-[#8B91A1]">
                        {service.description}
                      </p>
                      <div className="mt-6 flex flex-wrap gap-2">
                        {service.stack.map((tech) => (
                          <span
                            key={tech}
                            className="rounded-full border border-white/10 bg-white/[0.03] px-2.5 py-1 text-[11px] font-medium text-[#A5B4FC]"
                          >
                            {tech}
                          </span>
                        ))}
                      </div>
                    </div>
                    <div className="md:col-span-7">
                      <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#5C6275]">
                        What we deliver
                      </p>
                      <ul className="mt-5 space-y-3">
                        {service.highlights.map((point) => (
                          <li
                            key={point}
                            className="flex items-start gap-3 rounded-lg border border-white/[0.06] bg-white/[0.02] px-4 py-3"
                          >
                            <Check className="mt-0.5 h-4 w-4 shrink-0 text-[#A5B4FC]" />
                            <span className="text-sm text-[#E8EAF0]">{point}</span>
                          </li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </Container>
      </section>

      <section className="relative py-28">
        <Container>
          <div className="mx-auto max-w-3xl text-center">
            <span className="inline-flex items-center gap-2 rounded-full border border-[#4F46E5]/30 bg-[#4F46E5]/10 px-3 py-1 text-xs font-medium uppercase tracking-[0.18em] text-[#A5B4FC]">
              <span className="h-1 w-1 rounded-full bg-[#A5B4FC]" />
              How we work
            </span>
            <h2 className="mt-5 text-balance text-4xl font-semibold tracking-tight md:text-5xl">
              <span className="text-gradient">A four-phase engagement.</span>{" "}
              <span className="text-gradient-primary italic font-display">No surprises.</span>
            </h2>
            <p className="mt-6 text-lg text-[#8B91A1]">
              Fixed scope, fixed timeline, transparent communication. Every project follows
              the same proven workflow.
            </p>
          </div>

          <div className="mx-auto mt-20 grid max-w-5xl gap-5 md:grid-cols-2">
            {process.map((p, i) => (
              <Reveal key={p.step} delay={i * 0.06}>
                <div className="relative h-full overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-7">
                  <p className="font-mono text-xs text-[#5C6275]">PHASE {p.step}</p>
                  <h3 className="mt-2 text-xl font-semibold tracking-tight text-white">
                    {p.title}
                  </h3>
                  <p className="mt-4 text-sm leading-relaxed text-[#8B91A1]">
                    {p.body}
                  </p>
                </div>
              </Reveal>
            ))}
          </div>
        </Container>
      </section>

      <section className="relative py-20">
        <Container>
          <div className="mx-auto max-w-3xl text-center">
            <h2 className="text-balance text-4xl font-semibold tracking-tight md:text-5xl">
              <span className="text-gradient">Our </span>
              <span className="text-gradient-primary italic font-display">tech stack.</span>
            </h2>
            <p className="mt-6 text-lg text-[#8B91A1]">
              Modern, battle-tested, and deeply understood — not chosen by hype.
            </p>
          </div>

          <div className="mx-auto mt-16 grid max-w-5xl gap-4 md:grid-cols-2">
            {techStack.map((group) => {
              const Icon = group.icon;
              return (
                <Reveal key={group.category}>
                  <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-6">
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                        <Icon className="h-4 w-4" />
                      </div>
                      <h3 className="text-base font-semibold text-white">
                        {group.category}
                      </h3>
                    </div>
                    <div className="mt-5 flex flex-wrap gap-2">
                      {group.items.map((item) => (
                        <span
                          key={item}
                          className="rounded-full border border-white/10 bg-white/[0.02] px-3 py-1 text-xs text-[#E8EAF0]"
                        >
                          {item}
                        </span>
                      ))}
                    </div>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </Container>
      </section>

      <CTASection />
    </>
  );
}
