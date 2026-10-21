# Plano de Implementação — Spec 001 Controle de Gastos

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-17  
**Spec:** [spec/001-controle-de-gastos.md](../spec/001-controle-de-gastos.md)

---

## Context

Projeto greenfield. O scaffold existe (diretórios, dependências, pyproject.toml) mas
zero código foi escrito além de stubs vazios. A spec 001 está aprovada e define 4
entidades, ~14 endpoints REST e 3 endpoints de relatório. Este plano organiza a
implementação em ondas de baixo risco para cima, começando pelo plumbing e terminando
nos relatórios.

---

## Respostas às 5 perguntas-guia

### 1. Por onde começamos?

**Ordem:** infra → tracer bullet (Conta) → Categoria → Transação → Parcelamento → Relatórios.

Antes de qualquer entidade, precisamos de:
- `controle_gastos/config.py` — `Settings(BaseSettings)` com `DATABASE_URL`
- `controle_gastos/database.py` — `engine`, `SessionLocal`, `Base`, `get_db`
- `controle_gastos/main.py` — `FastAPI()`, lifespan, mount dos routers
- `alembic.ini` + `alembic/env.py` — Alembic apontando para `Base.metadata`
- `tests/conftest.py` — fixtures de DB (sessão real no `TEST_DATABASE_URL`), `override_get_db`, `override_get_today`, `AsyncClient`

Sem isso nada funciona. Com isso feito, o primeiro endpoint (POST Conta) prova que toda a cadeia está viva.

### 2. Ordem das entidades: Conta → Categoria → Transação → Parcelamento

Esse é o grafo de dependências:
```
Conta  ──┐
          ├─→  Transação  ←── (gera) ── Parcelamento
Categoria ┘
```

Conta e Categoria não têm FKs, podem ir juntas. Transação referencia ambas; deve
vir depois. Parcelamento referencia as duas **e** cria Transações — vem por último.

Tático: Conta e Categoria podem compartilhar a mesma migration (`0001_create_contas_categorias`),
pois não há FK entre elas e o padrão de model/schema/endpoint é idêntico.

### 3. Como testar Transações e Parcelamentos atomicamente

**Transação avulsa:**
- Testes de caminho feliz: criar, listar, buscar por id, PUT, PATCH, DELETE.
- Testes de borda: FK inexistente → 404; `categoria.tipo != transacao.tipo` → 422
  com mensagem exata; tentativa de editar/excluir Parcela → 422.

**Parcelamento (o ponto delicado):**

1. **Unit test do algoritmo puro** — isolar `calcular_parcelas()` como função sem I/O;
   cobrir com tabela de casos incluindo resíduos de arredondamento:
   - R$ 10,00 / 3 → [3.33, 3.33, 3.34]; soma == 10.00
   - R$ 1,00 / 3 → [0.33, 0.33, 0.34]; soma == 1.00
   - R$ 3600,00 / 12 → todos 300.00 (sem resíduo)

2. **Integration test de criação atômica** — POST parcelamento → assert exatamente
   `num_parcelas` linhas em `transacoes` → assert `sum(valores) == valor_total` (Decimal).

3. **Rollback test** — mockar sessão para lançar exceção no 2º INSERT de Transação;
   assert 0 parcelamentos e 0 transacoes no DB.

4. **Cancelamento com `get_today()` injetado** — override da dependência para data fixa;
   assert parcelas futuras deletadas, passadas preservadas, status == 'cancelado',
   contadores corretos no response body.

### 4. Maior risco: arredondamento do Parcelamento

O maior risco é a aritmética de arredondamento no Parcelamento. A fórmula da spec é:

```
parcela_base   = floor(V * 100 / N) / 100
ultima_parcela = round(V - parcela_base * (N - 1), 2)
```

Isso **deve** ser feito com `Decimal`, não `float`. Em Python:

```python
from decimal import Decimal

centavos = int(valor_total * 100)  # Decimal → int, sem perda
base_centavos = centavos // num_parcelas
parcela_base = Decimal(base_centavos) / 100
ultima = valor_total - parcela_base * (num_parcelas - 1)
```

Risco secundário: **serialização de `competencia`**. O campo é armazenado como
`YYYY-MM-01` (DATE) mas exposto como `"YYYY-MM"` (string). Um `@field_validator`
e um `@field_serializer` customizados em Pydantic v2 cobrem os dois sentidos.

Terceiro risco: **invariante `categoria.tipo`**. Deve ser validada na camada de serviço
(antes do INSERT) para retornar 422 com mensagem descritiva — não no banco.

### 5. Tracer bullet: `POST /api/v1/contas`

Essa rota toca todas as camadas com a menor complexidade possível:
- **Model:** `Conta` com `id`, `nome UNIQUE`, `criada_em`
- **Schema:** `ContaCreate(nome)` + `ContaRead(id, nome, criada_em)`
- **Endpoint:** POST retorna 201; nome duplicado retorna 409; nome vazio retorna 422
- **Migration:** `0001_create_contas`
- **Teste:** cria conta, lista, tenta duplicata

Quando esse teste passar verde com banco real, toda a infra está funcionando.

---

## Plano detalhado por fase

### Fase 0 — Infraestrutura (sem entidades)

| Arquivo | Conteúdo |
|---------|----------|
| `controle_gastos/config.py` | `Settings(BaseSettings)`: `DATABASE_URL`, `TEST_DATABASE_URL` |
| `controle_gastos/database.py` | `engine` (psycopg3 sync), `SessionLocal`, `Base`, `get_db: Generator` |
| `controle_gastos/main.py` | `app = FastAPI()`, `app.include_router(...)` para cada módulo |
| `alembic.ini` | config padrão apontando para o pacote |
| `alembic/env.py` | importa `Base` do `database.py`; usa `DATABASE_URL` da config |
| `tests/conftest.py` | `db_session` fixture (real DB), `client` fixture (`AsyncClient` + `dependency_overrides`), `freeze_today(date)` helper |

**Tracer bullet — Fase 0:**
```bash
python -c "from controle_gastos.database import engine; print(engine)"  # sem ImportError
make dev                                                                  # server sobe em :8000
curl http://localhost:8000/docs                                           # Swagger UI responde 200
alembic current                                                           # conecta ao DB sem erro
```

---

### Fase 1 — Conta (tracer bullet)

- `controle_gastos/models/conta.py` — `Conta(Base)`
- `controle_gastos/schemas/conta.py` — `ContaCreate`, `ContaRead`
- `controle_gastos/api/contas.py` — `router` com `POST /contas` e `GET /contas`
- `alembic/versions/0001_create_contas.py`
- `tests/test_contas.py`

**Tracer bullet — Fase 1:**
```bash
make migrate                                          # migration 0001 aplicada
make test -k test_contas                              # todos verdes
curl -s -X POST http://localhost:8000/api/v1/contas \
  -H "Content-Type: application/json" \
  -d '{"nome":"Nubank"}' | jq .                      # {"id":1,"nome":"Nubank","criada_em":"..."}
curl -s -X POST http://localhost:8000/api/v1/contas \
  -d '{"nome":"Nubank"}' -H "Content-Type: application/json" \
  | jq .status_code                                  # 409
```

---

### Fase 2 — Categoria

- `controle_gastos/models/categoria.py` — `Categoria(Base)` com `TipoEnum(StrEnum)`
- `controle_gastos/schemas/categoria.py` — `CategoriaCreate`, `CategoriaRead`
- `controle_gastos/api/categorias.py` — POST + GET com `?tipo=` filter
- `alembic/versions/0002_add_categorias.py`
- `tests/test_categorias.py`

**Tracer bullet — Fase 2:**
```bash
make migrate                                          # migration 0002 aplicada
make test -k test_categoria                           # todos verdes
curl -s "http://localhost:8000/api/v1/categorias?tipo=gasto" | jq length   # 0 (lista vazia)
curl -s -X POST http://localhost:8000/api/v1/categorias \
  -H "Content-Type: application/json" \
  -d '{"nome":"Alimentação","tipo":"gasto"}' | jq .tipo   # "gasto"
curl -s -X POST http://localhost:8000/api/v1/categorias \
  -H "Content-Type: application/json" \
  -d '{"nome":"X","tipo":"invalido"}' | jq .status   # 422
```

---

### Fase 3 — Transação avulsa

Novidades em relação às fases anteriores:
- `CompetenciaField`: `@field_validator` (str `"YYYY-MM"` → `date(Y, M, 1)`) +
  `@field_serializer` (`date` → `str "YYYY-MM"`)
- `valor` serializado como `str` (Pydantic `Decimal` → `str`)
- Validação na camada de serviço (`controle_gastos/services/transacoes.py`):
  - `get_or_404(db, Model, id)` helper reutilizável
  - checar `categoria.tipo == transacao.tipo`
  - checar `parcelamento_id IS NULL` em PUT/PATCH/DELETE

Arquivos:
- `controle_gastos/models/transacao.py`
- `controle_gastos/schemas/transacao.py`
- `controle_gastos/services/transacoes.py`
- `controle_gastos/api/transacoes.py`
- `alembic/versions/0003_add_transacoes.py`
- `tests/test_transacoes.py`

**Tracer bullet — Fase 3:**
```bash
make migrate                                          # migration 0003 aplicada
make test -k test_transacao                           # todos verdes (incluindo borda)
# valor deve vir como string, não número:
curl -s -X POST http://localhost:8000/api/v1/transacoes \
  -H "Content-Type: application/json" \
  -d '{"tipo":"gasto","valor":49.90,"descricao":"Mercado","competencia":"2026-10","conta_id":1,"categoria_id":1}' \
  | jq '.valor | type'                               # "string"
# competencia deve vir como "YYYY-MM":
  | jq '.competencia'                                # "2026-10"  (não "2026-10-01")
# categoria incompatível → 422:
curl -s -X POST ... -d '{"tipo":"receita",...,"categoria_id":1}' | jq .status   # 422
```

---

### Fase 4 — Parcelamento

Etapa mais complexa. Separar o algoritmo em função pura testável.

Arquivos:
- `controle_gastos/models/parcelamento.py` — `Parcelamento(Base)` com `StatusEnum`
- `controle_gastos/services/parcelamento.py`:
  - `calcular_parcelas(valor_total, num_parcelas, primeira_parcela) -> list[ParcelaCalc]`
  - `criar_parcelamento(db, payload) -> Parcelamento` — atômico (único `db.begin()`)
  - `cancelar_parcelamento(db, id, today) -> CancelamentoResult`
- `controle_gastos/schemas/parcelamento.py` — inclui `ParcelaResumida` no response do POST
- `controle_gastos/api/parcelamentos.py`
- `alembic/versions/0004_add_parcelamentos.py`
- `tests/test_parcelamento_algoritmo.py` — unit tests do algoritmo puro
- `tests/test_parcelamentos.py` — integration tests

**Tracer bullet — Fase 4:**
```bash
make migrate                                          # migration 0004 aplicada
make test -k "algoritmo"                              # unit tests do algoritmo passam
make test -k "parcelamento"                           # integration tests passam
# soma das parcelas deve ser exatamente igual ao valor_total:
curl -s -X POST http://localhost:8000/api/v1/parcelamentos \
  -H "Content-Type: application/json" \
  -d '{"descricao":"Notebook","valor_total":3600.00,"num_parcelas":12,"primeira_parcela":"2026-10","conta_id":1,"categoria_id":1}' \
  | jq '[.parcelas[].valor | tonumber] | add'        # 3600  (sem drift)
# parcelas geradas na competência correta:
  | jq '.parcelas[-1].competencia'                   # "2027-09"
# cancelamento:
curl -s -X POST http://localhost:8000/api/v1/parcelamentos/1/cancelar \
  | jq '{status,parcelas_removidas,parcelas_preservadas}'
```

---

### Fase 5 — Relatórios

- `controle_gastos/api/relatorios.py` com 3 endpoints, todos recebendo `get_today` via `Depends`
- Queries com `func.sum()`, `joinedload` para parcelas-ativas
- `tests/test_relatorios.py`

**Tracer bullet — Fase 5:**
```bash
make test -k "relatorio"                              # todos verdes
# balanço do mês com transações criadas nas fases anteriores:
curl -s "http://localhost:8000/api/v1/relatorios/balanco-mensal?competencia=2026-10" | jq .
# → {"competencia":"2026-10","total_receitas":"...","total_gastos":"...","saldo":"..."}
curl -s "http://localhost:8000/api/v1/relatorios/gastos-por-categoria?competencia=2026-10" | jq .itens
curl -s "http://localhost:8000/api/v1/relatorios/parcelas-ativas" | jq length   # > 0
make test                                             # suite completa: todos verdes
make lint                                             # ruff + mypy limpos
```

---

## Verificação end-to-end

```bash
make migrate   # 4 migrations aplicadas sem erros
make test      # pytest: todos os testes verdes, incluindo rollback e arredondamento
make lint      # ruff + mypy sem erros
make dev       # server sobe; GET /docs mostra todos os endpoints
```

Smoke manual:
1. `POST /api/v1/contas` → 201
2. `POST /api/v1/categorias` (tipo=gasto) → 201
3. `POST /api/v1/transacoes` → 201; verificar `valor` como string no JSON
4. `POST /api/v1/parcelamentos` (12x R$3600) → 201; contar 12 parcelas; somar valores == 3600.00
5. `POST /api/v1/parcelamentos/{id}/cancelar` → 200; verificar `parcelas_removidas` + `parcelas_preservadas`
6. `GET /api/v1/relatorios/balanco-mensal?competencia=2026-10` → totais corretos
