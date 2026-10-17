from datetime import date, datetime
from decimal import Decimal
from typing import Any

from pydantic import BaseModel, field_serializer, field_validator

from controle_gastos.models.categoria import TipoEnum


def _parse_competencia(v: Any) -> date:
    if isinstance(v, date):
        return v
    if isinstance(v, str):
        parts = v.split("-")
        if len(parts) == 2:
            try:
                return date(int(parts[0]), int(parts[1]), 1)
            except ValueError:
                pass
    raise ValueError("competencia deve estar no formato YYYY-MM.")


class TransacaoCreate(BaseModel):
    tipo: TipoEnum
    valor: Decimal
    descricao: str
    competencia: date
    conta_id: int
    categoria_id: int

    @field_validator("competencia", mode="before")
    @classmethod
    def parse_competencia(cls, v: Any) -> date:
        return _parse_competencia(v)

    @field_validator("valor")
    @classmethod
    def valor_positivo(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("valor deve ser maior que zero.")
        return v

    @field_validator("descricao")
    @classmethod
    def descricao_nao_vazia(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("descricao não pode ser vazia.")
        return v.strip()


class TransacaoPut(BaseModel):
    """Substitui todos os campos editáveis (tipo não é editável)."""

    valor: Decimal
    descricao: str
    competencia: date
    conta_id: int
    categoria_id: int

    @field_validator("competencia", mode="before")
    @classmethod
    def parse_competencia(cls, v: Any) -> date:
        return _parse_competencia(v)

    @field_validator("valor")
    @classmethod
    def valor_positivo(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("valor deve ser maior que zero.")
        return v

    @field_validator("descricao")
    @classmethod
    def descricao_nao_vazia(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("descricao não pode ser vazia.")
        return v.strip()


class TransacaoPatch(BaseModel):
    """Atualiza campos parciais (todos opcionais)."""

    valor: Decimal | None = None
    descricao: str | None = None
    competencia: date | None = None
    conta_id: int | None = None
    categoria_id: int | None = None

    @field_validator("competencia", mode="before")
    @classmethod
    def parse_competencia(cls, v: Any) -> date | None:
        if v is None:
            return None
        return _parse_competencia(v)

    @field_validator("valor")
    @classmethod
    def valor_positivo(cls, v: Decimal | None) -> Decimal | None:
        if v is not None and v <= 0:
            raise ValueError("valor deve ser maior que zero.")
        return v

    @field_validator("descricao")
    @classmethod
    def descricao_nao_vazia(cls, v: str | None) -> str | None:
        if v is not None and not v.strip():
            raise ValueError("descricao não pode ser vazia.")
        return v.strip() if v is not None else None


class TransacaoRead(BaseModel):
    id: int
    tipo: TipoEnum
    valor: Decimal
    descricao: str
    competencia: date
    conta_id: int
    categoria_id: int
    parcelamento_id: int | None
    numero_parcela: int | None
    criada_em: datetime
    atualizada_em: datetime

    @field_validator("competencia", mode="before")
    @classmethod
    def parse_competencia(cls, v: Any) -> date:
        return _parse_competencia(v)

    @field_serializer("competencia")
    def serialize_competencia(self, v: date) -> str:
        return v.strftime("%Y-%m")

    @field_serializer("valor")
    def serialize_valor(self, v: Decimal) -> str:
        return f"{v:.2f}"

    model_config = {"from_attributes": True}
