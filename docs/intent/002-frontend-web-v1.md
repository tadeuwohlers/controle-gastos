# 002 — Front-end Web v1

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-20  
**Status:** Rascunho  
**Relação com outros intents:** supera a exclusão de "Interface gráfica / frontend" do [intent 001](001-controle-de-gastos.md).

---

## Problema

A API (spec 001) cobre o necessário para controlar gastos, mas o único cliente é o Postman. Lançar transações, conferir o mês e ver o que está comprometido em parcelas exige montar requisições à mão. Na prática o usuário continua dependendo da planilha para o dia a dia, e o problema original (trabalho manual e pouca visibilidade) persiste.

---

## Resultado desejado

Uma aplicação web (Next.js, em `apps/web`) que consome a API existente e permite **fechar um mês inteiro sem abrir a planilha nem o Postman**: lançar tudo, consultar e ver o balanço.

Cobre toda a superfície que a API oferece, e nada além:

1. **Resumo do mês** (tela inicial, `/`): Balanço Mensal, Gastos por Categoria e Parcelas Ativas da Competência selecionada.
2. **Transações** (`/transacoes`): lista da Competência com filtros de tipo, conta e categoria; criar, editar e excluir Transações Avulsas.
3. **Parcelamentos** (`/parcelamentos`, `/parcelamentos/[id]`): criar, listar (filtro de status), ver o detalhe com as Parcelas e cancelar.
4. **Cadastros** (`/cadastros`): criar e listar Contas e Categorias.

### Comportamento

- **Competência como eixo.** Um seletor global de Competência (setas anterior/próximo) abre no mês corrente e vale para Resumo e Transações. Fica na URL (`?mes=2026-10`), para o link ser compartilhável e o botão voltar funcionar. A UI usa sempre o termo "Competência".
- **Lançamento rápido.** O formulário de Transação abre numa gaveta acessível de qualquer tela, com atalho de teclado. O tipo (gasto/receita) vem primeiro e filtra as Categorias. Conta (última usada) e Competência (selecionada) vêm pré-preenchidas. Um alternador "À vista / Parcelado" exibe os campos de Parcelamento (valor total, nº de parcelas, mês da 1ª Parcela). A edição de uma Transação Avulsa reaproveita a mesma gaveta.
- **Parcelas.** Aparecem na lista como Gasto comum, com selo "n/N" e link para o Parcelamento. Não têm editar nem excluir. Um Parcelamento cancelado continua visível, com selo "cancelado".
- **Cancelamento.** Exige confirmação explícita mostrando o efeito ("remove N Parcelas futuras; a do mês atual e as passadas ficam"). A contagem é calculada no cliente a partir do detalhe do Parcelamento.
- **Primeiro uso.** Com o banco vazio, o formulário permite criar Conta e Categoria inline, sem sair da gaveta. Meses sem lançamentos mostram estado vazio explicativo e balanço R$ 0,00.
- **Erros.** `409` e `422` aparecem inline no formulário, com o `detail` da API sem reescrita. Falha de rede ou `5xx` mostra aviso com "Tentar de novo" sem perder o que foi digitado.

---

## Usuários e sistemas afetados

| Ator | Papel |
|---|---|
| Tadeu Wohlers | Único usuário — lança e consulta tudo pela interface |
| `apps/web` | Novo cliente da API (Next.js, App Router, TypeScript, Tailwind) |
| `apps/api` | Ganha filtros opcionais em `GET /transacoes` (ver Restrições) |

---

## Restrições

- **Stack:** a já scaffoldada em `apps/web` (Next.js, TypeScript, Tailwind, npm, cliente `openapi-fetch` gerado do OpenAPI). Sem biblioteca de componentes; só Tailwind e componentes próprios.
- **Mudança mínima na API (pré-requisito):** filtros opcionais e retrocompatíveis `competencia`, `conta_id` e `categoria_id` em `GET /transacoes`, registrados como mudança de spec própria. Nenhuma outra mudança na API: Contas e Categorias seguem só com criar e listar; edição e exclusão só para Transações Avulsas.
- **Dinheiro:** `valor` trafega como string nos dois sentidos. A entrada aceita o formato pt-BR (`1.234,56`) e converte para string sem passar por `number`. `Number` só pode ser usado para formatar a exibição com `Intl` em R$, nunca para somar ou comparar. Os totais vêm sempre dos relatórios da API.
- **Competência:** trafega como `"YYYY-MM"` e é exibida por extenso ("outubro de 2026"). Helpers únicos de dinheiro e Competência em `src/lib`.
- **Dados:** leituras em Server Components; mutações disparadas do navegador direto para a API (CORS já liberado), seguidas de `router.refresh()`. Sem biblioteca de cache na v1; reavaliar se a lentidão aparecer.
- **Vocabulário:** a UI usa os termos do `GLOSSARY.md` (Competência, Parcelamento, Parcela, Transação Avulsa…). "Resumo do mês", "gaveta" e "selo" são vocabulário de UI e não entram no glossário.
- **Plataforma:** desktop primeiro, responsivo e utilizável no celular; tema claro e escuro seguindo o sistema; pt-BR fixo, sem i18n; valores em R$.
- **Usuário único, sem autenticação**, como no intent 001.

---

## Fora de escopo (v1)

- Orçamento por categoria e alertas de limite
- Importação de dados das planilhas existentes
- Comparação entre meses
- Autenticação e autorização *(para quando a API for hospedada remotamente)*
- Deploy em servidor remoto ou nuvem
- Editar, renomear ou excluir Conta e Categoria
- Edição de Parcelas individuais (só via cancelamento do Parcelamento)
- Histórico de edições de transações
- Internacionalização e outras moedas
- Biblioteca de cache de dados (TanStack Query) e atualizações otimistas

---

## Critério de pronto

- `npm run lint` e `npm run build` passam.
- Os helpers de dinheiro e Competência têm testes unitários (Vitest).
- Um teste ponta a ponta (Playwright), contra API e banco de teste, cobre o fluxo: criar Conta e Categoria → lançar Gasto e Receita → lançar um Parcelamento → conferir o Balanço Mensal → cancelar o Parcelamento.

---

## Ordem de entrega (fatias verticais)

1. **API:** filtros opcionais em `GET /transacoes` (pré-requisito).
2. **Casca:** layout, navegação, seletor de Competência na URL, helpers de dinheiro e Competência.
3. **Cadastros e Transação Avulsa:** criar, listar, editar e excluir, com criação inline de Conta e Categoria. A partir daqui já dá para lançar no dia a dia.
4. **Resumo do mês:** os três relatórios.
5. **Parcelamentos:** criar, detalhe e cancelar.
6. **Acabamento:** responsivo, erros, estados vazios e o teste E2E.

O detalhamento em issues fica para o plano.

---

## Decisões tomadas

| # | Questão | Decisão |
|---|---------|---------|
| 1 | Objetivo da v1 | Substituir a planilha no uso diário; fechar um mês sem Postman |
| 2 | Escopo funcional | Toda a superfície da API, nada além |
| 3 | Mudanças na API | Só filtros opcionais em `GET /transacoes` |
| 4 | Eixo de navegação | Competência global, na URL; Resumo como tela inicial |
| 5 | Lançamento | Gaveta única, tipo primeiro, alternador À vista / Parcelado |
| 6 | Dispositivo e visual | Desktop primeiro, responsivo; Tailwind puro; pt-BR; claro e escuro |
| 7 | Parcelas e cancelamento | Parcela só leitura com selo; cancelamento com confirmação e contagem |
| 8 | Dinheiro e Competência | Strings ponta a ponta; sem aritmética no front; helpers únicos |
| 9 | Erros | `detail` da API inline; aviso com retry para rede e `5xx` |
| 10 | Dados | Server Components para leitura; mutação no cliente + `router.refresh()` |
| 11 | Telas | Resumo, Transações, Parcelamentos, Cadastros |
| 12 | Primeiro uso | Criação inline de Conta e Categoria; estados vazios |
| 13 | Testes | Vitest nos helpers + um E2E Playwright do fluxo feliz |
| 14 | Glossário | Sem alterações; a UI usa os termos existentes |
| 15 | ADR | Nenhum por ora |
| 16 | Entrega | Seis fatias verticais, na ordem acima |

---

## Perguntas em aberto

1. **Atalho de teclado da gaveta.** Qual combinação abre "Nova transação" sem conflitar com o navegador? *(Resolver no Design.)*
   - *Decisão:* —

2. **Banco do teste E2E.** O Playwright sobe um Postgres descartável (docker compose) ou usa o mesmo `make db` com um banco de teste separado? *(Resolver no plano da fatia 6.)*
   - *Decisão:* —
