.PHONY: dev test lint format migrate

dev:
	uv run uvicorn controle_gastos.main:app --reload --host 0.0.0.0 --port 8000

test:
	uv run pytest -v

test-watch:
	uv run pytest -v --tb=short -x

lint:
	uv run ruff check controle_gastos tests

format:
	uv run ruff format controle_gastos tests

migrate:
	uv run alembic upgrade head

migrate-create:
	uv run alembic revision --autogenerate -m "$(MSG)"