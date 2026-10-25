#!/usr/bin/env bash
# E2E do app (integration_test) contra a API real e o banco `controle_gastos_test`.
#
# Recria o banco, sobe a API na porta 8100 (nunca toca a 8000 de desenvolvimento),
# roda `integration_test/` num simulador iOS ou emulador Android já abertos e
# derruba a API ao final.
#
#   E2E_DEVICE=ios      (padrão) primeiro simulador iOS aberto
#   E2E_DEVICE=android  primeiro emulador Android aberto (faz `adb reverse`)
#   E2E_DEVICE=<id>     id do `flutter devices`
#   E2E_DATABASE_URL    outro banco (o nome precisa terminar em `_test`)
set -euo pipefail

cd "$(dirname "$0")/.."
PORTA=8100
DEVICE="${E2E_DEVICE:-ios}"
DATABASE_URL="${E2E_DATABASE_URL:-postgresql+psycopg://controle_gastos:dev_password@localhost:5432/controle_gastos_test}"
ADB="${ADB:-${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb}"
LOG="$(mktemp -t e2e-mobile-api)"

case "$DEVICE" in
  ios)
    DEVICE="$(xcrun simctl list devices booted | grep -Eo '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' | head -1 || true)"
    [[ -n "$DEVICE" ]] || { echo "Nenhum simulador iOS aberto. Abra um (ex.: open -a Simulator)." >&2; exit 1; }
    ;;
  android)
    DEVICE="$("$ADB" devices | awk '/^emulator-[0-9]+\tdevice/ {print $1; exit}')"
    [[ -n "$DEVICE" ]] || { echo "Nenhum emulador Android aberto. Abra um (flutter emulators --launch <id>)." >&2; exit 1; }
    "$ADB" -s "$DEVICE" reverse "tcp:$PORTA" "tcp:$PORTA" >/dev/null
    ;;
esac

# Recusa qualquer banco que não termine em `_test` (o próprio script confere).
(cd ../api && DATABASE_URL="$DATABASE_URL" uv run python -m scripts.recriar_banco_teste)

(cd ../api && DATABASE_URL="$DATABASE_URL" exec uv run uvicorn controle_gastos.main:app --port "$PORTA" >"$LOG" 2>&1) &
API_PID=$!
trap 'pkill -P "$API_PID" 2>/dev/null || true; kill "$API_PID" 2>/dev/null || true' EXIT

for _ in $(seq 1 60); do
  curl -sf "http://localhost:$PORTA/docs" >/dev/null && break
  sleep 1
done
curl -sf "http://localhost:$PORTA/docs" >/dev/null || { echo "API não subiu; log em $LOG" >&2; exit 1; }

echo "API de teste em :$PORTA (log: $LOG); dispositivo: $DEVICE"
flutter test integration_test -d "$DEVICE" --dart-define="API_URL=http://localhost:$PORTA"
