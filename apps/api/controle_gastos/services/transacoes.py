from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from controle_gastos.models.categoria import Categoria
from controle_gastos.models.conta import Conta
from controle_gastos.models.transacao import Transacao
from controle_gastos.schemas.transacao import TransacaoPatch, TransacaoPut

_MSG_PARCELA_ALTERAR = "Parcelas só podem ser alteradas via Parcelamento."
_MSG_PARCELA_EXCLUIR = (
    "Parcelas só podem ser excluídas via cancelamento do Parcelamento."
)


def get_or_404[T](db: Session, model: type[T], id: int, detail: str) -> T:
    obj = db.get(model, id)
    if obj is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)
    return obj


def _validate_tipo_categoria(categoria: Any, tipo: str) -> None:
    if categoria.tipo != tipo:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=(
                f"Categoria do tipo '{categoria.tipo}' não pode ser usada "
                f"em transação do tipo '{tipo}'."
            ),
        )


def _assert_avulsa(transacao: Transacao) -> None:
    if transacao.parcelamento_id is not None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=_MSG_PARCELA_ALTERAR,
        )


def criar_transacao_avulsa(db: Session, payload: Any) -> Transacao:
    get_or_404(db, Conta, payload.conta_id, "Conta não encontrada.")
    categoria = get_or_404(
        db, Categoria, payload.categoria_id, "Categoria não encontrada."
    )
    _validate_tipo_categoria(categoria, payload.tipo)

    transacao = Transacao(
        tipo=payload.tipo,
        valor=payload.valor,
        descricao=payload.descricao,
        competencia=payload.competencia,
        conta_id=payload.conta_id,
        categoria_id=payload.categoria_id,
    )
    db.add(transacao)
    db.commit()
    db.refresh(transacao)
    return transacao


def atualizar_transacao_avulsa(
    db: Session, id: int, payload: TransacaoPut
) -> Transacao:
    transacao: Transacao = get_or_404(db, Transacao, id, "Transação não encontrada.")
    _assert_avulsa(transacao)

    get_or_404(db, Conta, payload.conta_id, "Conta não encontrada.")
    categoria = get_or_404(
        db, Categoria, payload.categoria_id, "Categoria não encontrada."
    )
    _validate_tipo_categoria(categoria, transacao.tipo)

    transacao.valor = payload.valor
    transacao.descricao = payload.descricao
    transacao.competencia = payload.competencia
    transacao.conta_id = payload.conta_id
    transacao.categoria_id = payload.categoria_id
    transacao.atualizada_em = datetime.now(UTC)
    db.commit()
    db.refresh(transacao)
    return transacao


def patch_transacao_avulsa(db: Session, id: int, payload: TransacaoPatch) -> Transacao:
    transacao: Transacao = get_or_404(db, Transacao, id, "Transação não encontrada.")
    _assert_avulsa(transacao)

    if payload.conta_id is not None:
        get_or_404(db, Conta, payload.conta_id, "Conta não encontrada.")
        transacao.conta_id = payload.conta_id

    if payload.categoria_id is not None:
        categoria = get_or_404(
            db, Categoria, payload.categoria_id, "Categoria não encontrada."
        )
        _validate_tipo_categoria(categoria, transacao.tipo)
        transacao.categoria_id = payload.categoria_id

    if payload.valor is not None:
        transacao.valor = payload.valor
    if payload.descricao is not None:
        transacao.descricao = payload.descricao
    if payload.competencia is not None:
        transacao.competencia = payload.competencia

    transacao.atualizada_em = datetime.now(UTC)
    db.commit()
    db.refresh(transacao)
    return transacao


def deletar_transacao_avulsa(db: Session, id: int) -> None:
    transacao: Transacao = get_or_404(db, Transacao, id, "Transação não encontrada.")
    if transacao.parcelamento_id is not None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail=_MSG_PARCELA_EXCLUIR,
        )
    db.delete(transacao)
    db.commit()
