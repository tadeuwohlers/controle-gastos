from datetime import date

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from controle_gastos.config import settings
from controle_gastos.database import Base, get_db
from controle_gastos.main import app

_test_engine = create_engine(settings.TEST_DATABASE_URL)
_TestSessionLocal = sessionmaker(bind=_test_engine, autocommit=False, autoflush=False)


@pytest.fixture
def db_session():
    Base.metadata.drop_all(_test_engine)
    Base.metadata.create_all(_test_engine)
    session = _TestSessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
async def client(db_session: Session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()


# ── shared domain fixtures (available to all test modules) ──────────────────


@pytest.fixture
async def conta(client: AsyncClient) -> dict:
    r = await client.post("/api/v1/contas", json={"nome": "Nubank"})
    return r.json()


@pytest.fixture
async def cat_gasto(client: AsyncClient) -> dict:
    r = await client.post(
        "/api/v1/categorias", json={"nome": "Alimentação", "tipo": "gasto"}
    )
    return r.json()


@pytest.fixture
async def cat_receita(client: AsyncClient) -> dict:
    r = await client.post(
        "/api/v1/categorias", json={"nome": "Salário", "tipo": "receita"}
    )
    return r.json()


@pytest.fixture
def freeze_today():
    """Fixture que congela get_today() para uma data fixa num teste."""
    from controle_gastos.dependencies import get_today

    frozen: list[date] = []

    def _freeze(d: date) -> None:
        frozen.append(d)
        app.dependency_overrides[get_today] = lambda: d

    yield _freeze

    app.dependency_overrides.pop(get_today, None)
