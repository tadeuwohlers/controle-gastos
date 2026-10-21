from datetime import date
from decimal import Decimal

import pytest
from httpx import AsyncClient
from sqlalchemy.orm import Session

pytestmark = pytest.mark.asyncio


# ── fixtures de apoio ───────────────────────────────────────────────────────


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
async def transacao_avulsa(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> dict:
    r = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 49.90,
            "descricao": "Supermercado",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert r.status_code == 201
    return r.json()


@pytest.fixture
async def transacao_parcela(
    db_session: Session, conta: dict, cat_gasto: dict
) -> object:
    """Cria parcelamento + transação ligada a ele diretamente no DB."""
    from controle_gastos.models.parcelamento import Parcelamento
    from controle_gastos.models.transacao import Transacao

    parc = Parcelamento(
        descricao="Fixture parcela",
        valor_total=Decimal("300.00"),
        num_parcelas=3,
        primeira_parcela=date(2026, 10, 1),
        conta_id=conta["id"],
        categoria_id=cat_gasto["id"],
        status="ativo",
    )
    db_session.add(parc)
    db_session.flush()

    t = Transacao(
        tipo="gasto",
        valor=Decimal("100.00"),
        descricao="Parcela 1/3",
        competencia=date(2026, 10, 1),
        conta_id=conta["id"],
        categoria_id=cat_gasto["id"],
        parcelamento_id=parc.id,
        numero_parcela=1,
    )
    db_session.add(t)
    db_session.commit()
    db_session.refresh(t)
    return t


# ── testes de criação ───────────────────────────────────────────────────────


async def test_criar_transacao_gasto(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 49.90,
            "descricao": "Supermercado",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["tipo"] == "gasto"
    assert data["id"] is not None
    assert data["parcelamento_id"] is None
    assert data["numero_parcela"] is None


async def test_criar_transacao_receita(
    client: AsyncClient, conta: dict, cat_receita: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "receita",
            "valor": 5000.00,
            "descricao": "Salário mensal",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_receita["id"],
        },
    )
    assert response.status_code == 201
    assert response.json()["tipo"] == "receita"


async def test_competencia_retornada_como_ano_mes(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 10.00,
            "descricao": "Teste",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 201
    assert response.json()["competencia"] == "2026-10"


async def test_valor_retornado_como_string(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 49.90,
            "descricao": "Teste",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert isinstance(data["valor"], str), "valor deve ser string no JSON"
    assert data["valor"] == "49.90"


async def test_criar_transacao_tipo_categoria_incompativel_retorna_422(
    client: AsyncClient, conta: dict, cat_receita: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 10.00,
            "descricao": "Incompatível",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_receita["id"],
        },
    )
    assert response.status_code == 422


async def test_criar_transacao_conta_inexistente_retorna_404(
    client: AsyncClient, cat_gasto: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 10.00,
            "descricao": "Teste",
            "competencia": "2026-10",
            "conta_id": 99999,
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 404
    assert response.json()["detail"] == "Conta não encontrada."


async def test_criar_transacao_categoria_inexistente_retorna_404(
    client: AsyncClient, conta: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 10.00,
            "descricao": "Teste",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": 99999,
        },
    )
    assert response.status_code == 404
    assert response.json()["detail"] == "Categoria não encontrada."


async def test_criar_transacao_valor_zero_retorna_422(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 0,
            "descricao": "Teste",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 422


async def test_criar_transacao_competencia_invalida_retorna_422(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    response = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 10.00,
            "descricao": "Teste",
            "competencia": "2026/10",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 422


# ── testes de listagem e leitura ────────────────────────────────────────────


async def test_listar_transacoes(
    client: AsyncClient, transacao_avulsa: dict
) -> None:
    response = await client.get("/api/v1/transacoes")
    assert response.status_code == 200
    assert len(response.json()) == 1


async def test_get_transacao_por_id(
    client: AsyncClient, transacao_avulsa: dict
) -> None:
    tid = transacao_avulsa["id"]
    response = await client.get(f"/api/v1/transacoes/{tid}")
    assert response.status_code == 200
    assert response.json()["id"] == tid


async def test_get_transacao_id_inexistente_retorna_404(
    client: AsyncClient,
) -> None:
    response = await client.get("/api/v1/transacoes/99999")
    assert response.status_code == 404


# ── testes de edição ────────────────────────────────────────────────────────


async def test_put_transacao_avulsa(
    client: AsyncClient, transacao_avulsa: dict, conta: dict, cat_gasto: dict
) -> None:
    tid = transacao_avulsa["id"]
    response = await client.put(
        f"/api/v1/transacoes/{tid}",
        json={
            "valor": 99.90,
            "descricao": "Padaria atualizada",
            "competencia": "2026-11",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["descricao"] == "Padaria atualizada"
    assert data["competencia"] == "2026-11"
    assert data["valor"] == "99.90"


async def test_patch_transacao_avulsa_descricao(
    client: AsyncClient, transacao_avulsa: dict
) -> None:
    tid = transacao_avulsa["id"]
    response = await client.patch(
        f"/api/v1/transacoes/{tid}", json={"descricao": "Padaria"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["descricao"] == "Padaria"
    assert data["valor"] == transacao_avulsa["valor"]  # inalterado


async def test_delete_transacao_avulsa(
    client: AsyncClient, transacao_avulsa: dict
) -> None:
    tid = transacao_avulsa["id"]
    response = await client.delete(f"/api/v1/transacoes/{tid}")
    assert response.status_code == 204
    assert (await client.get(f"/api/v1/transacoes/{tid}")).status_code == 404


# ── testes de proteção de Parcelas ─────────────────────────────────────────


async def test_put_parcela_retorna_422(
    client: AsyncClient, transacao_parcela: object, conta: dict, cat_gasto: dict
) -> None:
    tid = transacao_parcela.id  # type: ignore[attr-defined]
    response = await client.put(
        f"/api/v1/transacoes/{tid}",
        json={
            "valor": 100.00,
            "descricao": "Tentativa",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert response.status_code == 422
    assert (
        "Parcelas só podem ser alteradas via Parcelamento"
        in response.json()["detail"]
    )


async def test_patch_parcela_retorna_422(
    client: AsyncClient, transacao_parcela: object
) -> None:
    tid = transacao_parcela.id  # type: ignore[attr-defined]
    response = await client.patch(
        f"/api/v1/transacoes/{tid}", json={"descricao": "Tentativa"}
    )
    assert response.status_code == 422
    assert (
        "Parcelas só podem ser alteradas via Parcelamento"
        in response.json()["detail"]
    )


async def test_delete_parcela_retorna_422(
    client: AsyncClient, transacao_parcela: object
) -> None:
    tid = transacao_parcela.id  # type: ignore[attr-defined]
    response = await client.delete(f"/api/v1/transacoes/{tid}")
    assert response.status_code == 422
    assert "Parcelas só podem ser excluídas" in response.json()["detail"]
