from datetime import datetime

from pydantic import BaseModel, field_validator


class ContaCreate(BaseModel):
    nome: str

    @field_validator("nome")
    @classmethod
    def nome_nao_vazio(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("nome não pode ser vazio ou apenas espaços")
        return v.strip()


class ContaRead(BaseModel):
    id: int
    nome: str
    criada_em: datetime

    model_config = {"from_attributes": True}
