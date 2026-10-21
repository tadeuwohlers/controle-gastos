from datetime import date, datetime
from decimal import Decimal
from typing import Any

from pydantic import BaseModel, field_serializer, field_validator

from controle_gastos.schemas.transacao import _parse_competencia


class ParcelaResumida(BaseModel):
    id: int
    numero_parcela: int
    competencia: date
    valor: Decimal

    @field_serializer("competencia")
    def serialize_competencia(self, v: date) -> str:
        return v.strftime("%Y-%m")

    @field_serializer("valor")
    def serialize_valor(self, v: Decimal) -> str:
        return f"{v:.2f}"

    model_config = {"from_attributes": True}


class ParcelamentoCreate(BaseModel):
    descricao: str
    valor_total: Decimal
    num_parcelas: int
    primeira_parcela: date
    conta_id: int
    categoria_id: int

    @field_validator("primeira_parcela", mode="before")
    @classmethod
    def parse_primeira_parcela(cls, v: Any) -> date:
        return _parse_competencia(v)

    @field_validator("valor_total")
    @classmethod
    def valor_positivo(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("valor_total deve ser maior que zero.")
        return v

    @field_validator("num_parcelas")
    @classmethod
    def num_parcelas_minimo(cls, v: int) -> int:
        if v < 2:
            raise ValueError("num_parcelas deve ser pelo menos 2.")
        return v

    @field_validator("descricao")
    @classmethod
    def descricao_nao_vazia(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("descricao não pode ser vazia.")
        return v.strip()


class ParcelamentoRead(BaseModel):
    id: int
    descricao: str
    valor_total: Decimal
    num_parcelas: int
    primeira_parcela: date
    conta_id: int
    categoria_id: int
    status: str
    criado_em: datetime

    @field_validator("primeira_parcela", mode="before")
    @classmethod
    def parse_primeira_parcela(cls, v: Any) -> date:
        return _parse_competencia(v)

    @field_serializer("primeira_parcela")
    def serialize_primeira_parcela(self, v: date) -> str:
        return v.strftime("%Y-%m")

    @field_serializer("valor_total")
    def serialize_valor_total(self, v: Decimal) -> str:
        return f"{v:.2f}"

    model_config = {"from_attributes": True}


class ParcelamentoReadComParcelas(ParcelamentoRead):
    parcelas: list[ParcelaResumida]


class CancelamentoResult(BaseModel):
    id: int
    status: str
    parcelas_removidas: int
    parcelas_preservadas: int
