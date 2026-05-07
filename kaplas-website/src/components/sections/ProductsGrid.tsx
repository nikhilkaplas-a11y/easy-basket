"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { ArrowUpRight } from "lucide-react";
import { Container } from "@/components/ui/Container";
import { SectionHeader } from "@/components/ui/SectionHeader";
import { Pill } from "@/components/ui/Pill";
import { products } from "@/lib/data";

export function ProductsGrid() {
  return (
    <section className="relative py-28 md:py-36">
      <Container>
        <SectionHeader
          eyebrow="Our products"
          title={
            <>
              We don&apos;t just build for clients.
              <br />
              <span className="text-gradient-primary italic font-display">
                We build for ourselves.
              </span>
            </>
          }
          subtitle="A studio that ships its own products eats its own dogfood. Here's what we're shipping right now."
        />

        <div className="mt-20 grid gap-5 lg:grid-cols-3">
          {products.map((product, i) => {
            const variant =
              product.status === "Live"
                ? "live"
                : product.status === "Beta"
                ? "beta"
                : "soon";
            return (
              <motion.div
                key={product.slug}
                initial={{ opacity: 0, y: 24 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-80px" }}
                transition={{
                  duration: 0.6,
                  delay: i * 0.1,
                  ease: [0.21, 0.47, 0.32, 0.98],
                }}
              >
                <Link
                  href={
                    product.slug === "easy-basket"
                      ? "/projects/easy-basket"
                      : "/projects"
                  }
                  className="group relative flex h-full flex-col overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-white/[0.05] to-white/[0.01] p-7 transition-all duration-500 hover:border-[#4F46E5]/30"
                >
                  <div
                    aria-hidden
                    className="pointer-events-none absolute -right-20 -top-20 h-48 w-48 rounded-full bg-[#4F46E5]/0 blur-3xl transition-all duration-700 group-hover:bg-[#4F46E5]/40"
                  />

                  <div className="relative flex flex-1 flex-col">
                    <div className="flex items-start justify-between">
                      <Pill variant={variant}>{product.status}</Pill>
                      <ArrowUpRight className="h-5 w-5 text-[#5C6275] transition-all duration-500 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 group-hover:text-white" />
                    </div>

                    <h3 className="mt-8 text-2xl font-semibold tracking-tight text-white">
                      {product.name}
                    </h3>
                    <p className="mt-2 text-sm font-medium text-[#A5B4FC]">
                      {product.tagline}
                    </p>
                    <p className="mt-4 flex-1 text-sm leading-relaxed text-[#8B91A1]">
                      {product.description}
                    </p>

                    <div className="mt-6 flex flex-wrap gap-1.5 border-t border-white/5 pt-5">
                      {product.tags.map((tag) => (
                        <span
                          key={tag}
                          className="rounded-md border border-white/10 bg-white/[0.03] px-2 py-0.5 text-[10px] font-medium tracking-wide text-[#8B91A1]"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                </Link>
              </motion.div>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
