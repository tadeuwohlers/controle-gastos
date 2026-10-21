# apps/api

API REST em Python (FastAPI). Rode os comandos abaixo a partir de `apps/api/` ou, da raiz, via `make`.

## Commands

```bash
make dev       # start dev server
make test      # run test suite
make lint      # run linter
make format    # auto-format code
make migrate   # apply pending migrations
```

## Project conventions

- Imports organized (stdlib → third-party → local)
- Type hints on all function signatures
- Docstrings on business logic methods; skip trivial getters/setters
- Models in `controle_gastos/models/`
- Pydantic schemas in `controle_gastos/schemas/`
- API endpoints in `controle_gastos/api/`

## Architecture

- **ORM**: SQLAlchemy declarative base
- **API**: FastAPI with dependency injection
- **Migrations**: Alembic — versioned, never auto-generated without human review

## Tests

- pytest with fixtures for DB setup/teardown and HTTP client
- TDD workflow: red → green → refactor
- Test DB: set `TEST_DATABASE_URL` env var; swap via `app.dependency_overrides`

## Common mistakes to avoid

- **No lazy loading in endpoints** — always eager-load with `joinedload`; lazy loading causes N+1 and breaks async contexts
- **DECIMAL as strings in JSON** — never return `Decimal` as a raw number; serialize to `str` in Pydantic schemas
- **Never auto-generate migrations without reviewing** — always inspect the generated script before applying
