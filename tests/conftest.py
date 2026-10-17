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
