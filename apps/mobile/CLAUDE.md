# apps/mobile

App mobile em Flutter (Dart), Android e iPhone, em retrato. Cliente da mesma API do web; o comportamento de referência é a [spec 002](../../docs/spec/002-frontend-web-v1.md) e a spec do app é a [003](../../docs/spec/003-app-mobile-flutter-v1.md). Rode os comandos a partir de `apps/mobile/` ou, da raiz, via `make`.

## Commands

```bash
flutter analyze                # lint (make lint-mobile)
flutter test                   # testes (make test-mobile, que também gera o openapi.json do contrato)
make dev-mobile-ios            # simulador iOS, API em localhost:8000
make dev-mobile-android        # emulador Android, API em 10.0.2.2:8000
make dev-mobile API_URL=http://<ip-do-mac>:8000   # aparelho físico no mesmo Wi-Fi
make build-mobile              # compila APK debug e app do simulador iOS
```

Da raiz, `make dev` sobe a API (já escuta em `0.0.0.0:8000`) e `make db` o Postgres.

## API_URL

A URL da API é configuração de build: `--dart-define=API_URL=http://<host>:8000`, só a origem (os paths já incluem `/api/v1`). Sem ela o app mostra a tela "API não configurada".

- Simulador iOS: `http://localhost:8000`. Emulador Android: `http://10.0.2.2:8000`.
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

## Testes

- `test/lib/`: helpers, com os mesmos casos do web.
- `test/api/`: cliente HTTP, com `MockClient`.
- `test/contrato/`: confere o que o app chama, envia e lê contra o `apps/api/openapi.json`. Esse arquivo não é versionado: `make test-mobile` o gera e o apaga depois. Rodar `flutter test` direto falha no teste "o app respeita o openapi.json atual" com a instrução de usar o `make`.
- `test/telas/`: widgets, com `ProviderScope` e overrides.
