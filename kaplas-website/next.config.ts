import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",                 // ← exports to plain HTML/CSS/JS
  images: { unoptimized: true },    // ← needed because S3 has no image optimizer
  trailingSlash: true,              // ← S3 prefers /about/ over /about

};

export default nextConfig;
