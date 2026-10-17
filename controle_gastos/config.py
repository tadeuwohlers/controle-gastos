from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DATABASE_URL: str = (
        "postgresql+psycopg://controle_gastos:dev_password@localhost:5432/controle_gastos"
    )
    TEST_DATABASE_URL: str = (
        "postgresql+psycopg://controle_gastos:dev_password@localhost:5432/controle_gastos_test"
    )

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
