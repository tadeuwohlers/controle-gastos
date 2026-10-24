.PHONY: dev dev-web build-web lint-web e2e-web gen-api db test lint format migrate

# Raiz do monorepo: delega para cada app. Sem prefixo = API; sufixo -web = Next.js.

db:
	docker compose up -d postgres

dev:
	$(MAKE) -C apps/api dev

test:
	$(MAKE) -C apps/api test

lint:
	$(MAKE) -C apps/api lint

format:
	$(MAKE) -C apps/api format

migrate:
	$(MAKE) -C apps/api migrate

dev-web:
	npm --prefix apps/web run dev

build-web:
	npm --prefix apps/web run build

lint-web:
	npm --prefix apps/web run lint

# E2E (Playwright) contra a API e o banco `controle_gastos_test`; precisa do `make db`.
e2e-web:
	npm --prefix apps/web run e2e

# Regenera os tipos TypeScript do web a partir do OpenAPI da API.
gen-api:
	cd apps/api && uv run python -m scripts.export_openapi > openapi.json
	npm --prefix apps/web run gen:api
	rm -f apps/api/openapi.json
