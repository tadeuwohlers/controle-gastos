import { defineConfig } from "@playwright/test";

// Portas próprias: o E2E nunca reaproveita (nem derruba) os servidores de desenvolvimento.
const PORTA_API = 8100;
const PORTA_WEB = 3100;
const URL_WEB = `http://localhost:${PORTA_WEB}`;
const DATABASE_URL =
  process.env.E2E_DATABASE_URL ??
  "postgresql+psycopg://controle_gastos:dev_password@localhost:5432/controle_gastos_test";

export default defineConfig({
  testDir: "./e2e",
  testMatch: "**/*.e2e.ts",
  workers: 1,
  fullyParallel: false,
  reporter: "list",
  use: { baseURL: URL_WEB, locale: "pt-BR", timezoneId: "America/Sao_Paulo", trace: "retain-on-failure" },
  webServer: [
    {
      // Recria o banco de teste e só então sobe a API apontando para ele.
      command: `uv run python -m scripts.recriar_banco_teste && uv run uvicorn controle_gastos.main:app --port ${PORTA_API}`,
      cwd: "../api",
      env: { DATABASE_URL, CORS_ORIGINS: JSON.stringify([URL_WEB]) },
      url: `http://localhost:${PORTA_API}/docs`,
      reuseExistingServer: false,
      timeout: 120_000,
    },
    {
      command: `npx next build && npx next start --port ${PORTA_WEB}`,
      env: {
        NEXT_PUBLIC_API_URL: `http://localhost:${PORTA_API}/api/v1`,
        NEXT_DIST_DIR: ".next-e2e",
      },
      url: URL_WEB,
      reuseExistingServer: false,
      timeout: 300_000,
    },
  ],
});
