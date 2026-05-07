import { Hero } from "@/components/sections/Hero";
import { StatsBand } from "@/components/sections/StatsBand";
import { TechMarquee } from "@/components/sections/TechMarquee";
import { ServicesPreview } from "@/components/sections/ServicesPreview";
import { FeaturedProject } from "@/components/sections/FeaturedProject";
import { ProductsGrid } from "@/components/sections/ProductsGrid";
import { TrainingPreview } from "@/components/sections/TrainingPreview";
import { WhyKaplas } from "@/components/sections/WhyKaplas";
import { CTASection } from "@/components/sections/CTASection";

export default function Home() {
  return (
    <>
      <Hero />
      <StatsBand />
      <TechMarquee />
      <ServicesPreview />
      <FeaturedProject />
      <ProductsGrid />
      <TrainingPreview />
      <WhyKaplas />
      <CTASection />
    </>
  );
}
