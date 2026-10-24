# apps/web

Front-end web em Next.js (App Router, TypeScript, Tailwind). Gerenciador de pacotes: npm. Rode os comandos a partir de `apps/web/` ou, da raiz, via `make`.

Veja também `AGENTS.md` (gerado pelo Next.js): consulte `node_modules/next/dist/docs/` antes de escrever código, pois esta versão tem mudanças em relação ao que se conhece.

## Commands

```bash
npm run dev     # dev server (porta 3000)
npm run build   # build de produção
npm run lint    # eslint
npm run test    # vitest (testes unitários dos helpers)
npm run e2e     # Playwright (ponta a ponta, ver abaixo)
```

## E2E (Playwright)

Pré-requisitos: `make db` (Postgres no ar), `uv` instalado e, uma vez, `npx playwright install chromium`.

`npm run e2e` (ou `make e2e-web` na raiz) sobe tudo sozinho, em portas próprias, sem tocar no ambiente de desenvolvimento:

- **Banco:** `controle_gastos_test`, no mesmo Postgres do `make db`. `apps/api/scripts/recriar_banco_teste.py` cria o banco se faltar, apaga o schema e aplica as migrations antes da suíte; recusa qualquer banco cujo nome não termine em `_test`. Outra URL: `E2E_DATABASE_URL`.
- **API:** `uvicorn` na porta 8100 com `DATABASE_URL` apontando para o banco de teste.
- **Web:** build de produção em `.next-e2e` (não pisa no `.next` do `npm run dev`) servido na porta 3100.
- `e2e/01-fluxo.e2e.ts` é o fluxo único da spec e **exige banco vazio** (por isso roda primeiro); `e2e/02-revisao.e2e.ts` cobre erros, filtros, mobile e foco, com dados próprios.
- Não rode junto com `make test` da API: o pytest também usa `controle_gastos_test` (`TEST_DATABASE_URL`) e recria as tabelas.
- Em falha, o trace fica em `test-results/` (`npx playwright show-trace <trace.zip>`).

## Conventions

- Código em `src/`; alias `@/*` aponta para `src/*`.
- A API roda em `NEXT_PUBLIC_API_URL` (ver `.env.example`).
- `valor` e demais `Decimal` chegam da API como **string**: nunca converter para `number` para fazer conta ou exibir sem cuidado.
- `competencia` trafega como `"YYYY-MM"`.
