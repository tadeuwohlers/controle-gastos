from datetime import date

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


# ── helpers ─────────────────────────────────────────────────────────────────


async def _criar_gasto(
    client: AsyncClient,
    conta: dict,
    cat_gasto: dict,
    valor: float,
    competencia: str = "2026-10",
    descricao: str = "Gasto",
) -> dict:
    r = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": valor,
            "descricao": descricao,
            "competencia": competencia,
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert r.status_code == 201
    return r.json()


async def _criar_receita(
    client: AsyncClient,
    conta: dict,
    cat_receita: dict,
    valor: float,
    competencia: str = "2026-10",
) -> dict:
    r = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "receita",
            "valor": valor,
            "descricao": "Receita",
            "competencia": competencia,
            "conta_id": conta["id"],
            "categoria_id": cat_receita["id"],
        },
    )
    assert r.status_code == 201
    return r.json()


async def _criar_parcelamento(
    client: AsyncClient,
    conta: dict,
    cat_gasto: dict,
    valor_total: float = 300.0,
    num_parcelas: int = 3,
    primeira_parcela: str = "2026-10",
) -> dict:
    r = await client.post(
        "/api/v1/parcelamentos",
        json={
            "descricao": "Parcelamento Teste",
            "valor_total": valor_total,
            "num_parcelas": num_parcelas,
            "primeira_parcela": primeira_parcela,
            "conta_id": conta["id"],
            "categoria_id": cat_gasto["id"],
        },
    )
    assert r.status_code == 201
    return r.json()


# ── balanco-mensal ───────────────────────────────────────────────────────────


async def test_balanco_mensal_com_transacoes(
    client: AsyncClient, conta: dict, cat_gasto: dict, cat_receita: dict
) -> None:
    await _criar_gasto(client, conta, cat_gasto, 3200.0)
    await _criar_receita(client, conta, cat_receita, 5000.0)

    r = await client.get("/api/v1/relatorios/balanco-mensal?competencia=2026-10")
    assert r.status_code == 200
    data = r.json()
    assert data["competencia"] == "2026-10"
    assert data["total_gastos"] == "3200.00"
    assert data["total_receitas"] == "5000.00"
    assert data["saldo"] == "1800.00"


async def test_balanco_mensal_saldo_negativo(
    client: AsyncClient, conta: dict, cat_gasto: dict, cat_receita: dict
) -> None:
    await _criar_gasto(client, conta, cat_gasto, 1000.0)
    await _criar_receita(client, conta, cat_receita, 500.0)

    r = await client.get("/api/v1/relatorios/balanco-mensal?competencia=2026-10")
    assert r.status_code == 200
    assert r.json()["saldo"] == "-500.00"


async def test_balanco_mensal_sem_transacoes(client: AsyncClient) -> None:
    r = await client.get("/api/v1/relatorios/balanco-mensal?competencia=2099-01")
    assert r.status_code == 200
    data = r.json()
    assert data["competencia"] == "2099-01"
    assert data["total_gastos"] == "0.00"
    assert data["total_receitas"] == "0.00"
    assert data["saldo"] == "0.00"


async def test_balanco_mensal_default_usa_today(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    freeze_today(date(2026, 10, 1))
    await _criar_gasto(client, conta, cat_gasto, 100.0, competencia="2026-10")

    r = await client.get("/api/v1/relatorios/balanco-mensal")
    assert r.status_code == 200
    data = r.json()
    assert data["competencia"] == "2026-10"
    assert data["total_gastos"] == "100.00"


async def test_balanco_mensal_competencia_invalida(client: AsyncClient) -> None:
    r = await client.get("/api/v1/relatorios/balanco-mensal?competencia=2026/10")
    assert r.status_code == 422


async def test_balanco_mensal_ignora_outro_mes(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    await _criar_gasto(client, conta, cat_gasto, 500.0, competencia="2026-09")

    r = await client.get("/api/v1/relatorios/balanco-mensal?competencia=2026-10")
    assert r.status_code == 200
    assert r.json()["total_gastos"] == "0.00"


# ── gastos-por-categoria ─────────────────────────────────────────────────────


async def test_gastos_por_categoria(
    client: AsyncClient, conta: dict, cat_gasto: dict
) -> None:
    cat2 = (
        await client.post(
            "/api/v1/categorias", json={"nome": "Tecnologia", "tipo": "gasto"}
        )
    ).json()

    await _criar_gasto(client, conta, cat_gasto, 100.0, descricao="A")
    r = await client.post(
        "/api/v1/transacoes",
        json={
            "tipo": "gasto",
            "valor": 200.0,
            "descricao": "B",
            "competencia": "2026-10",
            "conta_id": conta["id"],
            "categoria_id": cat2["id"],
        },
    )
    assert r.status_code == 201

    r = await client.get(
        "/api/v1/relatorios/gastos-por-categoria?competencia=2026-10"
    )
    assert r.status_code == 200
    data = r.json()
    assert data["competencia"] == "2026-10"
    itens = data["itens"]
    assert len(itens) == 2
    # ordered by total DESC
    assert itens[0]["total"] == "200.00"
    assert itens[1]["total"] == "100.00"


async def test_gastos_por_categoria_vazio(client: AsyncClient) -> None:
    r = await client.get(
        "/api/v1/relatorios/gastos-por-categoria?competencia=2099-01"
    )
    assert r.status_code == 200
    assert r.json()["itens"] == []


async def test_gastos_por_categoria_exclui_receitas(
    client: AsyncClient, conta: dict, cat_receita: dict
) -> None:
    await _criar_receita(client, conta, cat_receita, 5000.0)

    r = await client.get(
        "/api/v1/relatorios/gastos-por-categoria?competencia=2026-10"
    )
    assert r.status_code == 200
    assert r.json()["itens"] == []


async def test_gastos_por_categoria_default_usa_today(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    freeze_today(date(2026, 10, 1))
    await _criar_gasto(client, conta, cat_gasto, 150.0, competencia="2026-10")

    r = await client.get("/api/v1/relatorios/gastos-por-categoria")
    assert r.status_code == 200
    data = r.json()
    assert data["competencia"] == "2026-10"
    assert len(data["itens"]) == 1
    assert data["itens"][0]["total"] == "150.00"


# ── parcelas-ativas ──────────────────────────────────────────────────────────


async def test_parcelas_ativas_lista_todas_a_partir_de_hoje(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    freeze_today(date(2026, 10, 1))
    await _criar_parcelamento(client, conta, cat_gasto)  # 3 parcelas: out, nov, dez

    r = await client.get("/api/v1/relatorios/parcelas-ativas")
    assert r.status_code == 200
    itens = r.json()
    assert len(itens) == 3
    assert itens[0]["competencia"] == "2026-10"
    assert itens[2]["competencia"] == "2026-12"


async def test_parcelas_ativas_exclui_passadas(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    freeze_today(date(2026, 10, 1))
    await _criar_parcelamento(client, conta, cat_gasto)  # out, nov, dez

    freeze_today(date(2026, 11, 1))  # avança para novembro
    r = await client.get("/api/v1/relatorios/parcelas-ativas")
    assert r.status_code == 200
    itens = r.json()
    assert len(itens) == 2
    assert itens[0]["competencia"] == "2026-11"


async def test_parcelas_ativas_exclui_parcelamentos_cancelados(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    freeze_today(date(2026, 10, 1))
    parc = await _criar_parcelamento(client, conta, cat_gasto)

    r = await client.post(f"/api/v1/parcelamentos/{parc['id']}/cancelar")
    assert r.status_code == 200

    r = await client.get("/api/v1/relatorios/parcelas-ativas")
    assert r.status_code == 200
    assert r.json() == []


async def test_parcelas_ativas_campos_completos(
    client: AsyncClient, conta: dict, cat_gasto: dict, freeze_today
) -> None:
    freeze_today(date(2026, 10, 1))
    parc = await _criar_parcelamento(
        client, conta, cat_gasto, valor_total=300.0, num_parcelas=3
    )

    r = await client.get("/api/v1/relatorios/parcelas-ativas")
    assert r.status_code == 200
    item = r.json()[0]

    assert item["parcelamento_id"] == parc["id"]
    assert item["parcelamento_descricao"] == "Parcelamento Teste"
    assert item["numero_parcela"] == 1
    assert item["num_parcelas_total"] == 3
    assert item["conta_id"] == conta["id"]
    assert item["conta_nome"] == "Nubank"
    assert item["categoria_nome"] == "Alimentação"
    assert isinstance(item["valor"], str)


async def test_parcelas_ativas_sem_parcelamentos(client: AsyncClient) -> None:
    r = await client.get("/api/v1/relatorios/parcelas-ativas")
    assert r.status_code == 200
    assert r.json() == []
