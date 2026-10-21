import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ORIGEM_WEB = "http://localhost:3000"


async def test_preflight_origem_permitida(client: AsyncClient) -> None:
    r = await client.options(
        "/api/v1/contas",
        headers={
            "Origin": _ORIGEM_WEB,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type",
        },
    )
    assert r.status_code == 200
    assert r.headers["access-control-allow-origin"] == _ORIGEM_WEB


async def test_resposta_inclui_header_cors_para_origem_permitida(
    client: AsyncClient,
) -> None:
    r = await client.get("/api/v1/contas", headers={"Origin": _ORIGEM_WEB})
    assert r.headers["access-control-allow-origin"] == _ORIGEM_WEB


async def test_origem_nao_permitida_nao_recebe_header_cors(
    client: AsyncClient,
) -> None:
    r = await client.get("/api/v1/contas", headers={"Origin": "http://evil.example"})
    assert "access-control-allow-origin" not in r.headers
