.PHONY: dev dev-web build-web lint-web db test lint format migrate

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
