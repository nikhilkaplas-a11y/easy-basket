import type { Metadata } from "next";
import Link from "next/link";
import { ArrowUpRight } from "lucide-react";
import { PageHero } from "@/components/sections/PageHero";
import { Container } from "@/components/ui/Container";
import { Pill } from "@/components/ui/Pill";
import { Reveal } from "@/components/ui/Reveal";
import { CTASection } from "@/components/sections/CTASection";
import { products } from "@/lib/data";

export const metadata: Metadata = {
  title: "Projects",
  description:
    "Live products and case studies from Kaplas Technology — Easy Basket, Routing AI, and Sandhal Clinic.",
};

export default function ProjectsPage() {
  return (
    <>
      <PageHero
        eyebrow="Our work"
        title="Products we've shipped."
        highlight="Lessons we've learned."
        subtitle="A selected look at what we've built — for ourselves, and for the clients who let us tell their story."
      />

      <section className="relative py-12 md:py-20">
        <Container>
          <div className="space-y-6">
            {products.map((product, i) => {
              const variant =
                product.status === "Live"
                  ? "live"
                  : product.status === "Beta"
                  ? "beta"
                  : "soon";
              const detailed = product.slug === "easy-basket";
              return (
                <Reveal key={product.slug} delay={i * 0.06}>
                  <Link
                    href={detailed ? `/projects/${product.slug}` : "#"}
                    className="group relative block overflow-hidden rounded-3xl border border-white/10 bg-gradient-to-br from-white/[0.04] to-transparent p-8 transition-all duration-500 hover:border-[#4F46E5]/30 md:p-12"
                  >
                    <div
                      aria-hidden
                      className="pointer-events-none absolute -right-20 -top-20 h-72 w-72 rounded-full bg-[#4F46E5]/0 blur-[100px] transition-all duration-700 group-hover:bg-[#4F46E5]/30"
                    />
                    <div className="relative grid gap-8 md:grid-cols-12">
                      <div className="md:col-span-8">
                        <div className="flex items-center gap-3">
                          <Pill variant={variant}>{product.status}</Pill>
                          <span className="text-xs font-mono text-[#5C6275]">
                            0{i + 1}
                          </span>
                        </div>
                        <h2 className="mt-5 text-3xl font-semibold tracking-tight text-white md:text-4xl lg:text-5xl">
                          {product.name}
                        </h2>
                        <p className="mt-3 text-lg font-medium text-[#A5B4FC]">
                          {product.tagline}
                        </p>
                        <p className="mt-5 max-w-2xl text-[15px] leading-relaxed text-[#8B91A1]">
                          {product.description}
                        </p>
                        <div className="mt-6 flex flex-wrap gap-2">
                          {product.tags.map((tag) => (
                            <span
                              key={tag}
                              className="rounded-full border border-white/10 bg-white/[0.03] px-3 py-1 text-xs font-medium text-[#E8EAF0]"
                            >
                              {tag}
                            </span>
                          ))}
                        </div>
                      </div>
                      <div className="flex md:col-span-4 md:items-end md:justify-end">
                        {detailed ? (
                          <span className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm font-medium text-white transition-all group-hover:border-[#4F46E5]/40 group-hover:bg-[#4F46E5]/10">
                            Read case study
                            <ArrowUpRight className="h-4 w-4 transition-transform group-hover:-translate-y-0.5 group-hover:translate-x-0.5" />
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.02] px-4 py-2 text-sm text-[#5C6275]">
                            Case study coming soon
                          </span>
                        )}
                      </div>
                    </div>
                  </Link>
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
