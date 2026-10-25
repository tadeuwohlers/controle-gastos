# Spec 003 — App Mobile (Flutter) v1

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-24  
**Status:** Rascunho  
**Intent:** [003-app-mobile-flutter-v1](../intent/003-app-mobile-flutter-v1.md)  
**Depende de:** [Spec 001](001-controle-de-gastos.md) (API) e [Spec 002](002-frontend-web-v1.md) (comportamento de referência)

---

## Decisões tomadas

As decisões 1–15 estão no intent. A spec 002 é o contrato de comportamento: tudo que ela define para telas, validação e erros vale aqui, salvo o que esta spec adapta. Esta spec fecha o que o intent deixou em aberto ou implícito:

| # | Questão | Decisão |
|---|---------|---------|
| 1 | IP do Mac na rede (pergunta em aberto 1 do intent) | A URL da API é sempre passada por `--dart-define=API_URL=http://<host>:8000`. Simulador iOS e emulador Android usam `http://localhost:8000`; no Android, o alvo `make` roda `adb reverse tcp:8000 tcp:8000` antes (o `10.0.2.2` também funcionaria, mas o `localhost` mantém o mesmo endereço do web). Para aparelho físico o IP é informado em `API_URL=...` na chamada. Hostname `.local` (Bonjour) funciona no iOS e na maioria dos roteadores, mas não é garantido; não é requisito. Sem tela de configuração no app. |
| 2 | Pacotes | `flutter_riverpod`, `go_router`, `http`, `shared_preferences`, `intl`, `flutter_localizations` (SDK) e `timezone`. Nada de biblioteca de componentes, gerador de código (`freezed`, `json_serializable`, `riverpod_generator`) nem `build_runner`. Versões fixadas no `pubspec.lock`. |
| 3 | Mês "corrente" no cliente | `timezone` com `America/Sao_Paulo`, nunca o fuso do aparelho (mesma regra da spec 002, decisão 5). A base de fusos é inicializada na `main()` (`tz.initializeTimeZones()`). |
| 4 | Modelos e JSON | Classes Dart imutáveis escritas à mão, com `fromJson`/`toJson`. `Decimal` da API é sempre `String` no modelo. |
| 5 | Filtro por tipo | Feito no cliente, como no web (spec 002, decisão 3). |
| 6 | Parcelas Ativas e o seletor | Não reage ao seletor; rótulo "A partir do mês corrente" (spec 002, decisão 4). |
| 7 | Prévia de valor da parcela | Não há (spec 002, decisão 7). |
| 8 | Formato do `detail` | Mesmo normalizador da spec 002 (decisão 8), em Dart. |
| 9 | Persistência de "última Conta" | `shared_preferences` (`ultima_conta_id`), validada contra a lista de Contas ao ler; falha de leitura é ignorada. |
| 10 | Contrato com a API | O `openapi.json` é gerado, não versionado (hoje só existe de forma temporária dentro de `make gen-api`, via `scripts.export_openapi`). O alvo `test-mobile` o gera antes do teste de contrato e o apaga depois, como o `gen-api` faz; ver [Testes](#testes). |
| 11 | Tráfego HTTP sem TLS | Liberado apenas nas configurações de **debug/profile** (Android: `usesCleartextTraffic` no manifest de debug; iOS: `NSAppTransportSecurity` com `NSAllowsLocalNetworking` e `NSLocalNetworkUsageDescription` no `Info.plist`). O build de release não habilita texto claro, porque o release só faz sentido com a API hospedada (outro intent). |
| 12 | Estados de carregamento | Primeira leitura de uma tela mostra indicador de progresso; releituras (após mutação ou troca de Competência) mantêm o conteúdo anterior visível e sinalizam a atualização, sem piscar a tela vazia. |

---

## Mudança na API

Nenhuma. O app consome os endpoints da spec 001, incluindo os filtros de `GET /transacoes` entregues na spec 002.

---

## Arquitetura do app

### Rotas (`go_router`)

Navegação por abas (`StatefulShellRoute`), uma pilha por aba, com barra inferior (`NavigationBar`, Material 3):

| Aba | Rota | Conteúdo |
|-----|------|----------|
| Resumo | `/` | Resumo do mês |
| Transações | `/transacoes` | Lista da Competência |
| Parcelamentos | `/parcelamentos` | Lista de Parcelamentos |
| | `/parcelamentos/:id` | Detalhe e Parcelas (empilhado sobre a aba) |
| Cadastros | `/cadastros` | Contas e Categorias |

Um `id` inválido ou inexistente em `/parcelamentos/:id` mostra "Parcelamento não encontrado." com botão de voltar. Não há deep links nem URL como estado: Competência e filtros vivem em providers (ver abaixo).

### Estrutura de `lib/`

```
lib/
  main.dart                 # inicializa fusos, ProviderScope, MaterialApp.router
  app.dart                  # tema claro/escuro, localizações pt-BR, router
  config.dart               # API_URL via String.fromEnvironment
  api/
    api_client.dart         # GET/POST/PUT/DELETE, JSON, ApiException
    modelos.dart            # Conta, Categoria, Transacao, Parcelamento, Parcela, relatórios
    repositorio.dart        # chamadas tipadas por recurso
  estado/
    competencia_provider.dart   # Competência selecionada (Notifier)
    dados_provider.dart         # FutureProviders de leitura (contas, categorias, etc.)
    ultima_conta_provider.dart
  lib/                      # helpers puros, sem Flutter
    dinheiro.dart           # parseValorBR, formatBRL, sinal
    competencia.dart        # competenciaAtual, valida, deslocar, formatar, comparar
    erros.dart              # extrairMensagem
  telas/
    resumo_tela.dart
    transacoes_tela.dart
    parcelamentos_tela.dart
    parcelamento_detalhe_tela.dart
    cadastros_tela.dart
  widgets/
    competencia_picker.dart
    transacao_sheet.dart    # bottom sheet de criar/editar
    transacao_form.dart
    confirmar_dialog.dart
    erro_inline.dart
    estado_vazio.dart
    aviso_com_retry.dart
```

O diretório `lib/lib/` (helpers) fica sem dependência de Flutter, para testar em `dart test`/`flutter test` puros.

### Dados

- **Leitura:** `FutureProvider`s (e `family` quando recebem parâmetro, como `transacoesProvider(competencia, contaId, categoriaId)`) chamam o repositório. Dados sempre frescos: sem cache entre navegações além do que o provider mantém enquanto a tela está viva.
- **Mutação:** o widget chama o repositório e, em sucesso, executa `ref.invalidate(...)` dos providers afetados (equivalente ao `router.refresh()` do web). Tabela de invalidação:

  | Mutação | Invalida |
  |---------|----------|
  | Criar/editar/excluir Transação Avulsa | transações, balanço, gastos por categoria, parcelas ativas |
  | Criar Parcelamento | transações, parcelamentos, balanço, gastos por categoria, parcelas ativas |
  | Cancelar Parcelamento | parcelamento (detalhe), parcelamentos, transações, balanço, gastos por categoria, parcelas ativas |
  | Criar Conta | contas |
  | Criar Categoria | categorias |

- **Contas e Categorias** são lidas em toda tela que mostra nomes. A lista é pequena.
- **Falha de leitura:** a tela mostra `AvisoComRetry` com "Tentar de novo" (`ref.invalidate` do provider); a barra inferior continua utilizável.
- **Competência:** `competenciaProvider` (`Notifier<String>`) começa em `competenciaAtual()` e é compartilhado por Resumo e Transações. `deslocar`, `definir` e `hoje()` são as únicas operações. Aba Parcelamentos, Cadastros e o detalhe não mostram o seletor.
- **Filtros** de Transações (tipo, conta, categoria) ficam em estado local da tela e **resetam ao sair** dela, sem persistência. Valor inválido não existe (vêm de controles fechados).

---

## Helpers (`lib/lib/`)

Mesmos contratos da spec 002, traduzidos para Dart. Nenhuma função faz aritmética sobre valores.

### `dinheiro.dart`

| Função | Contrato |
|--------|----------|
| `String? parseValorBR(String entrada)` | `"1.234,56"` → `"1234.56"`, `"49,9"` → `"49.90"`, `"49"` → `"49.00"`. Aceita `.` como milhar e `,` como decimal. Retorna `null` se: vazio, mais de 2 casas decimais, mais de 10 dígitos inteiros, caracteres inválidos, ou valor zero. Negativo é inválido. Puramente textual. |
| `String formatBRL(String valor)` | `"1234.56"` → `"R$ 1.234,56"`; `"-100.00"` → `"-R$ 100,00"`. Implementação textual (agrupa milhares na parte inteira e usa `,`), **sem `double`** e sem `NumberFormat` sobre `num`. |
| `Sinal sinal(String valor)` | `positivo`, `negativo` ou `zero`, pela forma textual. Usado para colorir o saldo. |

> Diferença deliberada do web: lá o `Number` era tolerado só para alimentar o `Intl`. Em Dart, `formatBRL` agrupa os dígitos como texto, o que dispensa conversão numérica por completo.

### `competencia.dart`

| Função | Contrato |
|--------|----------|
| `String competenciaAtual()` | `"YYYY-MM"` do mês corrente em `America/Sao_Paulo`. Aceita um relógio injetável (`DateTime Function()`), para teste. |
| `bool valida(String c)` | Mês entre `01` e `12`, ano com 4 dígitos. |
| `String deslocar(String c, int n)` | `deslocar("2026-12", 1)` → `"2027-01"`. |
| `String formatar(String c)` | `"2026-10"` → `"outubro de 2026"` (nomes dos meses em pt-BR, embutidos; sem depender de dados de locale em runtime). |
| `int comparar(String a, String b)` | Ordem cronológica, -1/0/1. |

### `erros.dart`

`String extrairMensagem(Object? error)`, mesmas regras da spec 002 ([Erros](002-frontend-web-v1.md#erros)): `detail` string; `detail` lista (junta `msg`, removendo o prefixo `"Value error, "`); caso contrário `"Algo deu errado. Tente de novo."`. Recebe o corpo JSON já decodificado, ou o `ApiException`.

---

## Telas

Todas as regras de dados e textos da spec 002 valem. Abaixo, só a adaptação ao celular.

### Shell

- `Scaffold` com `NavigationBar` de 4 destinos (Resumo, Transações, Parcelamentos, Cadastros).
- **Seletor de Competência** (`competencia_picker`) no topo de Resumo e Transações: seta anterior, rótulo `formatar(mes)`, seta próxima e botão "Hoje" quando o mês selecionado não é o corrente. Alvos de toque ≥ 48 dp.
- **FAB "Nova transação"** visível nas quatro abas, acima da barra inferior. Abre o `transacao_sheet`.

### Resumo (aba `/`)

Mesmo conteúdo da spec 002: Balanço Mensal (Receitas, Gastos, Saldo com `sinal` + ícone), Gastos por Categoria com barra proporcional e Parcelas Ativas agrupadas por Competência com link para o detalhe. Chamadas em paralelo (`Future.wait` via providers independentes). Puxar para atualizar (`RefreshIndicator`) invalida os três. A barra proporcional é o único cálculo numérico permitido em `double`, apenas para largura visual, a partir do total da linha e do maior total; nunca é exibida como valor. Os vazios são os mesmos textos da spec 002.

### Transações (aba `/transacoes`)

- Dados: `GET /transacoes?competencia=…[&conta_id=][&categoria_id=]` + Contas + Categorias; tipo filtrado no cliente. Filtros em *chips* (tipo) e *menus* (conta, categoria) no topo da lista.
- Linha: descrição, categoria, conta, valor com sinal visual por tipo e selo `n/N` se for Parcela (toque no selo leva ao Parcelamento).
- **Transação Avulsa:** toque abre o sheet de edição; *swipe* para excluir ou menu "Excluir" abre o diálogo de confirmação e então `DELETE`. Menu contextual de Editar/Excluir também por pressão longa, para não depender só do gesto.
- **Parcela:** toque leva ao Parcelamento; sem Editar nem Excluir.
- Vazio: "Nenhuma transação neste mês." + botão "Nova transação". `RefreshIndicator` na lista.

### Bottom sheet de Transação (criar e editar)

`showModalBottomSheet` com `isScrollControlled: true` e `useSafeArea: true`, ocupando a altura útil acima do teclado (o conteúdo rola; o teclado não cobre o campo ativo). Fechar por gesto ou toque fora descarta o que foi digitado sem perguntar, como a gaveta do web.

**Campos e comportamento:** idênticos à spec 002 (Tipo primeiro; Valor, Descrição, Competência, Conta, Categoria; alternador À vista / Parcelado só na criação e só para Gasto; "Salvar" e "Salvar e nova"; criação inline de Conta e Categoria; validação cliente). Diferenças:

- Teclado numérico (`TextInputType.numberWithOptions(decimal: true)`) em Valor e Número de parcelas; a entrada continua passando por `parseValorBR`, que aceita `,` e `.`.
- Competência e Primeira parcela escolhidas num seletor de mês simples (anterior/próximo, mesmo componente do shell), não num `DatePicker` de dia.
- Conta e Categoria em *dropdown* de tela cheia ou *bottom sheet* de seleção, com busca só se houver muitos itens (decisão de implementação).
- Parcelamento criado com sucesso: o sheet fecha e o app navega para o detalhe do Parcelamento.
- Erros `409`/`422`/`404`: inline no topo do sheet, mantendo o que foi digitado. Falha de rede/`5xx`: `AvisoComRetry` que reenvia o mesmo payload.

### Parcelamentos (aba `/parcelamentos`)

Lista com chips Todos / Ativos / Cancelados (`GET /parcelamentos[?status=]`), linha com descrição, valor total, `N×`, primeira parcela, conta, categoria e selo de status. Vazio: "Nenhum parcelamento." com botão "Nova transação".

### Detalhe do Parcelamento (`/parcelamentos/:id`)

Idêntico à spec 002: cabeçalho, lista de Parcelas (`n/N`, Competência, valor; a do mês corrente destacada, as passadas esmaecidas) e "Cancelar" (só se `ativo`) com diálogo de efeito calculado no cliente por `comparar(competencia, competenciaAtual())`. Após o `POST`, mostra os números **retornados pela API** (`parcelas_removidas`, `parcelas_preservadas`); `422 "Parcelamento já cancelado."` mostra a mensagem e recarrega.

### Cadastros (aba `/cadastros`)

Duas seções (Contas, Categorias agrupadas por tipo), cada uma com lista e formulário de criação (nome; tipo para Categoria). Sem renomear, excluir ou desativar. Vazio: mensagem explicando para que servem.

---

## Erros

Mesma tabela da spec 002: formulários mostram erro inline; falhas de rede e `5xx` mostram `AvisoComRetry`; leituras que falham mostram o aviso na própria tela. `ApiException` carrega `status` e o corpo decodificado; `extrairMensagem` é o único ponto que transforma `detail` em texto. Timeout de requisição: 15 s, tratado como falha de rede.

---

## Aparência e plataforma

- Material 3 (`useMaterial3: true`), `ColorScheme.fromSeed`, tema claro e escuro seguindo o sistema (`ThemeMode.system`). Sem alternador manual.
- `locale` fixo `pt-BR` com `GlobalMaterialLocalizations` e companhia; textos em português; valores com `formatBRL`; meses por extenso com `formatar`.
- Orientação travada em retrato (manifest Android `screenOrientation`, `UISupportedInterfaceOrientations` no iOS).
- Acessibilidade mínima: alvos ≥ 48 dp; todo controle com `Semantics`/rótulo; estado nunca depende só de cor (saldo e tipo têm sinal ou ícone); texto respeita a escala de fonte do sistema sem estourar o layout.
- Nome de exibição "Controle de Gastos"; identificadores `br.com.tadeuwohlers.controlegastos` (Android `applicationId` e iOS `PRODUCT_BUNDLE_IDENTIFIER`), provisórios, até haver publicação.

---

## Testes

### Unitários (`flutter test`, `test/lib/`)

Os mesmos casos da spec 002, em Dart:

- `parseValorBR`: `"1.234,56"`, `"49,9"`, `"49"`, `"0,00"` (null), `"-5"` (null), `"1,234"` (null; 3 casas), `"12345678901"` (null; excede 10 dígitos), `""`, `"abc"`.
- `formatBRL` e `sinal`, incluindo negativo, zero, milhares e valores sem parte inteira.
- `competencia.dart`: `deslocar` na virada de ano, `valida`, `formatar`, `competenciaAtual` com relógio injetado perto da meia-noite e do fim do mês (`America/Sao_Paulo` vs UTC).
- `extrairMensagem`: string, lista com prefixo `"Value error, "`, corpo inesperado.

### Contrato (`flutter test`, `test/contrato/`)

Um teste lê o `apps/api/openapi.json` (gerado por `uv run python -m scripts.export_openapi > openapi.json` no alvo `test-mobile`, que o remove ao final) e confere, para cada endpoint usado pelo app, que o caminho, o método e os nomes dos campos obrigatórios das respostas/requisições existem no schema. Quebra se a API renomear ou remover algo que o app usa. Se o arquivo não existir, o teste falha com a instrução de rodar `make test-mobile`.

### Widgets (`flutter test`, `test/telas/`)

Com repositório falso (`ProviderScope` com `overrides`):

- Resumo: balanço, gastos por categoria e parcelas ativas, mais o estado vazio.
- Transações: lista, filtro de tipo, selo de Parcela sem ações de edição/exclusão, exclusão com confirmação.
- Bottom sheet: tipo filtra Categorias; alternador Parcelado desabilitado para Receita; erro inline mantém o digitado; criação inline de Conta/Categoria.
- Detalhe do Parcelamento: prévia do cancelamento (`removidas`/`preservadas`) e a mensagem final com os números da API.

### Integração (`integration_test`, emulador/simulador)

Contra a API real e o banco `controle_gastos_test`, recriado antes da suíte (`apps/api/scripts/recriar_banco_teste.py`). O alvo `make e2e-mobile` sobe a API de teste (porta 8100, como no web) e roda `flutter test integration_test --dart-define=API_URL=…`. Um fluxo, o mesmo da spec 002:

1. Banco vazio → abrir o sheet pelo FAB e criar Conta e Categoria de Gasto inline, depois lançar um Gasto.
2. Criar Categoria de Receita inline e lançar uma Receita.
3. Lançar um Parcelamento (R$ 100,00 em 3×, primeira parcela no mês corrente) e conferir as 3 Parcelas (33,33 / 33,33 / 33,34).
4. Conferir no Resumo o Balanço Mensal e os Gastos por Categoria.
5. Cancelar o Parcelamento: o diálogo mostra "2 parcelas futuras removidas"; depois, a lista do mês corrente mantém a 1ª parcela e os meses seguintes não têm as demais.

Não rodar junto com `make test` da API nem com `make e2e-web`: ambos usam `controle_gastos_test`.

### Critério de pronto

`flutter analyze`, `flutter test` e o teste de integração passam; `make test` e `make lint` (API) continuam passando; o app compila e roda no emulador Android e no simulador iOS, e abre e lança uma Transação em um aparelho físico no mesmo Wi-Fi da API.

---

## Fatias de entrega

Cada fatia é uma issue (`ready-for-agent`) e termina testável. A ordem vem do intent. Sem fatia de API.

1. **Casca.** `flutter create` em `apps/mobile` (Android e iOS apenas), `pubspec`, `config.dart` e `--dart-define`, tema e localização pt-BR, orientação travada, texto claro nos manifestos de debug, navegação por abas, `competenciaProvider` e `competencia_picker`, helpers `dinheiro`/`competencia`/`erros` com testes, `api_client` e `modelos`, teste de contrato e comandos `make` (`dev-mobile`, `lint-mobile`, `test-mobile`, `build-mobile`, `e2e-mobile`) + `apps/mobile/CLAUDE.md`. Valida o ambiente (`flutter doctor`).
2. **Cadastros e Transação Avulsa.** `/cadastros`, `/transacoes`, bottom sheet (criar e editar, "Salvar e nova", criação inline), exclusão com confirmação, última Conta. Ao final, já dá para lançar no dia a dia.
3. **Resumo do mês.** Os três relatórios, incluindo vazios e puxar para atualizar.
4. **Parcelamentos.** Alternador Parcelado, lista, detalhe, cancelamento com prévia e confirmação, link das Parcelas e das Parcelas Ativas.
5. **Acabamento.** Estados vazios e de erro revisados, acessibilidade mínima, tema escuro conferido, e o teste de integração.

---

## Notas de implementação

- `valor` e demais `Decimal` chegam como string e são enviados como string (JSON `"1234.56"`); nunca `double.parse` em valor.
- `competencia` e `primeira_parcela` trafegam como `"YYYY-MM"`.
- A base URL é só a origem; os paths já incluem `/api/v1` (como no cliente do web).
- `API_URL` é a única variável de configuração; documentada em `apps/mobile/CLAUDE.md`. Sem ela, o app mostra uma tela de erro de configuração em vez de tentar um padrão.
- O Dart exige `await`/`mounted` ao usar `BuildContext` depois de chamadas assíncronas; checar `context.mounted` antes de fechar o sheet ou navegar.
- Todo texto de UI usa os termos do `GLOSSARY.md`: Competência, Parcelamento, Parcela, Transação Avulsa, Balanço Mensal, Conta, Categoria.
- O ambiente (Android SDK completo e Xcode) é pré-requisito do critério de pronto, não da fatia 1 inteira: helpers e testes rodam sem ele.
