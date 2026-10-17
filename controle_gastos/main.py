from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from controle_gastos.api.contas import router as contas_router


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    yield


app = FastAPI(title="Controle de Gastos", version="0.1.0", lifespan=lifespan)

app.include_router(contas_router, prefix="/api/v1")
