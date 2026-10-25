# 003 — App Mobile (Flutter) v1

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-24  
**Status:** Rascunho  
**Relação com outros intents:** complementa o [intent 002](002-frontend-web-v1.md) (front-end web), cujo comportamento este app replica; herda do [intent 001](001-controle-de-gastos.md) a API e o usuário único sem autenticação.

---

## Problema

O front-end web (intent 002) resolve o fechamento do mês, mas exige um computador. Os lançamentos acontecem longe da mesa (na fila do caixa, logo após a compra), e o web, mesmo responsivo, não é um app instalado no celular. O resultado é que lançamentos ficam para depois, voltam a depender da memória e o problema original (trabalho manual e pouca visibilidade) reaparece.

---

## Resultado desejado

Um app mobile em Flutter (`apps/mobile`) que consome a mesma API e tem **os mesmos comportamentos do front-end web**, com um único código para Android (celular) e iOS (iPhone). Cobre toda a superfície que a API oferece, e nada além:

1. **Resumo do mês** (aba inicial): Balanço Mensal, Gastos por Categoria e Parcelas Ativas da Competência selecionada.
2. **Transações**: lista da Competência com filtros de tipo, conta e categoria; criar, editar e excluir Transações Avulsas.
3. **Parcelamentos**: criar, listar (filtro de status), ver o detalhe com as Parcelas e cancelar.
4. **Cadastros**: criar e listar Contas e Categorias.

### Comportamento

O intent 002 e a spec 002 são o contrato de **comportamento**; o app adapta apenas o idioma de interação ao celular:

| Web | App |
|---|---|
| Gaveta de "Nova transação" + atalho `n` | Bottom sheet aberto por um botão flutuante (FAB), visível em todas as abas |
| Navegação com 4 destinos | Barra de navegação inferior com os mesmos 4 destinos |
| Competência em `?mes=` na URL | Competência selecionada como estado do app, compartilhada entre Resumo e Transações (setas anterior/próximo e "Hoje"); abre no mês corrente |
| Filtros em `?tipo=`, `?conta=`, `?categoria=` | Filtros em estado local da tela de Transações |
| `localStorage` (`ultima_conta_id`) | Preferência local do app, validada contra a lista de Contas ao ler |
| `router.refresh()` após mutação | Invalidação dos dados lidos, seguida de nova leitura |

Mantidas sem alteração:

- **Competência como eixo.** A UI usa sempre o termo "Competência", exibida por extenso ("outubro de 2026"). Parcelas Ativas não reage ao seletor e traz o rótulo "A partir do mês corrente".
- **Lançamento rápido.** O tipo (gasto/receita) vem primeiro e filtra as Categorias. Conta (última usada) e Competência (selecionada) vêm pré-preenchidas. Um alternador "À vista / Parcelado" exibe os campos de Parcelamento (valor total, nº de parcelas, mês da 1ª Parcela) e fica desabilitado para Receita. A edição de uma Transação Avulsa reaproveita o mesmo bottom sheet.
- **Parcelas.** Aparecem na lista como Gasto comum, com selo "n/N" e link para o Parcelamento. Não têm editar nem excluir. Um Parcelamento cancelado continua visível, com selo "cancelado".
- **Cancelamento.** Exige confirmação explícita mostrando o efeito ("remove N Parcelas futuras; a do mês atual e as passadas ficam"), com a contagem calculada no cliente a partir do detalhe.
- **Primeiro uso.** Com o banco vazio, o formulário permite criar Conta e Categoria inline. Meses sem lançamentos mostram estado vazio explicativo e balanço R$ 0,00.
- **Erros.** `409` e `422` aparecem inline no formulário, com o `detail` da API sem reescrita. Falha de rede ou `5xx` mostra aviso com "Tentar de novo" sem perder o que foi digitado.

---

## Usuários e sistemas afetados

| Ator | Papel |
|---|---|
| Tadeu Wohlers | Único usuário; lança e consulta pelo celular |
| `apps/mobile` | Novo cliente da API (Flutter, Android e iOS) |
| `apps/api` | **Sem mudanças.** O app usa o contrato atual, incluindo os filtros de `GET /transacoes` entregues para o web |
| `apps/web` | Sem mudanças; segue como o cliente de desktop |

---

## Restrições

- **Stack:** Flutter (Dart) em `apps/mobile`, com Material 3 e widgets próprios, sem biblioteca de componentes. Cliente da API escrito à mão sobre `package:http`, com modelos próprios; um teste de contrato contra o `apps/api/openapi.json` pega divergência. Estado com Riverpod e navegação com `go_router`. Escolha final de pacotes e versões na spec.
- **Plataformas:** Android (celular) e iOS (iPhone), em retrato, com versões mínimas padrão do Flutter 3.32 (Android API 24+, iOS 13+). Tema claro e escuro seguindo o sistema; pt-BR fixo, sem i18n; valores em R$. Tablet, paisagem, web e desktop não são alvo.
- **Ambiente (pré-requisito):** Android SDK completo (`cmdline-tools` e licenças aceitas) e Xcode completo com simulador iOS. Hoje o `flutter doctor` acusa os dois como incompletos; o desenvolvimento pode começar no que já funciona (testes e helpers), mas o critério de pronto só fecha com as duas plataformas.
- **Acesso à API:** a API continua só local. O celular físico a alcança pelo **Wi-Fi local**, apontando para o IP do Mac na rede; o emulador Android usa `10.0.2.2` e o simulador iOS usa `localhost`. A URL é configuração de build (`--dart-define=API_URL=...`). O `make dev` da API já escuta em `0.0.0.0:8000`. Como a conexão é HTTP sem TLS na rede local, o app precisa permitir tráfego em texto claro (Android) e acesso à rede local (iOS, com exceção de ATS e aviso de permissão); isso vale só para a configuração de desenvolvimento. CORS não se aplica a app nativo.
- **Dinheiro:** `valor` trafega como string nos dois sentidos, ponta a ponta. A entrada aceita o formato pt-BR (`1.234,56`) e converte para string sem passar por `double`. Formatação de exibição em R$ só na camada de apresentação; nunca soma nem comparação. Os totais vêm sempre dos relatórios da API.
- **Competência:** trafega como `"YYYY-MM"`; o mês corrente é calculado em `America/Sao_Paulo`, nunca pelo fuso do aparelho. Helpers únicos de dinheiro e Competência, com os mesmos contratos e casos de teste da spec 002.
- **Dados:** 100% online; o app não guarda dados da API localmente, só a preferência de última Conta.
- **Vocabulário:** a UI usa os termos do `GLOSSARY.md` (Competência, Parcelamento, Parcela, Transação Avulsa…). "Resumo do mês", "selo", "bottom sheet" e "FAB" são vocabulário de UI e não entram no glossário.
- **Usuário único, sem autenticação**, como nos intents 001 e 002.

---

## Fora de escopo (v1)

- Publicação nas lojas (Play Store e App Store) e TestFlight
- Hospedagem da API, deploy e acesso fora da rede local
- Autenticação e autorização *(para quando a API for hospedada remotamente)*
- Modo offline e sincronização
- Notificações, widgets de tela inicial, biometria, câmera/nota fiscal
- Tablet, paisagem, web e desktop
- Orçamento por categoria e alertas de limite
- Importação de dados das planilhas existentes
- Comparação entre meses
- Editar, renomear ou excluir Conta e Categoria
- Edição de Parcelas individuais (só via cancelamento do Parcelamento)
- Histórico de edições de transações
- Internacionalização e outras moedas
- Geração automática do cliente da API a partir do OpenAPI

---

## Critério de pronto

- `flutter analyze` e `flutter test` passam.
- Os helpers de dinheiro e Competência têm testes unitários com os mesmos casos da spec 002.
- As telas principais têm testes de widget, com a API simulada.
- Um teste de integração (`integration_test`) cobre o fluxo único do web, contra a API real e o banco de teste (`controle_gastos_test`, reaproveitando `recriar_banco_teste.py`): criar Conta e Categoria → lançar Gasto e Receita → lançar um Parcelamento → conferir o Balanço Mensal → cancelar o Parcelamento.
- O app compila e roda no emulador Android e no simulador iOS, e abre e lança uma Transação em um aparelho físico na mesma rede Wi-Fi da API.

---

## Ordem de entrega (fatias verticais)

1. **Casca:** projeto Flutter em `apps/mobile`, ambiente validado (`flutter doctor`), navegação por abas, seletor de Competência, helpers de dinheiro e Competência, cliente da API e comandos `make` (`dev-mobile`, `lint-mobile`, `test-mobile`, `build-mobile`).
2. **Cadastros e Transação Avulsa:** criar, listar, editar e excluir, com criação inline de Conta e Categoria. A partir daqui já dá para lançar no dia a dia.
3. **Resumo do mês:** os três relatórios.
4. **Parcelamentos:** criar, detalhe e cancelar.
5. **Acabamento:** estados vazios, erros, tema e o teste de integração.

Não há fatia de API. O detalhamento em issues fica para o plano.

---

## Decisões tomadas

| # | Questão | Decisão |
|---|---------|---------|
| 1 | Objetivo da v1 | Mesmos comportamentos do web, no celular, para lançar fora da mesa |
| 2 | Framework | Flutter, um código para Android e iOS |
| 3 | "Distribuir" | Compilar e rodar nas duas plataformas (emulador, simulador e aparelho próprio); loja e TestFlight fora de escopo |
| 4 | Acesso à API | Wi-Fi local; URL por `--dart-define`; sem deploy nem autenticação |
| 5 | Paridade | Comportamento idêntico ao web; idioma de interação adaptado (bottom sheet, FAB, barra inferior, Competência como estado) |
| 6 | Extras de plataforma | Nenhum; 100% online |
| 7 | Localização e numeração | `apps/mobile`; intent/spec/plano 003 |
| 8 | Mudanças na API | Nenhuma |
| 9 | Glossário e ADR | Sem alterações no glossário; nenhum ADR por ora |
| 10 | Ambiente | Android SDK e Xcode completos são pré-requisito do critério de pronto |
| 11 | Cliente da API | Manual sobre `package:http`, com teste de contrato contra o `openapi.json` |
| 12 | Estado e navegação | Riverpod e `go_router`; Material 3 sem biblioteca de componentes |
| 13 | Plataformas | Android e iPhone, retrato, claro/escuro, pt-BR; mínimos padrão do Flutter 3.32 |
| 14 | Testes | Unitários nos helpers, widget nas telas, integração com o fluxo do web |
| 15 | Entrega | Cinco fatias verticais, sem fatia de API |

---

## Perguntas em aberto

1. **IP do Mac na rede.** O IP do Mac muda entre redes e reinícios do roteador. Basta passar o IP atual no `--dart-define`, ou vale fixar um IP/hostname (ex.: `.local` via Bonjour)? *(Resolver no Design.)*
   - *Decisão:* —

2. **Acesso fora de casa.** Como lançar longe do Wi-Fi onde o Mac está? *(Fora de escopo; é o motivo do futuro intent de hospedagem da API.)*
   - *Decisão:* —
