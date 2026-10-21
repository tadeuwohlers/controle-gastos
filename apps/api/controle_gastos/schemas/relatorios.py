from pydantic import BaseModel


class BalancoMensal(BaseModel):
    competencia: str
    total_receitas: str
    total_gastos: str
    saldo: str


class GastoCategoria(BaseModel):
    categoria_id: int
    categoria_nome: str
    total: str


class GastosPorCategoria(BaseModel):
    competencia: str
    itens: list[GastoCategoria]


class ParcelaAtiva(BaseModel):
    transacao_id: int
    parcelamento_id: int
    parcelamento_descricao: str
    numero_parcela: int
    num_parcelas_total: int
    competencia: str
    valor: str
    conta_id: int
    conta_nome: str
    categoria_id: int
    categoria_nome: str
