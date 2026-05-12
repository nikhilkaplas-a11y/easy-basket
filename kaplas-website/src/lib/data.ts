import type { LucideIcon } from "lucide-react";
import {
  Server,
  Smartphone,
  Globe,
  Gauge,
  Database,
  Cloud,
  ShieldCheck,
  Cpu,
} from "lucide-react";

export type Service = {
  slug: string;
  title: string;
  short: string;
  description: string;
  icon: LucideIcon;
  highlights: string[];
  stack: string[];
};

export const services: Service[] = [
  {
    slug: "backend",
    title: "Backend Engineering",
    short: "APIs, microservices, and payment systems built to handle real load.",
    description:
      "We architect distributed backends that survive Black Friday traffic. From payment orchestration to async job pipelines, we build the unsexy infrastructure that keeps products running.",
    icon: Server,
    highlights: [
      "Microservices & event-driven systems",
      "Payment gateway integrations (PhonePe, Razorpay, Cashfree)",
      "Queue-based async pipelines (SQS, Redis)",
      "Database sharding, read-replicas, archival",
    ],
    stack: ["Node.js", "TypeScript", "Python", "AWS", "Redis", "PostgreSQL", "MySQL"],
  },
  {
    slug: "mobile",
    title: "Mobile Development",
    short: "Native-feel cross-platform apps shipped to App Store and Play Store.",
    description:
      "We build mobile apps that feel native, ship fast, and don't crash on edge devices. From hyperlocal delivery apps to clinic booking systems — production-ready Flutter and React Native.",
    icon: Smartphone,
    highlights: [
      "Flutter & React Native for cross-platform reach",
      "Real-time tracking, push notifications, OTP",
      "Offline-first architecture",
      "App Store + Play Store submission & ASO",
    ],
    stack: ["Flutter", "React Native", "Firebase", "Twilio", "FCM"],
  },
  {
    slug: "web",
    title: "Web Development",
    short: "Marketing sites, dashboards, and SaaS platforms with measurable speed.",
    description:
      "Modern web that loads in under a second. SEO-tuned marketing sites, real-time dashboards, and full-stack SaaS platforms — built with Next.js, React, and the best of the modern stack.",
    icon: Globe,
    highlights: [
      "Next.js / React with App Router",
      "Server components, streaming, edge caching",
      "Lighthouse 95+ on every page",
      "Type-safe end-to-end (tRPC, Zod)",
    ],
    stack: ["Next.js", "React", "TypeScript", "Tailwind", "tRPC", "Vercel"],
  },
  {
    slug: "optimization",
    title: "Performance Optimization",
    short: "Audit your stack, kill the bottlenecks, slash your infra bill.",
    description:
      "Slow APIs costing you users? Database queries crawling? We profile, measure, and fix — turning 14 DB calls into 1, dropping P99 latency by 60%, and cutting your AWS bill in half.",
    icon: Gauge,
    highlights: [
      "P99 latency reduction (60%+ typical)",
      "Database query optimization & indexing",
      "Caching strategy (Redis, CDN, edge)",
      "Cost optimization — cut infra spend by 30-50%",
    ],
    stack: ["New Relic", "Datadog", "Redis", "Profilers", "k6"],
  },
];

export type Product = {
  slug: string;
  name: string;
  tagline: string;
  description: string;
  status: "Live" | "In Development" | "Beta";
  tags: string[];
  href?: string;
};

export const products: Product[] = [
  {
    slug: "easy-basket",
    name: "Easy Basket",
    tagline: "Hyperlocal grocery delivery, end-to-end.",
    description:
      "A full-stack grocery delivery platform with customer app, delivery rider app, and merchant dashboard. Real-time order tracking, COD reconciliation, and OTP-based delivery confirmation built in.",
    status: "Live",
    tags: ["Mobile", "Backend", "Real-time", "Payments"],
  },
  {
    slug: "routing-ai",
    name: "Routing AI",
    tagline: "One platform. Every AI model. Pay for what you use.",
    description:
      "A unified gateway for OpenAI, Anthropic, Google, and open-source models. Smart routing picks the best model per query, with consolidated billing and usage analytics.",
    status: "In Development",
    tags: ["AI", "Web", "API Gateway", "SaaS"],
  },
  {
    slug: "sandhal-clinic",
    name: "Sandhal Clinic",
    tagline: "Modern patient booking, built for Indian practices.",
    description:
      "Clinic management system with online appointment booking, patient records, prescription generation, and WhatsApp reminders — designed for the realities of small-to-mid Indian clinics.",
    status: "Beta",
    tags: ["Healthcare", "Web", "Mobile", "Booking"],
  },
];

export type Stat = { value: string; label: string };

export const heroStats: Stat[] = [
  { value: "70%", label: "Faster onboarding" },
  { value: "90%", label: "Payment conversion" },
  { value: "100K+", label: "Daily transactions handled" },
  { value: "60%", label: "Latency reduction" },
];

export type TrainingTrack = {
  slug: string;
  title: string;
  duration: string;
  format: string;
  audience: string;
  description: string;
  modules: string[];
  icon: LucideIcon;
};

export const trainingTracks: TrainingTrack[] = [
  {
    slug: "dsa",
    title: "Data Structures & Algorithms",
    duration: "12 weeks",
    format: "Hybrid (live + recorded)",
    audience: "Engineering students & early-career devs",
    description:
      "From arrays to graph algorithms. Built around real interview problems from FAANG, Zupee, Razorpay, and other top product companies.",
    modules: [
      "Time & Space Complexity",
      "Arrays, Strings, Hashing",
      "Linked Lists, Stacks, Queues",
      "Trees, Tries, Heaps",
      "Graphs, BFS/DFS, Shortest Paths",
      "Dynamic Programming",
      "System Design fundamentals",
    ],
    icon: Cpu,
  },
  {
    slug: "backend",
    title: "Backend Engineering",
    duration: "10 weeks",
    format: "Hybrid",
    audience: "Final-year students & junior backend devs",
    description:
      "Build a production-grade Node.js backend from scratch — with auth, payments, queues, caching, and deployment. Capstone: ship your own API to AWS.",
    modules: [
      "Node.js + TypeScript foundations",
      "REST API design & versioning",
      "PostgreSQL & Redis",
      "Auth: JWT, OAuth, sessions",
      "Async jobs with BullMQ / SQS",
      "Payment gateway integration",
      "AWS deployment & CI/CD",
    ],
    icon: Server,
  },
  {
    slug: "fullstack",
    title: "Full-Stack Web (Next.js)",
    duration: "14 weeks",
    format: "Online (cohort-based)",
    audience: "Self-taught devs & bootcamp graduates",
    description:
      "Become a full-stack engineer who can ship end-to-end. Frontend, backend, database, and deployment — all with the modern Next.js stack.",
    modules: [
      "React fundamentals",
      "Next.js App Router & RSC",
      "Tailwind CSS & component design",
      "Database with Prisma",
      "Authentication (NextAuth)",
      "Payments with Stripe / Razorpay",
      "Capstone project + deployment",
    ],
    icon: Globe,
  },
  {
    slug: "system-design",
    title: "System Design",
    duration: "8 weeks",
    format: "Live online (weekend cohort)",
    audience: "Mid-level engineers prepping for senior interviews",
    description:
      "Design Twitter, design WhatsApp, design Razorpay. Real-world architectures dissected — by an Engineering Manager who's built them.",
    modules: [
      "Scalability & load balancing",
      "Caching layers",
      "Database scaling & sharding",
      "Message queues",
      "Microservices vs Monolith",
      "CAP theorem in practice",
      "Mock interviews with feedback",
    ],
    icon: Database,
  },
];

export const trainingHighlights = [
  { value: "1:1", label: "Mentorship with engineers from Zupee, Amazon" },
  { value: "Live", label: "Real production projects, not toy problems" },
  { value: "100%", label: "Placement assistance & resume review" },
  { value: "Lifetime", label: "Access to recordings & community" },
];

export const founderStats = [
  { value: "8+", label: "Years engineering" },
  { value: "20", label: "Engineers led" },
  { value: "$10K", label: "Monthly cost saved with one rewrite" },
  { value: "100K+", label: "Daily payouts orchestrated" },
];

export const techStack: { category: string; items: string[]; icon: LucideIcon }[] = [
  {
    category: "Languages",
    icon: Cpu,
    items: ["TypeScript", "Node.js", "Python", "Dart", "Go"],
  },
  {
    category: "Databases",
    icon: Database,
    items: ["PostgreSQL", "MySQL", "MongoDB", "Redis", "DynamoDB"],
  },
  {
    category: "Cloud & DevOps",
    icon: Cloud,
    items: ["AWS", "Vercel", "Docker", "GitHub Actions", "Terraform"],
  },
  {
    category: "Security & Compliance",
    icon: ShieldCheck,
    items: ["GST/TDS Compliance", "PCI-DSS aware", "OAuth 2.0", "Data Encryption"],
  },
];
