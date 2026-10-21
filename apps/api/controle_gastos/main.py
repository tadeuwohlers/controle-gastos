from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from controle_gastos.api.categorias import router as categorias_router
from controle_gastos.api.contas import router as contas_router
from controle_gastos.api.parcelamentos import router as parcelamentos_router
from controle_gastos.api.relatorios import router as relatorios_router
from controle_gastos.api.transacoes import router as transacoes_router
from controle_gastos.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    yield


app = FastAPI(title="Controle de Gastos", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(contas_router, prefix="/api/v1")
app.include_router(categorias_router, prefix="/api/v1")
app.include_router(transacoes_router, prefix="/api/v1")
app.include_router(parcelamentos_router, prefix="/api/v1")
app.include_router(relatorios_router, prefix="/api/v1")
