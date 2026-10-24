"""Recria do zero o banco de teste (E2E): cria se faltar, apaga o schema e aplica as migrations.

Usa `DATABASE_URL`. Recusa qualquer banco cujo nome não termine em `_test`,
para nunca tocar no banco de desenvolvimento.
"""

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

from controle_gastos.config import settings


def main() -> None:
    url = make_url(settings.DATABASE_URL)
    if not (url.database or "").endswith("_test"):
        raise SystemExit(
            f"Recusado: '{url.database}' não termina em '_test'. "
            "Aponte DATABASE_URL para o banco de teste."
        )

    admin = create_engine(url.set(database="postgres"), isolation_level="AUTOCOMMIT")
    with admin.connect() as conn:
        existe = conn.execute(
            text("SELECT 1 FROM pg_database WHERE datname = :n"), {"n": url.database}
        ).scalar()
        if not existe:
            conn.execute(text(f'CREATE DATABASE "{url.database}"'))
    admin.dispose()

    engine = create_engine(url, isolation_level="AUTOCOMMIT")
    with engine.connect() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE"))
        conn.execute(text("CREATE SCHEMA public"))
    engine.dispose()

    command.upgrade(Config("alembic.ini"), "head")
    print(f"Banco '{url.database}' recriado e migrado.")


if __name__ == "__main__":
    main()
