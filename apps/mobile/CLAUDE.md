# apps/mobile

App mobile em Flutter (Dart), Android e iPhone, em retrato. Cliente da mesma API do web; o comportamento de referência é a [spec 002](../../docs/spec/002-frontend-web-v1.md) e a spec do app é a [003](../../docs/spec/003-app-mobile-flutter-v1.md). Rode os comandos a partir de `apps/mobile/` ou, da raiz, via `make`.

## Commands

```bash
flutter analyze                # lint (make lint-mobile)
flutter test                   # testes (make test-mobile, que também gera o openapi.json do contrato)
make dev-mobile-ios            # simulador iOS, API em localhost:8000
make dev-mobile-android        # emulador Android, API em localhost:8000 (via adb reverse)
make dev-mobile API_URL=http://<ip-do-mac>:8000   # aparelho físico no mesmo Wi-Fi
make build-mobile              # compila APK debug e app do simulador iOS
make e2e-mobile                # E2E (integration_test) no simulador iOS aberto
make e2e-mobile E2E_DEVICE=android   # idem, no emulador Android aberto
```

Da raiz, `make dev` sobe a API (já escuta em `0.0.0.0:8000`) e `make db` o Postgres.

## API_URL

A URL da API é configuração de build: `--dart-define=API_URL=http://<host>:8000`, só a origem (os paths já incluem `/api/v1`). Sem ela o app mostra a tela "API não configurada".

- Simulador iOS e emulador Android: `http://localhost:8000`. No Android, `make dev-mobile-android` roda `adb reverse tcp:8000 tcp:8000` antes (sem isso o `localhost` do emulador é o próprio emulador; o endereço do Mac visto de dentro dele é `10.0.2.2`). Instalou o APK por fora do make? Rode o `adb reverse` uma vez por emulador.
- Aparelho físico: o IP do Mac na rede (`ipconfig getifaddr en0`); celular e Mac no mesmo Wi-Fi.
- HTTP sem TLS: liberado só nos manifestos Android de debug/profile; no iOS, `NSAllowsLocalNetworking` e `NSLocalNetworkUsageDescription` no `Info.plist`. O release sem TLS só faz sentido com a API hospedada (outro intent).

## Conventions

- Código em `lib/`, importando sempre por `package:controle_gastos/...` (o lint `avoid_relative_lib_imports` proíbe imports relativos entre pastas de `lib/`).
- `lib/lib/` guarda os helpers puros (`dinheiro`, `competencia`, `erros`), sem Flutter. Nenhum faz aritmética sobre valores.
- `valor` e demais `Decimal` chegam da API como **string** e seguem string nos modelos e no envio: nunca `double.parse`/`num` para somar, comparar ou exibir. Único `double` permitido: largura da barra proporcional do Resumo.
- `competencia` trafega como `"YYYY-MM"`. O mês corrente vem de `competenciaAtual()` (`America/Sao_Paulo`, via pacote `timezone`), nunca do fuso do aparelho. `tz.initializeTimeZones()` roda na `main` e em testes que usam a Competência corrente.
- Estado com Riverpod; mutação seguida de `ref.invalidate(...)` dos providers afetados (tabela na spec 003).
- Sem biblioteca de componentes, só Material 3, e sem geradores de código (`build_runner`).
- Textos da UI usam os termos do `GLOSSARY.md`.

## E2E (integration_test)

Pré-requisitos: `make db` (Postgres no ar), `uv` instalado e um simulador iOS (padrão) ou emulador Android **já abertos**.

`make e2e-mobile` (roda `scripts/e2e.sh`) sobe tudo sozinho, sem tocar no ambiente de desenvolvimento:

- **Banco:** `controle_gastos_test`, o mesmo Postgres do `make db`. `apps/api/scripts/recriar_banco_teste.py` cria o banco se faltar, apaga o schema e aplica as migrations; recusa qualquer banco cujo nome não termine em `_test`. Outra URL: `E2E_DATABASE_URL`.
- **API:** `uvicorn` na porta **8100** (nunca a 8000 de desenvolvimento), derrubada ao final. No Android o script faz `adb reverse tcp:8100 tcp:8100`.
- **Dispositivo:** `E2E_DEVICE=ios` (padrão, primeiro simulador aberto), `E2E_DEVICE=android` (primeiro emulador aberto) ou um id do `flutter devices`.
- `integration_test/fluxo_test.dart` é o fluxo único da spec e **exige banco vazio**: cria Conta e Categoria no formulário, lança Gasto, Receita e um Parcelamento (R$ 100,00 em 3×: 33,33 / 33,33 / 33,34), confere o Balanço Mensal e cancela o Parcelamento.
- Não rode junto com `make test` da API, `make e2e-web` nem outro `make e2e-mobile`: todos usam `controle_gastos_test` (e `make e2e-web` também a porta 8100).
- O teste espera a rede com `aguardar` (com rede de verdade `pumpAndSettle` volta antes da resposta) e fecha o teclado antes de tocar (`fecharTeclado`), porque o teclado muda o layout do sheet no iOS e no Android.
- Em falha, o log da API fica no arquivo temporário que o script imprime (`e2e-mobile-api.*`).

## Testes

- `test/lib/`: helpers, com os mesmos casos do web.
- `test/api/`: cliente HTTP, com `MockClient`.
- `test/contrato/`: confere o que o app chama, envia e lê contra o `apps/api/openapi.json`. Esse arquivo não é versionado: `make test-mobile` o gera e o apaga depois. Rodar `flutter test` direto falha no teste "o app respeita o openapi.json atual" com a instrução de usar o `make`.
- `test/telas/`: widgets, com `ProviderScope` e overrides. `acabamento_test.dart` percorre todas as telas em tema escuro e com fonte 1,5× e 2× (sem overflow) e confere as guias de acessibilidade do Flutter (alvos ≥ 48 dp, rótulos e contraste) nos dois temas.
- `integration_test/`: o E2E acima; `flutter test` sozinho não o roda.
