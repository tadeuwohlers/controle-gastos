# Spec 001 — Controle de Gastos Pessoal

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-17  
**Status:** Aprovado  
**Intent:** [001-controle-de-gastos](../intent/001-controle-de-gastos.md)

---

## Decisões tomadas

| # | Questão | Decisão |
|---|---------|---------|
| 1 | Valor do Parcelamento e arredondamento | O usuário informa o **valor total**. O sistema divide: `parcela = floor(total * 100 / n) / 100`; o centavo residual vai para a **última parcela**. |
| 2 | Conta e Categoria do Parcelamento | Informadas no Parcelamento; **herdadas** por todas as suas Parcelas. |
| 3 | Editar / Excluir Transações | Transação avulsa (Gasto ou Receita não vinculada a Parcelamento): pode ser editada (PUT/PATCH) e excluída (DELETE). Parcelas só se alteram via operações no Parcelamento (cancelamento). |
| 4 | Operações em Conta / Categoria | MVP suporta apenas **criar** e **listar**. Renomear, excluir e desativar ficam fora. |
| 5 | Fuso horário | Todas as datas são armazenadas como `DATE` (sem hora). "Hoje" é sempre calculado em `America/Sao_Paulo`. Testes injetam uma dependência `get_today()` para controlar a data. |
| 6 | Moeda, filtros e paginação | Apenas BRL. Listagem de Transações é simples, sem paginação. Filtros (mês, conta, categoria) só aparecem nos endpoints de relatório. |

---

## Modelo de Domínio

### Conta

```
contas
  id          SERIAL PRIMARY KEY
  nome        VARCHAR(100) NOT NULL UNIQUE
  criada_em   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
```

### Categoria

```
categorias
  id          SERIAL PRIMARY KEY
  nome        VARCHAR(100) NOT NULL UNIQUE
  tipo        VARCHAR(7)   NOT NULL CHECK (tipo IN ('gasto', 'receita'))
  criada_em   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
```

### Transação

Uma Transação é ou um Gasto avulso / Receita, ou uma Parcela gerada por Parcelamento.

```
transacoes
  id              SERIAL PRIMARY KEY
  tipo            VARCHAR(7)     NOT NULL CHECK (tipo IN ('gasto', 'receita'))
  valor           DECIMAL(12, 2) NOT NULL CHECK (valor > 0)
  descricao       VARCHAR(255)   NOT NULL
  competencia     DATE           NOT NULL   -- armazenado como 1º dia do mês (YYYY-MM-01)
  conta_id        INTEGER        NOT NULL REFERENCES contas(id)
  categoria_id    INTEGER        NOT NULL REFERENCES categorias(id)
  parcelamento_id INTEGER        REFERENCES parcelamentos(id)  -- NULL = avulsa
  numero_parcela  INTEGER        CHECK (numero_parcela >= 1)   -- NULL = avulsa
  criada_em       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
  atualizada_em   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()

  CONSTRAINT chk_parcela_consistente
    CHECK (
      (parcelamento_id IS NULL AND numero_parcela IS NULL) OR
      (parcelamento_id IS NOT NULL AND numero_parcela IS NOT NULL)
    )
  UNIQUE (parcelamento_id, numero_parcela)
```

**Invariante:** `categoria.tipo` deve corresponder a `transacao.tipo`.

### Parcelamento

```
parcelamentos
  id              SERIAL PRIMARY KEY
  descricao       VARCHAR(255)   NOT NULL
  valor_total     DECIMAL(12, 2) NOT NULL CHECK (valor_total > 0)
  num_parcelas    INTEGER        NOT NULL CHECK (num_parcelas >= 2)
  primeira_parcela DATE          NOT NULL   -- armazenado como 1º dia do mês
  conta_id        INTEGER        NOT NULL REFERENCES contas(id)
  categoria_id    INTEGER        NOT NULL REFERENCES categorias(id)
  status          VARCHAR(9)     NOT NULL DEFAULT 'ativo' CHECK (status IN ('ativo', 'cancelado'))
  criado_em       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
  atualizado_em   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
```

**Invariante:** `categoria.tipo` deve ser `'gasto'`.

---

## Algoritmo de Parcelamento

### Criação

Dado `valor_total V`, `num_parcelas N`, e `primeira_parcela P` (normalizada para o 1º dia do mês):

```
parcela_base = floor(V * 100 / N) / 100          # trunca para 2 casas
soma_base    = parcela_base * (N - 1)
ultima_parcela = round(V - soma_base, 2)          # absorve o resíduo

Para i in 1..N:
    valor_i       = parcela_base  se i < N
                    ultima_parcela se i == N
    competencia_i = P + (i - 1) meses             # 1º dia de cada mês
    Inserir Transação(tipo='gasto', valor=valor_i, competencia=competencia_i,
                      conta_id=parcelamento.conta_id,
                      categoria_id=parcelamento.categoria_id,
                      parcelamento_id=parcelamento.id,
                      numero_parcela=i)
```

**Garantia:** `sum(valor_i for i in 1..N) == V` (sem drift de arredondamento).

### Cancelamento

Dado `parcelamento_id` e `hoje` (em `America/Sao_Paulo`):

```
mes_corrente = date(hoje.year, hoje.month, 1)

DELETE FROM transacoes
 WHERE parcelamento_id = $id
   AND competencia > mes_corrente     -- estritamente futuro

UPDATE parcelamentos SET status = 'cancelado' WHERE id = $id
```

Parcelas com `competencia <= mes_corrente` são preservadas intactas.

---

## REST API

### Convenções

- Base path: `/api/v1`
- Content-Type: `application/json`
- Competência enviada como `"YYYY-MM"` (ex: `"2026-10"`); armazenada internamente como `YYYY-MM-01`.
- Erros seguem o formato `{"detail": "<mensagem>"}` (padrão FastAPI).
- IDs inexistentes retornam `404`.
- Violações de regra de negócio retornam `422` com `detail` descritivo.

---

### Contas

#### `POST /api/v1/contas`

Cria uma Conta.

**Body:**
```json
{ "nome": "Nubank" }
```

**Response 201:**
```json
{ "id": 1, "nome": "Nubank", "criada_em": "2026-10-17T12:00:00Z" }
```

**Erros:**
- `422` — `nome` ausente ou em branco.
- `409` — `nome` já existe.

---

#### `GET /api/v1/contas`

Lista todas as Contas, ordenadas por `nome`.

**Response 200:**
```json
[{ "id": 1, "nome": "Nubank", "criada_em": "2026-10-17T12:00:00Z" }]
```

---

### Categorias

#### `POST /api/v1/categorias`

Cria uma Categoria.

**Body:**
```json
{ "nome": "Alimentação", "tipo": "gasto" }
```

**Response 201:**
```json
{ "id": 1, "nome": "Alimentação", "tipo": "gasto", "criada_em": "2026-10-17T12:00:00Z" }
```

**Erros:**
- `422` — `nome` ausente/em branco; `tipo` fora de `['gasto', 'receita']`.
- `409` — `nome` já existe.

---

#### `GET /api/v1/categorias`

Lista todas as Categorias. Query param opcional: `?tipo=gasto` ou `?tipo=receita`.

**Response 200:**
```json
[{ "id": 1, "nome": "Alimentação", "tipo": "gasto", "criada_em": "..." }]
```

---

### Transações

#### `POST /api/v1/transacoes`

Cria uma Transação avulsa (Gasto ou Receita).

**Body:**
```json
{
  "tipo": "gasto",
  "valor": 49.90,
  "descricao": "Supermercado",
  "competencia": "2026-10",
  "conta_id": 1,
  "categoria_id": 1
}
```

**Response 201:**
```json
{
  "id": 10,
  "tipo": "gasto",
  "valor": "49.90",
  "descricao": "Supermercado",
  "competencia": "2026-10",
  "conta_id": 1,
  "categoria_id": 1,
  "parcelamento_id": null,
  "numero_parcela": null,
  "criada_em": "2026-10-17T12:00:00Z",
  "atualizada_em": "2026-10-17T12:00:00Z"
}
```

**Erros:**
- `422` — campo obrigatório ausente; `valor <= 0`; `competencia` inválida; `categoria.tipo != transacao.tipo`.
- `404` — `conta_id` ou `categoria_id` inexistente.

---

#### `GET /api/v1/transacoes`

Lista todas as Transações (avulsas e Parcelas), ordenadas por `competencia DESC`, depois `id DESC`. Sem paginação no MVP.

**Response 200:** array de objetos com os mesmos campos do POST 201.

---

#### `GET /api/v1/transacoes/{id}`

Retorna uma Transação pelo ID.

---

#### `PUT /api/v1/transacoes/{id}`

Substitui todos os campos editáveis de uma Transação **avulsa**.

**Body:** mesmos campos do POST (exceto `tipo`, que não pode ser alterado).

**Erros:**
- `404` — ID inexistente.
- `422` — Transação pertence a um Parcelamento (`parcelamento_id IS NOT NULL`). Mensagem: `"Parcelas só podem ser alteradas via Parcelamento."`.
- `422` — regras de negócio equivalentes ao POST.

---

#### `PATCH /api/v1/transacoes/{id}`

Atualiza campos parciais de uma Transação **avulsa** (mesmas restrições do PUT).

**Body:** subconjunto dos campos editáveis.

---

#### `DELETE /api/v1/transacoes/{id}`

Exclui uma Transação **avulsa**.

**Response 204** (sem corpo).

**Erros:**
- `404` — ID inexistente.
- `422` — Transação pertence a um Parcelamento. Mensagem: `"Parcelas só podem ser excluídas via cancelamento do Parcelamento."`.

---

### Parcelamentos

#### `POST /api/v1/parcelamentos`

Cria um Parcelamento e gera automaticamente todas as Parcelas.

**Body:**
```json
{
  "descricao": "Notebook",
  "valor_total": 3600.00,
  "num_parcelas": 12,
  "primeira_parcela": "2026-10",
  "conta_id": 1,
  "categoria_id": 2
}
```

**Response 201:**
```json
{
  "id": 5,
  "descricao": "Notebook",
  "valor_total": "3600.00",
  "num_parcelas": 12,
  "primeira_parcela": "2026-10",
  "conta_id": 1,
  "categoria_id": 2,
  "status": "ativo",
  "parcelas": [
    { "id": 20, "numero_parcela": 1, "competencia": "2026-10", "valor": "300.00" },
    ...
    { "id": 31, "numero_parcela": 12, "competencia": "2027-09", "valor": "300.00" }
  ],
  "criado_em": "2026-10-17T12:00:00Z"
}
```

> **Decisão de UX:** o POST retorna o array completo de `parcelas` para que o cliente possa exibir o calendário de vencimentos imediatamente, sem uma segunda requisição ao `GET /parcelamentos/{id}`.

**Erros:**
- `422` — `num_parcelas < 2`; `valor_total <= 0`; `categoria.tipo != 'gasto'`.
- `404` — `conta_id` ou `categoria_id` inexistente.

---

#### `GET /api/v1/parcelamentos`

Lista todos os Parcelamentos. Query param opcional: `?status=ativo` ou `?status=cancelado`.

**Response 200:** array de objetos sem o campo `parcelas` (para economizar payload).

---

#### `GET /api/v1/parcelamentos/{id}`

Retorna um Parcelamento com todas as suas Parcelas.

---

#### `POST /api/v1/parcelamentos/{id}/cancelar`

Cancela um Parcelamento ativo: remove Parcelas com competência estritamente posterior ao mês corrente (`America/Sao_Paulo`) e muda status para `cancelado`.

**Body:** vazio.

**Response 200:**
```json
{
  "id": 5,
  "status": "cancelado",
  "parcelas_removidas": 8,
  "parcelas_preservadas": 4
}
```

**Erros:**
- `404` — ID inexistente.
- `422` — Parcelamento já está `cancelado`. Mensagem: `"Parcelamento já cancelado."`.

---

### Relatórios

#### `GET /api/v1/relatorios/balanco-mensal`

Retorna o balanço de um mês: total de Receitas, total de Gastos e saldo.

Query param opcional: `?competencia=2026-10`. Se omitido, usa o mês corrente (`America/Sao_Paulo`).

**Response 200:**
```json
{
  "competencia": "2026-10",
  "total_receitas": "5000.00",
  "total_gastos": "3200.00",
  "saldo": "1800.00"
}
```

**Erros:**
- `422` — `competencia` informada mas inválida (formato fora de `YYYY-MM`).

---

#### `GET /api/v1/relatorios/gastos-por-categoria`

Retorna o breakdown de Gastos por Categoria em um mês.

Query param opcional: `?competencia=2026-10`. Se omitido, usa o mês corrente (`America/Sao_Paulo`).

**Response 200:**
```json
{
  "competencia": "2026-10",
  "itens": [
    { "categoria_id": 1, "categoria_nome": "Alimentação", "total": "1200.00" },
    { "categoria_id": 2, "categoria_nome": "Tecnologia", "total": "300.00" }
  ]
}
```

---

#### `GET /api/v1/relatorios/parcelas-ativas`

Lista todas as Parcelas de Parcelamentos `ativo` cuja competência é igual ou posterior ao mês corrente (`America/Sao_Paulo`), ordenadas por `competencia ASC`.

**Response 200:**
```json
[
  {
    "transacao_id": 20,
    "parcelamento_id": 5,
    "parcelamento_descricao": "Notebook",
    "numero_parcela": 1,
    "num_parcelas_total": 12,
    "competencia": "2026-10",
    "valor": "300.00",
    "conta_id": 1,
    "conta_nome": "Nubank",
    "categoria_id": 2,
    "categoria_nome": "Tecnologia"
  }
]
```

---

## Validações e Casos de Erro

| Situação | Status | Mensagem |
|----------|--------|----------|
| Campo obrigatório ausente | 422 | Padrão Pydantic |
| `valor <= 0` | 422 | `"valor deve ser maior que zero."` |
| `num_parcelas < 2` | 422 | `"num_parcelas deve ser pelo menos 2."` |
| `conta_id` inexistente | 404 | `"Conta não encontrada."` |
| `categoria_id` inexistente | 404 | `"Categoria não encontrada."` |
| `categoria.tipo` incompatível com `transacao.tipo` | 422 | `"Categoria do tipo '{tipo}' não pode ser usada em transação do tipo '{tipo}'."` |
| `categoria.tipo != 'gasto'` em Parcelamento | 422 | `"Parcelamentos só aceitam categorias do tipo 'gasto'."` |
| Nome de Conta já existe | 409 | `"Já existe uma Conta com esse nome."` |
| Nome de Categoria já existe | 409 | `"Já existe uma Categoria com esse nome."` |
| Tentar editar/excluir Parcela diretamente | 422 | `"Parcelas só podem ser alteradas via Parcelamento."` |
| Cancelar Parcelamento já cancelado | 422 | `"Parcelamento já cancelado."` |
| `competencia` fora do formato `YYYY-MM` | 422 | `"competencia deve estar no formato YYYY-MM."` |

---

## Fora de escopo (MVP)

- Renomear, excluir ou desativar Contas e Categorias.
- Excluir Parcelamento (apenas cancelamento é suportado).
- Paginação na listagem de Transações.
- Filtros por conta/categoria fora dos endpoints de relatório.
- Suporte a moedas além de BRL.

---

## Notas de Implementação

- **`get_today()`**: função injetável (FastAPI `Depends`) que retorna `datetime.now(ZoneInfo("America/Sao_Paulo")).date()`. Testes sobrescrevem via `app.dependency_overrides`.
- **`competencia` no banco**: sempre `YYYY-MM-01`; na API, serializado/deserializado como `"YYYY-MM"`.
- **`valor` no banco**: `DECIMAL(12, 2)`; na API, retornado como string para evitar perda de precisão em JSON.
- **`tipo` como Enum**: tanto em `transacoes` quanto em `categorias`, o campo `tipo` deve ser modelado como `StrEnum` (Python) / `Literal` (Pydantic), não como string livre. Valores válidos: `'gasto'` e `'receita'`. O `CHECK` no banco é a segunda linha de defesa.
- **Unicidade de Parcela**: índice único em `(parcelamento_id, numero_parcela)` — refletido no schema da tabela `transacoes` acima.
- **Operação atômica**: criação de Parcelamento (INSERT parcelamento + N INSERTs transacoes) ocorre numa única transação de banco. Se qualquer INSERT falhar, tudo é revertido.
