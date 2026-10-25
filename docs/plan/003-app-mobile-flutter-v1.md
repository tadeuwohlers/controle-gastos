# Plano de Implementação — Spec 003 App Mobile (Flutter) v1

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-24  
**Spec:** [spec/003-app-mobile-flutter-v1.md](../spec/003-app-mobile-flutter-v1.md)  
**Intent:** [intent/003-app-mobile-flutter-v1.md](../intent/003-app-mobile-flutter-v1.md)

---

## Context

A API (spec 001) e o web (spec 002) estão prontos. Falta `apps/mobile`: um app Flutter que repete o comportamento do web com idioma de interação mobile. Não há mudança na API, então o plano é só de cliente, em cinco fatias verticais (ordem da spec). Cada fatia vira uma issue `ready-for-agent`, sub-issue de uma issue-mãe "App mobile v1", como foi feito no web (#10–#16).

---

## Pré-requisito humano (fora das fatias)

O `flutter doctor` de hoje acusa Android SDK sem `cmdline-tools` e licenças, e Xcode incompleto. Isso pede senha e a App Store, então é do Tadeu, e **não bloqueia as fatias 1–4** (helpers, widgets e `flutter test` rodam sem). Bloqueia:

- rodar no emulador Android / simulador iOS e o teste de integração (fatia 5);
- o aceite "compila nas duas plataformas" (fatias 1 e 5).

Checklist:

```bash
flutter doctor --android-licenses
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
flutter doctor        # deve ficar verde nas duas categorias
```

---

## Ordem e dependências

```
1 Casca ──→ 2 Cadastros + Transação Avulsa ──→ 3 Resumo
                          │
                          └──────────────────→ 4 Parcelamentos ──→ 5 Acabamento + integração
```

- A fatia 3 só depende de 1 e do sheet/estado da 2 para o FAB; pode ser paralela à 4 depois da 2, mas as duas tocam `lib/telas/` e `dados_provider.dart`: **execute em sequência** (3, depois 4), para evitar conflito.
- A 4 estende o sheet da 2 (alternador Parcelado), então depende dela.
- A 5 depende de todas.

---

## Riscos e como o plano os trata

1. **Dinheiro sem `double`.** `formatBRL` é textual (spec, helpers). Mitigação: testes de tabela na fatia 1 antes de qualquer tela e critério de aceite "nenhum `double.parse`/`num` sobre valor" em todas as fatias (exceto a largura da barra do Resumo).
2. **Fuso e virada de mês.** `competenciaAtual` com `timezone` e relógio injetável; testes perto da meia-noite e do fim do mês (fatia 1). A prévia de cancelamento (fatia 4) usa a mesma função.
3. **Rede local e HTTP sem TLS.** Texto claro só em debug/profile; iOS pede `NSLocalNetworkUsageDescription`. Isso só se prova num aparelho físico, então o aceite da fatia 5 exige o teste manual no Wi-Fi.
4. **Deriva do contrato.** Cliente manual, mitigado pelo teste de contrato contra o `openapi.json` gerado (fatia 1, `make test-mobile`).
5. **Invalidação incompleta.** Mutação que não invalida um provider deixa o Resumo velho. A tabela de invalidação da spec vira teste de widget em cada fatia que muta.
6. **Banco de teste compartilhado.** O `integration_test` usa `controle_gastos_test`, como `make test` e `make e2e-web`; nunca rodar juntos (documentar no `apps/mobile/CLAUDE.md`).

---

## Fatias

Cada seção é o corpo da issue correspondente. Todas começam com `Part of #<mãe>` e o link da spec, e pedem que se leia a spec inteira.

### 1/5 — Casca: projeto, navegação, Competência, helpers e cliente

**Escopo** (seções "Arquitetura do app", "Helpers", "Erros", "Aparência e plataforma", "Testes" e "Notas de implementação"):

- `flutter create` em `apps/mobile` só com Android e iOS; identificadores provisórios da spec; nome "Controle de Gastos".
- `pubspec` com os pacotes da spec (nenhum gerador de código); `config.dart` com `API_URL` via `--dart-define` e tela de erro de configuração quando ausente.
- Tema Material 3 claro/escuro, `pt-BR`, orientação retrato; texto claro só nos manifestos debug/profile (Android) e `NSAllowsLocalNetworking` + `NSLocalNetworkUsageDescription` (iOS).
- Navegação por abas (`StatefulShellRoute`, `NavigationBar` com 4 destinos), telas placeholder, FAB "Nova transação" (abre um sheet vazio por enquanto).
- `competenciaProvider` e `competencia_picker` (setas, rótulo, "Hoje").
- `lib/lib/dinheiro.dart`, `competencia.dart`, `erros.dart` conforme os contratos, com testes de tabela.
- `api_client.dart` (timeout 15 s, `ApiException`), `modelos.dart` e `repositorio.dart` para os endpoints da spec 001.
- Teste de contrato contra o `openapi.json`.
- `make dev-mobile`, `lint-mobile`, `test-mobile` (gera e apaga o `openapi.json`), `build-mobile`; `apps/mobile/CLAUDE.md` e `.env`/exemplo de `API_URL` por alvo; atualizar o `CLAUDE.md` da raiz (layout e comandos).

**Aceite:**

- [ ] Testes unitários cobrem todos os casos da seção "Testes" da spec, incluindo `competenciaAtual` perto da meia-noite e do fim do mês em `America/Sao_Paulo`.
- [ ] Teste de contrato passa e falha quando um campo usado some do OpenAPI.
- [ ] Nenhuma aritmética sobre valores no código.
- [ ] `flutter analyze` e `flutter test` passam; `make test-mobile` e `make lint-mobile` funcionam da raiz.
- [ ] Com o ambiente pronto: `flutter doctor` verde, o app abre em Android e iOS mostrando as 4 abas e o seletor (se ainda não estiver pronto, registrar na issue o que faltou).

### 2/5 — Cadastros e Transação Avulsa

**Escopo** (seções "Dados", "Telas": Cadastros, Transações e Bottom sheet de Transação):

- Aba Cadastros: listar e criar Contas e Categorias (agrupadas por tipo).
- Aba Transações: lista da Competência, filtros (tipo no cliente; conta e categoria na API), selo `n/N`, vazio, puxar para atualizar.
- Bottom sheet de criar/editar Transação Avulsa: campos, validação cliente, "Salvar" e "Salvar e nova", criação inline de Conta e Categoria, última Conta (`shared_preferences`), erros `409`/`422` inline e `AvisoComRetry` para rede/`5xx`.
- Exclusão com confirmação (swipe e menu/pressão longa); Parcela sem editar/excluir.
- Invalidação conforme a tabela da spec.
- Alternador "Parcelado" ainda **não**: entra na fatia 4.

**Aceite:**

- [ ] Testes de widget: Transações (lista, filtro de tipo, Parcela sem ações, exclusão com confirmação) e sheet (tipo filtra Categorias, erro inline mantém o digitado, criação inline, "Salvar e nova" mantém tipo/Conta/Competência).
- [ ] Banco vazio: dá para criar Conta, Categoria e lançar Gasto e Receita só pelo app.
- [ ] Nenhuma aritmética sobre valores; `flutter analyze` e `flutter test` passam.

### 3/5 — Resumo do mês

**Escopo** (seção "Telas: Resumo"):

- Aba Resumo: Balanço Mensal (Receitas, Gastos, Saldo com `sinal` + ícone), Gastos por Categoria com barra proporcional (único uso de `double`, só para largura) e Parcelas Ativas agrupadas por Competência com "A partir do mês corrente" e link ao detalhe.
- Os três relatórios em providers independentes; `RefreshIndicator` invalida os três; estados vazios.
- O link de Parcela Ativa leva a `/parcelamentos/:id`, que nesta fatia pode ser um placeholder "em construção" até a 4.

**Aceite:**

- [ ] Testes de widget: balanço, gastos por categoria, parcelas ativas e o estado vazio do mês.
- [ ] Parcelas Ativas não reage ao seletor de Competência (testado).
- [ ] Lançar uma Transação (fatia 2) atualiza o Resumo sem recarregar manualmente.
- [ ] `flutter analyze` e `flutter test` passam.

### 4/5 — Parcelamentos

**Escopo** (seções "Telas: bottom sheet (Parcelado), Parcelamentos e Detalhe"):

- Alternador "À vista / Parcelado" no sheet (só criação, só Gasto; desabilitado para Receita): valor total, nº de parcelas (inteiro ≥ 2), primeira parcela; `POST /parcelamentos`; sucesso fecha o sheet e navega ao detalhe.
- Aba Parcelamentos: chips Todos/Ativos/Cancelados, linhas e vazio.
- Detalhe `/parcelamentos/:id`: cabeçalho, Parcelas (corrente destacada, passadas esmaecidas), `404` com "Parcelamento não encontrado.".
- Cancelamento com diálogo e prévia calculada no cliente (`comparar` + `competenciaAtual`), mensagem final com os números da API, tratamento de `422 "Parcelamento já cancelado."`.
- Invalidação conforme a tabela da spec; substituir o placeholder da fatia 3.

**Aceite:**

- [ ] Testes de widget: Parcelado desabilitado para Receita; prévia do cancelamento (`removidas`/`preservadas`, caso `removidas = 0`); mensagem final com os números da API; `404` do detalhe.
- [ ] Nenhuma divisão de valor no cliente (sem prévia de parcela).
- [ ] `flutter analyze` e `flutter test` passam.

### 5/5 — Acabamento e teste de integração

**Escopo** (seções "Erros", "Aparência e plataforma", "Testes: Integração" e critério de pronto):

- Revisão de estados vazios e de erro em todas as telas, carregamento sem piscar nas releituras, alvos ≥ 48 dp, `Semantics`, tema escuro e escala de fonte.
- `integration_test` do fluxo único da spec, contra a API real e `controle_gastos_test`; `make e2e-mobile` (recria o banco, sobe a API na 8100, roda o teste com `API_URL`).
- Atualizar `apps/mobile/CLAUDE.md` com o E2E (pré-requisitos, "não rodar junto com `make test` nem `make e2e-web`", traces/logs).

**Aceite:**

- [ ] `flutter analyze`, `flutter test` e `make e2e-mobile` passam em emulador Android e simulador iOS.
- [ ] `make test` e `make lint` (API) e os checks do web continuam passando.
- [ ] Teste manual registrado na issue: app instalado em um aparelho físico no mesmo Wi-Fi da API abre e lança uma Transação.
- [ ] Tema escuro e fonte grande conferidos nas quatro abas.

---

## Como virar issues

1. Criar a issue-mãe "App mobile v1" (label `enhancement`), linkando intent, spec e este plano, como a #10 do web.
2. Criar as cinco issues das fatias com o corpo acima, label `ready-for-agent`, como sub-issues da mãe (`gh issue create --parent`), nomeadas "App mobile v1 (n/5): …".
3. Registrar as dependências (2 depende de 1; 3 e 4 dependem de 2; 4 depois de 3; 5 depende de todas) como bloqueios nativos ou na linha `Blocked by:` no topo do corpo.
4. Cada fatia vai por PR próprio, numa branch/worktree isolada (mesmo fluxo das PRs #20–#22 do web).

---

## Fora do plano

Tudo o que o intent lista como fora de escopo: publicação, hospedagem da API, autenticação, offline, extras de plataforma, tablet/paisagem/web/desktop.
