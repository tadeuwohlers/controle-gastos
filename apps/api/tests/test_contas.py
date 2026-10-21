import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


async def test_criar_conta(client: AsyncClient) -> None:
    response = await client.post("/api/v1/contas", json={"nome": "Nubank"})
    assert response.status_code == 201
    data = response.json()
    assert data["nome"] == "Nubank"
    assert data["id"] is not None
    assert data["criada_em"] is not None


async def test_listar_contas_vazia(client: AsyncClient) -> None:
    response = await client.get("/api/v1/contas")
    assert response.status_code == 200
    assert response.json() == []


async def test_listar_contas_ordenada_por_nome(client: AsyncClient) -> None:
    await client.post("/api/v1/contas", json={"nome": "Bradesco"})
    await client.post("/api/v1/contas", json={"nome": "Nubank"})
    await client.post("/api/v1/contas", json={"nome": "Itaú"})
    response = await client.get("/api/v1/contas")
    assert response.status_code == 200
    nomes = [c["nome"] for c in response.json()]
    assert nomes == sorted(nomes)


async def test_criar_conta_duplicada_retorna_409(client: AsyncClient) -> None:
    await client.post("/api/v1/contas", json={"nome": "Nubank"})
    response = await client.post("/api/v1/contas", json={"nome": "Nubank"})
    assert response.status_code == 409
    assert response.json()["detail"] == "Já existe uma Conta com esse nome."


async def test_criar_conta_nome_vazio_retorna_422(client: AsyncClient) -> None:
    response = await client.post("/api/v1/contas", json={"nome": ""})
    assert response.status_code == 422


async def test_criar_conta_nome_so_espacos_retorna_422(client: AsyncClient) -> None:
    response = await client.post("/api/v1/contas", json={"nome": "   "})
    assert response.status_code == 422


async def test_criar_conta_sem_nome_retorna_422(client: AsyncClient) -> None:
    response = await client.post("/api/v1/contas", json={})
    assert response.status_code == 422
