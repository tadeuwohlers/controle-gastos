# apps/web

Front-end web em Next.js (App Router, TypeScript, Tailwind). Gerenciador de pacotes: npm. Rode os comandos a partir de `apps/web/` ou, da raiz, via `make`.

Veja também `AGENTS.md` (gerado pelo Next.js): consulte `node_modules/next/dist/docs/` antes de escrever código, pois esta versão tem mudanças em relação ao que se conhece.

## Commands

```bash
npm run dev     # dev server (porta 3000)
npm run build   # build de produção
npm run lint    # eslint
npm run test    # vitest (testes unitários dos helpers)
```

## Conventions

- Código em `src/`; alias `@/*` aponta para `src/*`.
- A API roda em `NEXT_PUBLIC_API_URL` (ver `.env.example`).
- `valor` e demais `Decimal` chegam da API como **string**: nunca converter para `number` para fazer conta ou exibir sem cuidado.
- `competencia` trafega como `"YYYY-MM"`.
