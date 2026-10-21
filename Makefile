.PHONY: dev db test lint format migrate

# Raiz do monorepo: delega para cada app. Comandos do app web serão adicionados com apps/web.

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
