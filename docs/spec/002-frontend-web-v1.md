# Spec 002 — Front-end Web v1

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-20  
**Status:** Rascunho  
**Intent:** [002-frontend-web-v1](../intent/002-frontend-web-v1.md)  
**Depende de:** [Spec 001](001-controle-de-gastos.md) (API)

---

## Decisões tomadas

As decisões 1–16 estão no intent. Esta spec fecha o que o intent deixou em aberto ou implícito:

| # | Questão | Decisão |
|---|---------|---------|
| 1 | Atalho da gaveta "Nova transação" (pergunta em aberto 1 do intent) | Tecla `n`, sem modificadores, ativa apenas quando o foco não está em `input`, `textarea`, `select` nem `[contenteditable]`. Evita conflito com atalhos do navegador. Também há um botão visível. |
| 2 | Banco do E2E (pergunta em aberto 2) | Banco separado `controle_gastos_test` no mesmo Postgres do `make db`. A API de teste sobe com `DATABASE_URL` apontando para ele; o E2E o recria (drop/migrate) antes de rodar. Sem segundo container. |
| 3 | Filtro por tipo na lista de Transações | Feito **no cliente**. A API filtra só por `competencia`, `conta_id` e `categoria_id` (intent, Q3); a lista de um mês é pequena. |
| 4 | Parcelas Ativas e a Competência selecionada | O relatório `parcelas-ativas` **não aceita Competência**: sempre lista do mês corrente em diante (spec 001). No Resumo ele aparece com o rótulo "A partir do mês corrente" e **não reage ao seletor**. |
| 5 | Mês "corrente" no cliente | Calculado com `Intl.DateTimeFormat` em `America/Sao_Paulo`, igual ao servidor (spec 001, decisão 5), nunca pelo fuso do navegador. |
| 6 | Parcelado só para Gasto | O alternador "Parcelado" fica desabilitado quando o tipo é Receita (a API retorna 422 para categoria que não é de gasto). |
| 7 | Prévia de valor da parcela | Não há. Dividir o total exigiria aritmética no cliente (intent, Restrições). O valor de cada Parcela só aparece depois da criação, vindo da API. |
| 8 | Formato do `detail` de erro | Ver [Erros](#erros): o `detail` pode ser string ou lista de objetos; um normalizador único produz a mensagem. |
| 9 | Persistência de "última Conta" | `localStorage` (`ultima_conta_id`), validado contra a lista de Contas ao ler. Falha de leitura é ignorada. |

---

## Mudança na API (fatia 1)

### `GET /api/v1/transacoes`

Passa a aceitar query params **opcionais**. Sem nenhum, o comportamento é idêntico ao atual.

| Param | Tipo | Efeito |
|-------|------|--------|
| `competencia` | `YYYY-MM` | Só Transações da Competência |
| `conta_id` | int | Só da Conta |
| `categoria_id` | int | Só da Categoria |

Filtros combinam com `AND`. Ordenação inalterada (`competencia DESC`, `id DESC`).

**Erros:**
- `422` — `competencia` fora do formato, com a mesma mensagem dos relatórios: `"competencia deve estar no formato YYYY-MM."`.
- `conta_id` ou `categoria_id` inexistente **não** gera `404`: devolve lista vazia.

Depois da mudança, regenerar o cliente: `npm run gen:api` em `apps/web` (e commitar `openapi.json` e `schema.d.ts` junto). Atualizar a spec 001 (seções `GET /transacoes` e "Fora de escopo") para refletir os filtros.

---

## Arquitetura do front-end

### Rotas

| Rota | Tipo | Conteúdo |
|------|------|----------|
| `/` | Server Component | Resumo do mês |
| `/transacoes` | Server Component | Lista da Competência |
| `/parcelamentos` | Server Component | Lista de Parcelamentos (`?status=`) |
| `/parcelamentos/[id]` | Server Component | Detalhe e Parcelas |
| `/cadastros` | Server Component | Contas e Categorias |

Parâmetros de URL: `?mes=YYYY-MM` (Resumo e Transações), `?status=ativo|cancelado` (Parcelamentos), `?tipo=`, `?conta=`, `?categoria=` (Transações). Valor inválido em qualquer um é **ignorado** (cai no padrão: mês corrente, sem filtro), nunca gera erro nem tela em branco.

### Estrutura de `src/`

```
src/
  app/
    layout.tsx              # shell: navegação, seletor de Competência, gaveta, atalho
    page.tsx                # Resumo
    transacoes/page.tsx
    parcelamentos/page.tsx
    parcelamentos/[id]/page.tsx
    cadastros/page.tsx
  components/
    competencia-picker.tsx  # client: setas + atualiza ?mes=
    transacao-drawer.tsx    # client: gaveta de criar/editar (contexto + <dialog>)
    transacao-form.tsx      # client
    transacoes-list.tsx
    confirm-dialog.tsx      # client
    erro-inline.tsx
    estado-vazio.tsx
  lib/
    api/                    # client.ts, schema.d.ts (já existem)
    dinheiro.ts             # parseValorBR, formatBRL, sinal
    competencia.ts          # competenciaAtual, shift, format, valida, compara
    erros.ts                # extrairMensagem(error)
    dados.ts                # leituras server-side (contas, categorias, etc.)
```

### Dados

- **Leitura:** Server Components chamam a API com o cliente `openapi-fetch` existente. Páginas dinâmicas (sem cache de dados): o dado precisa refletir a mutação feita há segundos. Consultar `node_modules/next/dist/docs/` antes de escolher a opção de rendering, pois esta versão do Next tem mudanças (ver `apps/web/AGENTS.md`).
- **Mutação:** componentes cliente chamam a API direto do navegador (CORS já liberado para `localhost:3000`) e, em sucesso, executam `router.refresh()`.
- **Contas e Categorias** são lidas em toda tela que mostra nomes (listas trazem só ids). A lista é pequena; sem cache.
- Falha de leitura no servidor mostra o estado de erro da rota (`error.tsx`) com "Tentar de novo"; a navegação continua utilizável.

---

## Helpers

### `lib/dinheiro.ts`

Nenhuma função faz aritmética sobre valores.

| Função | Contrato |
|--------|----------|
| `parseValorBR(entrada: string): string \| null` | Converte `"1.234,56"` → `"1234.56"`, `"49,9"` → `"49.90"`, `"49"` → `"49.00"`. Aceita `.` como milhar e `,` como decimal. Retorna `null` se: vazio, mais de 2 casas decimais, mais de 10 dígitos inteiros (limite de `DECIMAL(12,2)`), caracteres inválidos, ou valor zero. Valor negativo é inválido (a API exige `> 0`). Operação puramente textual. |
| `formatBRL(valor: string): string` | `"1234.56"` → `"R$ 1.234,56"`; `"-100.00"` → `"-R$ 100,00"`. `Number` só pode ser usado aqui, para alimentar `Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" })`. |
| `sinal(valor: string): "positivo" \| "negativo" \| "zero"` | Decide pela forma textual (prefixo `-`, ou só zeros), usado para colorir o saldo. |

### `lib/competencia.ts`

| Função | Contrato |
|--------|----------|
| `competenciaAtual(): string` | `"YYYY-MM"` do mês corrente em `America/Sao_Paulo`. |
| `valida(c: string): boolean` | Mês entre `01` e `12`, ano com 4 dígitos. |
| `deslocar(c: string, n: number): string` | `deslocar("2026-12", 1)` → `"2027-01"`. |
| `formatar(c: string): string` | `"2026-10"` → `"outubro de 2026"`. |
| `comparar(a, b): -1 \| 0 \| 1` | Ordem cronológica (comparação textual basta no formato `YYYY-MM`). |

### `lib/erros.ts`

`extrairMensagem(error: unknown): string` — ver abaixo.

---

## Telas

### Shell (todas as telas)

- Navegação com 4 destinos (Resumo, Transações, Parcelamentos, Cadastros). Em telas estreitas, vira barra inferior ou menu.
- Seletor de Competência visível em Resumo e Transações: seta anterior, rótulo `formatar(mes)`, seta próxima, e um botão "Hoje" quando o mês selecionado não é o corrente. Atualiza `?mes=` com `router.replace`, preservando os demais params.
- Botão "Nova transação" sempre visível e atalho `n`.

### Resumo (`/`)

Dados (chamados em paralelo): `balanco-mensal?competencia=`, `gastos-por-categoria?competencia=`, `parcelas-ativas`.

1. **Balanço Mensal:** três valores: Receitas, Gastos e Saldo. Saldo colorido por `sinal` (verde/vermelho/neutro) além de ícone ou sinal textual, para não depender só de cor.
2. **Gastos por Categoria:** lista ordenada como vem da API (maior total primeiro), com barra proporcional. A proporção da barra é o único cálculo numérico permitido no front, e só para largura visual (`Number` do total da linha sobre o do maior item); nunca é exibida como valor.
3. **Parcelas Ativas** ("A partir do mês corrente"): agrupadas por `competencia`, cada linha com descrição, `n/N`, conta, categoria e valor, com link para `/parcelamentos/[parcelamento_id]`.

Vazios: mês sem lançamentos mostra R$ 0,00 no balanço, "Nenhum gasto neste mês." em Gastos por Categoria e "Nenhuma parcela a vencer." em Parcelas Ativas.

### Transações (`/transacoes`)

- Dados: `GET /transacoes?competencia=<mes>[&conta_id=][&categoria_id=]` + Contas + Categorias. Filtro de tipo aplicado no cliente.
- Linha: descrição, categoria, conta, valor com sinal visual por tipo (gasto/receita), selo `n/N` se for Parcela (link para o Parcelamento).
- **Transação Avulsa:** menu com Editar (abre a gaveta) e Excluir (diálogo de confirmação, depois `DELETE`).
- **Parcela:** sem Editar nem Excluir.
- Vazio: "Nenhuma transação neste mês." + botão "Nova transação".

### Gaveta de Transação (criar e editar)

Componente cliente montado no layout, aberto por contexto.

**Campos (criar):** Tipo (Gasto/Receita, primeiro e obrigatório), Valor, Descrição, Competência (padrão: mês selecionado, ou o corrente fora das telas com seletor), Conta (padrão: última usada), Categoria (filtrada pelo tipo).

**Alternador À vista / Parcelado** (só criação, só tipo Gasto): em Parcelado, "Valor" vira "Valor total" e aparecem "Número de parcelas" (inteiro ≥ 2) e "Primeira parcela" (Competência, no lugar de Competência). Envia `POST /parcelamentos`; no sucesso navega para `/parcelamentos/[id]`.

**Editar:** só Avulsa. Tipo exibido e não editável (a API não o aceita). Envia `PUT /transacoes/{id}` com todos os campos editáveis.

**Botões:** "Salvar" (fecha) e, só na criação de Avulsa, "Salvar e nova" (mantém tipo, Conta e Competência; limpa valor e descrição; foco no valor).

**Criação inline** (intent, fatia 3): se não há Conta, ou não há Categoria do tipo escolhido, o campo correspondente mostra "Criar conta" / "Criar categoria". O mini-formulário (nome, e tipo já definido para Categoria) usa `POST /contas` ou `POST /categorias` e seleciona o item recém-criado, sem fechar a gaveta.

**Validação cliente (antes de enviar):** valor via `parseValorBR` (null = erro no campo), descrição não vazia, campos de seleção preenchidos, parcelas inteiro ≥ 2. A API continua sendo a fonte da verdade; as mensagens dela são exibidas se o cliente deixar passar algo.

### Parcelamentos (`/parcelamentos`)

- Dados: `GET /parcelamentos[?status=]` + Contas + Categorias. Filtro de status por abas ou chips: Todos, Ativos, Cancelados.
- Linha: descrição, valor total, `N×`, primeira parcela, conta, categoria, selo de status. Link para o detalhe.
- Vazio: "Nenhum parcelamento." com botão "Nova transação" (o Parcelamento nasce na gaveta).

### Detalhe do Parcelamento (`/parcelamentos/[id]`)

- Dados: `GET /parcelamentos/{id}` + Contas + Categorias. `404` mostra "Parcelamento não encontrado." com link de volta.
- Cabeçalho: descrição, valor total, conta, categoria, status.
- Tabela de Parcelas: `n/N`, Competência, valor. A do mês corrente fica destacada; as passadas, esmaecidas.
- **Cancelar** (só se `ativo`): abre diálogo com o efeito. Prévia calculada no cliente a partir da resposta do detalhe, sem aritmética de valor:
  - removidas = Parcelas com `comparar(competencia, competenciaAtual()) > 0`;
  - preservadas = as demais.
  - Texto: "Remove {removidas} parcela(s) futura(s); {preservadas} (a do mês atual e as passadas) permanecem." Se removidas = 0, avisa que apenas o status muda.
- Após `POST /parcelamentos/{id}/cancelar`, a página recarrega e um aviso mostra os números **retornados pela API** (`parcelas_removidas`, `parcelas_preservadas`). Se divergirem da prévia (fuso, virada de mês), prevalece o da API.
- `422 "Parcelamento já cancelado."` (outra aba cancelou antes): mostra a mensagem e recarrega.

### Cadastros (`/cadastros`)

- Duas seções, Contas e Categorias, cada uma com lista e formulário de criação.
- Categorias agrupadas por tipo (Gasto, Receita); o formulário pede nome e tipo.
- Sem renomear, excluir ou desativar (spec 001, decisão 4).
- Vazio: mensagem explicando para que servem.

---

## Erros

A API devolve dois formatos em `detail`:

| Origem | Forma |
|--------|-------|
| `HTTPException` (404, 409, 422 de regra de negócio) | `{"detail": "mensagem"}` |
| Validação do Pydantic (422) | `{"detail": [{"loc": [...], "msg": "Value error, mensagem", ...}]}` |

`extrairMensagem(error)`:
1. `detail` string → a própria string.
2. `detail` lista → mensagens `msg` unidas por quebra de linha, removendo o prefixo `"Value error, "` que o Pydantic adiciona às nossas validações.
3. Qualquer outra coisa → `"Algo deu errado. Tente de novo."`.

Essa é a única normalização feita sobre o `detail`; não há tradução ou reescrita de mensagens.

**Onde aparece:**
- Erros de formulário (`409`, `422`, `404` de Conta/Categoria inexistente): inline, no topo do formulário, via `erro-inline`. Os dados digitados são mantidos.
- Falha de rede ou `5xx` numa mutação: aviso com "Tentar de novo" que reenvia o mesmo payload, sem perder o formulário.
- Falha de leitura no servidor: `error.tsx` da rota.

---

## Responsividade e tema

- Desktop primeiro; abaixo de `md` a navegação vira inferior e tabelas viram cartões empilhados. A gaveta ocupa a tela inteira em telas estreitas.
- Tema claro/escuro via `prefers-color-scheme` (já suportado no Tailwind scaffoldado). Sem alternador manual.
- Idioma fixo pt-BR: `<html lang="pt-BR">`; textos em português; valores com `formatBRL`; datas por extenso via `formatar`.
- Acessibilidade mínima: a gaveta e os diálogos usam `<dialog>` (foco preso, `Esc` fecha); controles têm rótulo; estado nunca depende só de cor (saldo e tipo têm sinal ou ícone).

---

## Testes

### Unitários (Vitest, `apps/web`)

Adicionar `vitest` e o script `npm run test`. Cobrir:

- `parseValorBR`: `"1.234,56"`, `"49,9"`, `"49"`, `"0,00"` (null), `"-5"` (null), `"1,234"` (null; 3 casas), `"12345678901"` (null; excede 10 dígitos), `""`, `"abc"`.
- `formatBRL` e `sinal`, incluindo negativo e zero.
- `competencia.ts`: `deslocar` na virada de ano, `valida`, `formatar`, `competenciaAtual` com relógio simulado perto da meia-noite e do fim do mês (fuso `America/Sao_Paulo` vs UTC).
- `extrairMensagem`: string, lista com prefixo `"Value error, "`, corpo inesperado.

### API (pytest, `apps/api`)

Em `GET /transacoes`: sem filtro (inalterado), cada filtro isolado, filtros combinados, `competencia` inválida (422), `conta_id` inexistente (lista vazia).

### Ponta a ponta (Playwright, `apps/web`)

Contra a API real e o banco `controle_gastos_test`, recriado antes da suíte. Um fluxo:

1. Banco vazio → abrir a gaveta com `n` e criar Conta e Categoria de Gasto inline, depois lançar um Gasto.
2. Criar Categoria de Receita inline e lançar uma Receita.
3. Lançar um Parcelamento (ex.: R$ 100,00 em 3×, primeira parcela no mês corrente) e conferir as 3 Parcelas, incluindo que a última absorve o centavo (33,33 / 33,33 / 33,34).
4. Conferir no Resumo o Balanço Mensal (Receitas, Gastos incluindo a 1ª parcela, Saldo) e os Gastos por Categoria.
5. Cancelar o Parcelamento: o diálogo mostra "2 parcelas futuras removidas"; depois do cancelamento, a lista do mês corrente mantém a 1ª parcela e os meses seguintes não têm mais as demais.

### Critério de pronto

`npm run lint`, `npm run build`, `npm run test` e o E2E passam; `make test` e `make lint` (API) passam.

---

## Fatias de entrega

Cada fatia é uma issue (`ready-for-agent`) e termina testável. A ordem vem do intent.

1. **API: filtros em `GET /transacoes`.** Endpoint, testes pytest, atualização da spec 001, regeneração do `schema.d.ts`.
2. **Casca.** Layout, navegação, seletor de Competência com `?mes=`, `lib/dinheiro.ts` e `lib/competencia.ts` com testes Vitest, `lib/erros.ts`, `error.tsx`, tema e `lang`.
3. **Cadastros e Transação Avulsa.** `/cadastros`, `/transacoes`, gaveta (criar e editar, "Salvar e nova", atalho `n`, criação inline), exclusão com confirmação. Ao final, já é possível lançar no dia a dia.
4. **Resumo do mês.** Os três relatórios, incluindo vazios.
5. **Parcelamentos.** Alternador Parcelado na gaveta, `/parcelamentos`, detalhe, cancelamento com prévia e confirmação. `ParcelaAtiva` com link para o detalhe.
6. **Acabamento.** Responsivo, estados de erro e vazio revisados, acessibilidade mínima, E2E Playwright.

---

## Notas de implementação

- `valor` e demais `Decimal` chegam como string e são enviados como string; `POST` aceita string numérica (Pydantic `Decimal`). Nunca `parseFloat` em valor.
- `competencia` e `primeira_parcela` trafegam como `"YYYY-MM"`.
- O cliente `openapi-fetch` usa só a origem como `baseUrl` (`src/lib/api/client.ts`) porque os paths do schema já incluem `/api/v1`.
- `NEXT_PUBLIC_API_URL` é a única variável de ambiente; documentada em `.env.example`.
- Todo texto de UI usa os termos do `GLOSSARY.md`: Competência, Parcelamento, Parcela, Transação Avulsa, Balanço Mensal, Conta, Categoria.
