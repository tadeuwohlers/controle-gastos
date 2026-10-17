import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


async def test_criar_categoria_gasto(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/categorias", json={"nome": "Alimentação", "tipo": "gasto"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["nome"] == "Alimentação"
    assert data["tipo"] == "gasto"
    assert data["id"] is not None
    assert data["criada_em"] is not None


async def test_criar_categoria_receita(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/categorias", json={"nome": "Salário", "tipo": "receita"}
    )
    assert response.status_code == 201
    assert response.json()["tipo"] == "receita"


async def test_listar_categorias_vazia(client: AsyncClient) -> None:
    response = await client.get("/api/v1/categorias")
    assert response.status_code == 200
    assert response.json() == []


async def test_listar_categorias_ordenada_por_nome(client: AsyncClient) -> None:
    await client.post("/api/v1/categorias", json={"nome": "Transporte", "tipo": "gasto"})
    await client.post("/api/v1/categorias", json={"nome": "Alimentação", "tipo": "gasto"})
    response = await client.get("/api/v1/categorias")
    assert response.status_code == 200
    nomes = [c["nome"] for c in response.json()]
    assert nomes == sorted(nomes)
    assert len(nomes) == 2


async def test_listar_categorias_filtro_gasto(client: AsyncClient) -> None:
    await client.post("/api/v1/categorias", json={"nome": "Alimentação", "tipo": "gasto"})
    await client.post("/api/v1/categorias", json={"nome": "Salário", "tipo": "receita"})
    response = await client.get("/api/v1/categorias?tipo=gasto")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["tipo"] == "gasto"


async def test_listar_categorias_filtro_receita(client: AsyncClient) -> None:
    await client.post("/api/v1/categorias", json={"nome": "Alimentação", "tipo": "gasto"})
    await client.post("/api/v1/categorias", json={"nome": "Salário", "tipo": "receita"})
    response = await client.get("/api/v1/categorias?tipo=receita")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["tipo"] == "receita"


async def test_criar_categoria_duplicada_retorna_409(client: AsyncClient) -> None:
    await client.post("/api/v1/categorias", json={"nome": "Alimentação", "tipo": "gasto"})
    response = await client.post(
        "/api/v1/categorias", json={"nome": "Alimentação", "tipo": "receita"}
    )
    assert response.status_code == 409
    assert response.json()["detail"] == "Já existe uma Categoria com esse nome."


async def test_criar_categoria_tipo_invalido_retorna_422(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/categorias", json={"nome": "Teste", "tipo": "invalido"}
    )
    assert response.status_code == 422


async def test_criar_categoria_nome_vazio_retorna_422(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/categorias", json={"nome": "", "tipo": "gasto"}
    )
    assert response.status_code == 422


async def test_criar_categoria_nome_so_espacos_retorna_422(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/categorias", json={"nome": "   ", "tipo": "gasto"}
    )
    assert response.status_code == 422
