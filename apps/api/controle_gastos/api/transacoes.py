from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from controle_gastos.database import get_db
from controle_gastos.models.transacao import Transacao
from controle_gastos.schemas.transacao import (
    TransacaoCreate,
    TransacaoPatch,
    TransacaoPut,
    TransacaoRead,
)
from controle_gastos.services.transacoes import (
    atualizar_transacao_avulsa,
    criar_transacao_avulsa,
    deletar_transacao_avulsa,
    get_or_404,
    patch_transacao_avulsa,
)

router = APIRouter(prefix="/transacoes", tags=["transacoes"])


@router.post("", response_model=TransacaoRead, status_code=status.HTTP_201_CREATED)
def create_transacao(
    payload: TransacaoCreate, db: Session = Depends(get_db)
) -> Transacao:
    return criar_transacao_avulsa(db, payload)


@router.get("", response_model=list[TransacaoRead])
def list_transacoes(db: Session = Depends(get_db)) -> list[Transacao]:
    return (
        db.query(Transacao)
        .order_by(Transacao.competencia.desc(), Transacao.id.desc())
        .all()
    )


@router.get("/{id}", response_model=TransacaoRead)
def get_transacao(id: int, db: Session = Depends(get_db)) -> Transacao:
    return get_or_404(db, Transacao, id, "Transação não encontrada.")


@router.put("/{id}", response_model=TransacaoRead)
def put_transacao(
    id: int, payload: TransacaoPut, db: Session = Depends(get_db)
) -> Transacao:
    return atualizar_transacao_avulsa(db, id, payload)


@router.patch("/{id}", response_model=TransacaoRead)
def patch_transacao(
    id: int, payload: TransacaoPatch, db: Session = Depends(get_db)
) -> Transacao:
    return patch_transacao_avulsa(db, id, payload)


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transacao(id: int, db: Session = Depends(get_db)) -> Response:
    deletar_transacao_avulsa(db, id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
