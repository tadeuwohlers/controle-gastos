from datetime import UTC, date, datetime
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from controle_gastos.models.categoria import Categoria
from controle_gastos.models.conta import Conta
from controle_gastos.models.parcelamento import Parcelamento
from controle_gastos.models.transacao import Transacao
from controle_gastos.schemas.parcelamento import (
    CancelamentoResult,
    ParcelamentoCreate,
    ParcelamentoReadComParcelas,
    ParcelaResumida,
)


def _get_or_404[T](db: Session, model: type[T], id: int, detail: str) -> T:
    obj = db.get(model, id)
    if obj is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)
    return obj  # type: ignore[return-value]


def _add_months(d: date, months: int) -> date:
    """Avança d por N meses, sempre retornando o 1º dia do mês resultante."""
    month = d.month + months
    year = d.year + (month - 1) // 12
    month = ((month - 1) % 12) + 1
    return date(year, month, 1)


def calcular_parcelas(
    valor_total: Decimal, num_parcelas: int, primeira_parcela: date
) -> list[dict]:
    """
    Divide valor_total em num_parcelas usando aritmética inteira para evitar
    drift. A última parcela absorve o resíduo de centavos.
    Garantia: sum(p["valor"] for p in result) == valor_total.
    """
    centavos_total = int(valor_total * 100)
    centavos_base = centavos_total // num_parcelas
    parcela_base = Decimal(centavos_base) / 100
    ultima_parcela = valor_total - parcela_base * (num_parcelas - 1)

    return [
        {
            "numero": i,
            "valor": parcela_base if i < num_parcelas else ultima_parcela,
            "competencia": _add_months(primeira_parcela, i - 1),
        }
        for i in range(1, num_parcelas + 1)
    ]


def _load_com_parcelas(
    db: Session, parcelamento: Parcelamento
) -> ParcelamentoReadComParcelas:
    parcelas = (
        db.query(Transacao)
        .filter(Transacao.parcelamento_id == parcelamento.id)
        .order_by(Transacao.numero_parcela)
        .all()
    )
    return ParcelamentoReadComParcelas(
        id=parcelamento.id,
        descricao=parcelamento.descricao,
        valor_total=parcelamento.valor_total,
        num_parcelas=parcelamento.num_parcelas,
        primeira_parcela=parcelamento.primeira_parcela,
        conta_id=parcelamento.conta_id,
        categoria_id=parcelamento.categoria_id,
        status=parcelamento.status,
        criado_em=parcelamento.criado_em,
        parcelas=[ParcelaResumida.model_validate(p) for p in parcelas],
    )


def criar_parcelamento(
    db: Session, payload: ParcelamentoCreate
) -> ParcelamentoReadComParcelas:
    _get_or_404(db, Conta, payload.conta_id, "Conta não encontrada.")
    categoria: Categoria = _get_or_404(
        db, Categoria, payload.categoria_id, "Categoria não encontrada."
    )
    if categoria.tipo != "gasto":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Parcelamentos só aceitam categorias do tipo 'gasto'.",
        )

    parcelas_calc = calcular_parcelas(
        payload.valor_total, payload.num_parcelas, payload.primeira_parcela
    )

    parcelamento = Parcelamento(
        descricao=payload.descricao,
        valor_total=payload.valor_total,
        num_parcelas=payload.num_parcelas,
        primeira_parcela=payload.primeira_parcela,
        conta_id=payload.conta_id,
        categoria_id=payload.categoria_id,
        status="ativo",
    )
    db.add(parcelamento)
    db.flush()  # obtém id sem commitar

    for p in parcelas_calc:
        db.add(
            Transacao(
                tipo="gasto",
                valor=p["valor"],
                descricao=f"{payload.descricao} {p['numero']}/{payload.num_parcelas}",
                competencia=p["competencia"],
                conta_id=payload.conta_id,
                categoria_id=payload.categoria_id,
                parcelamento_id=parcelamento.id,
                numero_parcela=p["numero"],
            )
        )

    db.commit()
    db.refresh(parcelamento)
    return _load_com_parcelas(db, parcelamento)


def cancelar_parcelamento(
    db: Session, id: int, today: date
) -> CancelamentoResult:
    parcelamento: Parcelamento = _get_or_404(
        db, Parcelamento, id, "Parcelamento não encontrado."
    )
    if parcelamento.status == "cancelado":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Parcelamento já cancelado.",
        )

    mes_corrente = date(today.year, today.month, 1)

    total = (
        db.query(Transacao)
        .filter(Transacao.parcelamento_id == id)
        .count()
    )
    removidas = (
        db.query(Transacao)
        .filter(
            Transacao.parcelamento_id == id,
            Transacao.competencia > mes_corrente,
        )
        .delete(synchronize_session="fetch")
    )
    preservadas = total - removidas

    parcelamento.status = "cancelado"
    parcelamento.atualizado_em = datetime.now(UTC)
    db.commit()

    return CancelamentoResult(
        id=id,
        status="cancelado",
        parcelas_removidas=removidas,
        parcelas_preservadas=preservadas,
    )
