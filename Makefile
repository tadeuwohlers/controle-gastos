.PHONY: dev dev-web build-web lint-web e2e-web gen-api db test lint format migrate dev-mobile dev-mobile-ios dev-mobile-android lint-mobile test-mobile build-mobile

# Raiz do monorepo: delega para cada app. Sem prefixo = API; sufixo -web = Next.js;
# sufixo -mobile = Flutter.

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

# App mobile (Flutter). A API roda no Mac (`make dev`, porta 8000, escuta em 0.0.0.0).
# Simulador iOS e emulador Android usam http://localhost:8000 (no Android, via
# `adb reverse`); aparelho físico no Wi-Fi exige o IP do Mac:
#   make dev-mobile API_URL=http://192.168.0.10:8000
ADB ?= $(or $(ANDROID_HOME),$(HOME)/Library/Android/sdk)/platform-tools/adb

dev-mobile-ios:
	cd apps/mobile && flutter run -d ios --dart-define=API_URL=$(or $(API_URL),http://localhost:8000)

# `adb reverse` faz o localhost:8000 do emulador chegar ao localhost:8000 do Mac.
dev-mobile-android:
	$(ADB) reverse tcp:8000 tcp:8000
	cd apps/mobile && flutter run -d android --dart-define=API_URL=$(or $(API_URL),http://localhost:8000)

dev-mobile:
	@test -n "$(API_URL)" || { echo "Informe API_URL=http://<ip-do-mac>:8000 (ou use dev-mobile-ios / dev-mobile-android)"; exit 1; }
	cd apps/mobile && flutter run --dart-define=API_URL=$(API_URL)

lint-mobile:
	cd apps/mobile && flutter analyze

# Gera o OpenAPI da API para o teste de contrato e o apaga ao final (como o gen-api).
test-mobile:
	cd apps/api && uv run python -m scripts.export_openapi > openapi.json
	cd apps/mobile && flutter test; status=$$?; rm -f ../api/openapi.json; exit $$status

# Compila as duas plataformas (debug, sem assinatura). API_URL só entra no binário.
build-mobile:
	cd apps/mobile && flutter build apk --debug --dart-define=API_URL=$(or $(API_URL),http://localhost:8000)
	cd apps/mobile && flutter build ios --simulator --debug --dart-define=API_URL=$(or $(API_URL),http://localhost:8000)
