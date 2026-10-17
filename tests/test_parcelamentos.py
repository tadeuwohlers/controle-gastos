from datetime import date
from decimal import Decimal

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


# ── helpers ─────────────────────────────────────────────────────────────────


def _payload(conta_id: int, cat_id: int, **overrides) -> dict:
    base = {
        "descricao": "Notebook",
        "valor_total": 3600.00,
        "num_parcelas": 12,
        "primeira_parcela": "2026-10",
        "conta_id": conta_id,
        "categoria_id": cat_id,
    }
    base.update(overrides)
    return base


# ── testes de criação ───────────────────────────────────────────────────────


async def test_criar_parcelamento_valido(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_gasto["id"])
    )
    assert r.status_code == 201
    data = r.json()
    assert data["descricao"] == "Notebook"
    assert data["status"] == "ativo"
    assert data["num_parcelas"] == 12
    assert data["id"] is not None


async def test_post_retorna_parcelas(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_gasto["id"])
    )
    assert r.status_code == 201
    parcelas = r.json()["parcelas"]
    assert len(parcelas) == 12
    numeros = [p["numero_parcela"] for p in parcelas]
    assert numeros == list(range(1, 13))


async def test_soma_parcelas_igual_valor_total(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos",
        json=_payload(conta["id"], cat_gasto["id"], valor_total=10.00, num_parcelas=3),
    )
    assert r.status_code == 201
    parcelas = r.json()["parcelas"]
    soma = sum(Decimal(p["valor"]) for p in parcelas)
    assert soma == Decimal("10.00")


async def test_competencia_das_parcelas(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos",
        json=_payload(
            conta["id"], cat_gasto["id"], num_parcelas=3, primeira_parcela="2026-10"
        ),
    )
    assert r.status_code == 201
    competencias = [p["competencia"] for p in r.json()["parcelas"]]
    assert competencias == ["2026-10", "2026-11", "2026-12"]


async def test_criar_parcelamento_categoria_receita_retorna_422(
    client: AsyncClient, conta: dict, cat_receita: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_receita["id"])
    )
    assert r.status_code == 422
    assert "gasto" in r.json()["detail"].lower()


async def test_criar_parcelamento_num_parcelas_1_retorna_422(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos",
        json=_payload(conta["id"], cat_gasto["id"], num_parcelas=1),
    )
    assert r.status_code == 422


async def test_criar_parcelamento_conta_inexistente_retorna_404(
    client: AsyncClient, cat_gasto: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos", json=_payload(99999, cat_gasto["id"])
    )
    assert r.status_code == 404


async def test_criar_parcelamento_categoria_inexistente_retorna_404(
    client: AsyncClient, conta: dict
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], 99999)
    )
    assert r.status_code == 404


# ── testes de listagem ──────────────────────────────────────────────────────


async def test_listar_parcelamentos_sem_parcelas(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_gasto["id"])
    )
    r = await client.get("/api/v1/parcelamentos")
    assert r.status_code == 200
    data = r.json()
    assert len(data) == 1
    assert "parcelas" not in data[0]


async def test_listar_parcelamentos_filtro_status(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_gasto["id"])
    )
    pid_r = await client.post(
        "/api/v1/parcelamentos",
        json=_payload(conta["id"], cat_gasto["id"], descricao="Segundo"),
    )
    pid = pid_r.json()["id"]

    freeze_today(date(2026, 10, 17))
    await client.post(f"/api/v1/parcelamentos/{pid}/cancelar")

    r_ativo = await client.get("/api/v1/parcelamentos?status=ativo")
    r_cancelado = await client.get("/api/v1/parcelamentos?status=cancelado")
    assert len(r_ativo.json()) == 1
    assert len(r_cancelado.json()) == 1


async def test_get_parcelamento_por_id_com_parcelas(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    cr = await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_gasto["id"])
    )
    pid = cr.json()["id"]
    r = await client.get(f"/api/v1/parcelamentos/{pid}")
    assert r.status_code == 200
    data = r.json()
    assert "parcelas" in data
    assert len(data["parcelas"]) == 12


async def test_get_parcelamento_id_inexistente_retorna_404(
    client: AsyncClient,
) -> None:
    r = await client.get("/api/v1/parcelamentos/99999")
    assert r.status_code == 404


# ── testes de cancelamento ──────────────────────────────────────────────────


async def test_cancelar_parcelamento(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    # 6 parcelas: Sep-2026 a Feb-2027
    r = await client.post(
        "/api/v1/parcelamentos",
        json=_payload(
            conta["id"],
            cat_gasto["id"],
            num_parcelas=6,
            primeira_parcela="2026-09",
            valor_total=600.00,
        ),
    )
    pid = r.json()["id"]

    # hoje = 2026-10-17 → mes_corrente = 2026-10-01
    # preserva: Sep, Oct (≤ 2026-10-01)
    # remove: Nov, Dec, Jan, Feb (> 2026-10-01)
    freeze_today(date(2026, 10, 17))
    cr = await client.post(f"/api/v1/parcelamentos/{pid}/cancelar")
    assert cr.status_code == 200
    data = cr.json()
    assert data["status"] == "cancelado"
    assert data["parcelas_removidas"] == 4
    assert data["parcelas_preservadas"] == 2


async def test_cancelar_parcelamento_muda_status(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_gasto["id"])
    )
    pid = r.json()["id"]
    freeze_today(date(2026, 10, 17))
    await client.post(f"/api/v1/parcelamentos/{pid}/cancelar")

    detail = await client.get(f"/api/v1/parcelamentos/{pid}")
    assert detail.json()["status"] == "cancelado"


async def test_cancelar_ja_cancelado_retorna_422(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    r = await client.post(
        "/api/v1/parcelamentos", json=_payload(conta["id"], cat_gasto["id"])
    )
    pid = r.json()["id"]
    freeze_today(date(2026, 10, 17))
    await client.post(f"/api/v1/parcelamentos/{pid}/cancelar")

    r2 = await client.post(f"/api/v1/parcelamentos/{pid}/cancelar")
    assert r2.status_code == 422
    assert "já cancelado" in r2.json()["detail"].lower()
