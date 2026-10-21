"""Imprime o schema OpenAPI da API em JSON (não precisa de banco de dados)."""

import json

from controle_gastos.main import app

if __name__ == "__main__":
    print(json.dumps(app.openapi(), indent=2, ensure_ascii=False))
