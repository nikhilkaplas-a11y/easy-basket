import type { Metadata } from "next";
import { Calendar, Users, Award, MapPin } from "lucide-react";
import { PageHero } from "@/components/sections/PageHero";
import { Container } from "@/components/ui/Container";
import { Reveal } from "@/components/ui/Reveal";
import { Pill } from "@/components/ui/Pill";
import { Button } from "@/components/ui/Button";
import { CTASection } from "@/components/sections/CTASection";
import { trainingTracks, trainingHighlights } from "@/lib/data";

export const metadata: Metadata = {
  title: "Internships & Training",
  description:
    "Hands-on engineering training from people who've shipped at Amazon, Zupee, and major FinTech platforms. DSA, backend, full-stack, and system design tracks.",
};

const howItWorks = [
  {
    icon: Calendar,
    title: "Structured curriculum",
    body: "Every track has a week-by-week plan with assignments, projects, and live reviews. No 'just watch the video and figure it out.'",
  },
  {
    icon: Users,
    title: "1:1 mentorship",
    body: "Direct mentor access — code reviews, doubt-clearing, career guidance. Engineers from Zupee, Amazon, and high-scale FinTech.",
  },
  {
    icon: Award,
    title: "Real production work",
    body: "Capstone projects deployed to production. Build features for Easy Basket and Sandhal Clinic — with real users at the other end.",
  },
  {
    icon: MapPin,
    title: "Placement support",
    body: "Resume review, mock interviews, and direct referrals through our network of partner companies. We don't disappear after the course.",
  },
];

export default function InternshipsPage() {
  return (
    <>
      <PageHero
        eyebrow="Internships & Training"
        title="Learn engineering from"
        highlight="engineers."
        subtitle="No tutorials, no theory-only courses. Just structured, hands-on programs taught by people who've shipped at scale — with real projects and real placement support."
      />

      <section className="relative py-12 md:py-20">
        <Container>
          <Reveal>
            <div className="grid grid-cols-2 gap-px overflow-hidden rounded-2xl border border-white/10 bg-white/5 md:grid-cols-4">
              {trainingHighlights.map((h) => (
                <div
                  key={h.label}
                  className="bg-[#0A0D17] p-6 text-center md:p-8"
                >
                  <p className="text-gradient-primary text-3xl font-bold tracking-tight md:text-4xl">
                    {h.value}
                  </p>
                  <p className="mt-3 text-xs leading-relaxed text-[#8B91A1] md:text-sm">
                    {h.label}
                  </p>
                </div>
              ))}
            </div>
          </Reveal>
        </Container>
      </section>

      <section className="relative py-12 md:py-20">
        <Container>
          <div className="mx-auto max-w-3xl text-center">
            <h2 className="text-balance text-4xl font-semibold tracking-tight md:text-5xl">
              <span className="text-gradient">Pick your </span>
              <span className="text-gradient-primary italic font-display">track.</span>
            </h2>
            <p className="mt-5 text-lg text-[#8B91A1]">
              Four specialized programs — each designed for a specific career stage.
            </p>
          </div>

          <div className="mt-16 grid gap-5 lg:grid-cols-2">
            {trainingTracks.map((track, i) => {
              const Icon = track.icon;
              return (
                <Reveal key={track.slug} delay={i * 0.06}>
                  <div className="group relative h-full overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-8 transition-all duration-500 hover:border-[#4F46E5]/30">
                    <div
                      aria-hidden
                      className="pointer-events-none absolute -right-20 -top-20 h-48 w-48 rounded-full bg-[#4F46E5]/0 blur-3xl transition-all duration-700 group-hover:bg-[#4F46E5]/30"
                    />
                    <div className="relative">
                      <div className="flex items-start justify-between">
                        <div className="flex h-12 w-12 items-center justify-center rounded-xl border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                          <Icon className="h-5 w-5" />
                        </div>
                        <Pill variant="primary">{track.duration}</Pill>
                      </div>

                      <h3 className="mt-6 text-2xl font-semibold tracking-tight text-white">
                        {track.title}
                      </h3>
                      <p className="mt-3 text-[15px] leading-relaxed text-[#8B91A1]">
                        {track.description}
                      </p>

                      <div className="mt-5 grid grid-cols-2 gap-3 border-y border-white/5 py-4 text-xs">
                        <div>
                          <p className="text-[#5C6275]">Format</p>
                          <p className="mt-0.5 font-medium text-white">{track.format}</p>
                        </div>
                        <div>
                          <p className="text-[#5C6275]">For</p>
                          <p className="mt-0.5 font-medium text-white">{track.audience}</p>
                        </div>
                      </div>

                      <div className="mt-5">
                        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#5C6275]">
                          What you&apos;ll learn
                        </p>
                        <ul className="mt-3 grid gap-1.5 sm:grid-cols-2">
                          {track.modules.slice(0, 6).map((m) => (
                            <li
                              key={m}
                              className="flex items-start gap-2 text-xs text-[#E8EAF0]"
                            >
                              <span className="mt-1 h-1 w-1 shrink-0 rounded-full bg-[#A5B4FC]" />
                              <span>{m}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </Container>
      </section>

      <section className="relative py-20">
        <Container>
          <div className="mx-auto max-w-3xl text-center">
            <h2 className="text-balance text-4xl font-semibold tracking-tight md:text-5xl">
              <span className="text-gradient">How it </span>
              <span className="text-gradient-primary italic font-display">works.</span>
            </h2>
          </div>

          <div className="mx-auto mt-14 grid max-w-5xl gap-5 md:grid-cols-2">
            {howItWorks.map((item, i) => {
              const Icon = item.icon;
              return (
                <Reveal key={item.title} delay={i * 0.06}>
                  <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-7">
                    <div className="flex h-11 w-11 items-center justify-center rounded-xl border border-[#4F46E5]/30 bg-[#4F46E5]/10 text-[#A5B4FC]">
                      <Icon className="h-5 w-5" />
                    </div>
                    <h3 className="mt-5 text-xl font-semibold tracking-tight text-white">
                      {item.title}
                    </h3>
                    <p className="mt-3 text-[15px] leading-relaxed text-[#8B91A1]">
                      {item.body}
                    </p>
                  </div>
                </Reveal>
              );
            })}
          </div>
        </Container>
      </section>

      <section className="relative py-20">
        <Container size="narrow">
          <Reveal>
            <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-[#0F1322] via-[#0A0D17] to-[#0F1322] p-10 text-center md:p-16">
              <div
                aria-hidden
                className="pointer-events-none absolute left-1/2 top-0 h-64 w-96 -translate-x-1/2 -translate-y-1/2 rounded-full bg-[#4F46E5]/30 blur-[100px]"
              />
              <div className="relative">
                <h2 className="text-balance text-3xl font-semibold tracking-tight md:text-4xl">
                  <span className="text-gradient">Next cohort starts soon.</span>{" "}
                  <span className="text-gradient-primary italic font-display">
                    Apply now.
                  </span>
                </h2>
                <p className="mx-auto mt-5 max-w-xl text-lg text-[#8B91A1]">
                  Limited seats per cohort to maintain mentorship quality. Reach out and
                  we&apos;ll get on a call to figure out the best track for you.
                </p>
                <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
                  <Button href="/contact" size="lg" withArrow>
                    Apply for a track
                  </Button>
                  <Button href="/contact" variant="secondary" size="lg">
                    Schedule a call
                  </Button>
                </div>
              </div>
            </div>
          </Reveal>
        </Container>
      </section>

      <CTASection />
    </>
  );
}
