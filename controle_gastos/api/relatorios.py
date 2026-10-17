from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from controle_gastos.database import get_db
from controle_gastos.dependencies import get_today
from controle_gastos.models.categoria import Categoria
from controle_gastos.models.conta import Conta
from controle_gastos.models.parcelamento import Parcelamento, StatusEnum
from controle_gastos.models.transacao import Transacao
from controle_gastos.schemas.relatorios import (
    BalancoMensal,
    GastoCategoria,
    GastosPorCategoria,
    ParcelaAtiva,
)
from controle_gastos.schemas.transacao import _parse_competencia

router = APIRouter(prefix="/relatorios", tags=["relatorios"])


def _resolve_competencia(competencia_str: str | None, today: date) -> date:
    if competencia_str is None:
        return date(today.year, today.month, 1)
    try:
        return _parse_competencia(competencia_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="competencia deve estar no formato YYYY-MM.",
        )


@router.get("/balanco-mensal", response_model=BalancoMensal)
def balanco_mensal(
    competencia: str | None = Query(default=None),
    db: Session = Depends(get_db),
    today: date = Depends(get_today),
) -> BalancoMensal:
    comp_date = _resolve_competencia(competencia, today)

    rows = (
        db.query(Transacao.tipo, func.sum(Transacao.valor).label("total"))
        .filter(Transacao.competencia == comp_date)
        .group_by(Transacao.tipo)
        .all()
    )

    totais: dict[str, Decimal] = {row.tipo: row.total for row in rows}
    total_receitas = totais.get("receita", Decimal("0"))
    total_gastos = totais.get("gasto", Decimal("0"))
    saldo = total_receitas - total_gastos

    return BalancoMensal(
        competencia=comp_date.strftime("%Y-%m"),
        total_receitas=f"{total_receitas:.2f}",
        total_gastos=f"{total_gastos:.2f}",
        saldo=f"{saldo:.2f}",
    )


@router.get("/gastos-por-categoria", response_model=GastosPorCategoria)
def gastos_por_categoria(
    competencia: str | None = Query(default=None),
    db: Session = Depends(get_db),
    today: date = Depends(get_today),
) -> GastosPorCategoria:
    comp_date = _resolve_competencia(competencia, today)

    rows = (
        db.query(
            Transacao.categoria_id,
            Categoria.nome.label("categoria_nome"),
            func.sum(Transacao.valor).label("total"),
        )
        .join(Categoria, Transacao.categoria_id == Categoria.id)
        .filter(Transacao.tipo == "gasto", Transacao.competencia == comp_date)
        .group_by(Transacao.categoria_id, Categoria.nome)
        .order_by(func.sum(Transacao.valor).desc())
        .all()
    )

    return GastosPorCategoria(
        competencia=comp_date.strftime("%Y-%m"),
        itens=[
            GastoCategoria(
                categoria_id=row.categoria_id,
                categoria_nome=row.categoria_nome,
                total=f"{row.total:.2f}",
            )
            for row in rows
        ],
    )


@router.get("/parcelas-ativas", response_model=list[ParcelaAtiva])
def parcelas_ativas(
    db: Session = Depends(get_db),
    today: date = Depends(get_today),
) -> list[ParcelaAtiva]:
    mes_corrente = date(today.year, today.month, 1)

    rows = (
        db.query(
            Transacao,
            Parcelamento.descricao.label("parcelamento_descricao"),
            Parcelamento.num_parcelas.label("num_parcelas_total"),
            Conta.nome.label("conta_nome"),
            Categoria.nome.label("categoria_nome"),
        )
        .join(Parcelamento, Transacao.parcelamento_id == Parcelamento.id)
        .join(Conta, Transacao.conta_id == Conta.id)
        .join(Categoria, Transacao.categoria_id == Categoria.id)
        .filter(
            Parcelamento.status == StatusEnum.ATIVO,
            Transacao.competencia >= mes_corrente,
        )
        .order_by(Transacao.competencia.asc())
        .all()
    )

    return [
        ParcelaAtiva(
            transacao_id=row.Transacao.id,
            parcelamento_id=row.Transacao.parcelamento_id,
            parcelamento_descricao=row.parcelamento_descricao,
            numero_parcela=row.Transacao.numero_parcela,
            num_parcelas_total=row.num_parcelas_total,
            competencia=row.Transacao.competencia.strftime("%Y-%m"),
            valor=f"{row.Transacao.valor:.2f}",
            conta_id=row.Transacao.conta_id,
            conta_nome=row.conta_nome,
            categoria_id=row.Transacao.categoria_id,
            categoria_nome=row.categoria_nome,
        )
        for row in rows
    ]
