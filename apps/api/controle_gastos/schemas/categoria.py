from datetime import datetime

from pydantic import BaseModel, field_validator

from controle_gastos.models.categoria import TipoEnum


class CategoriaCreate(BaseModel):
    nome: str
    tipo: TipoEnum

    @field_validator("nome")
    @classmethod
    def nome_nao_vazio(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("nome não pode ser vazio ou apenas espaços")
        return v.strip()


class CategoriaRead(BaseModel):
    id: int
    nome: str
    tipo: TipoEnum
    criada_em: datetime

    model_config = {"from_attributes": True}
