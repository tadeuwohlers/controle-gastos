import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // O E2E builda em outro diretório para não pisar no `.next` do dev server.
  distDir: process.env.NEXT_DIST_DIR ?? ".next",
  /* config options here */
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
