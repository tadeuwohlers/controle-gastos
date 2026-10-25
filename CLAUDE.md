## Monorepo layout

```
apps/api/     # API REST (Python/FastAPI) — ver apps/api/CLAUDE.md
apps/web/     # Front-end (Next.js) — ver apps/web/CLAUDE.md
apps/mobile/  # App mobile (Flutter) — ver apps/mobile/CLAUDE.md
docs/         # intent/, spec/, plan/, adr/, agents/
GLOSSARY.md   # vocabulário do domínio (fonte única)
```

Cada app tem seu próprio `CLAUDE.md` com comandos e convenções. Specs em `docs/spec/` são do sistema todo, não de um app; a numeração (`001`, `002`, …) é compartilhada.

## Commands (da raiz)

```bash
make db        # sobe o Postgres (docker compose)
make dev       # start API dev server
make test      # run API test suite
make lint      # run API linter
make format    # auto-format API code
make migrate   # apply pending API migrations
make dev-web   # start web dev server
make build-web # build web
make lint-web  # lint web
make e2e-web   # E2E do web (Playwright, banco controle_gastos_test)
make dev-mobile-ios      # app mobile no simulador iOS (API em localhost:8000)
make dev-mobile-android  # app mobile no emulador Android (API em 10.0.2.2:8000)
make dev-mobile API_URL=http://<ip>:8000  # aparelho físico no mesmo Wi-Fi
make test-mobile  # testes do app (gera o openapi.json do teste de contrato)
make lint-mobile  # flutter analyze
make build-mobile # compila APK debug e app do simulador iOS
```

## Agent skills

### Issue tracker

GitHub Issues in `tadeuwohlers/controle-gastos`, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default triage labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
