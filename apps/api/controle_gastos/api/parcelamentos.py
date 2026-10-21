from datetime import date

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from controle_gastos.database import get_db
from controle_gastos.dependencies import get_today
from controle_gastos.models.parcelamento import Parcelamento, StatusEnum
from controle_gastos.schemas.parcelamento import (
    CancelamentoResult,
    ParcelamentoCreate,
    ParcelamentoRead,
    ParcelamentoReadComParcelas,
)
from controle_gastos.services.parcelamento import (
    _load_com_parcelas,
    cancelar_parcelamento,
    criar_parcelamento,
)
from controle_gastos.services.transacoes import get_or_404

router = APIRouter(prefix="/parcelamentos", tags=["parcelamentos"])


@router.post(
    "", response_model=ParcelamentoReadComParcelas, status_code=status.HTTP_201_CREATED
)
def create_parcelamento(
    payload: ParcelamentoCreate, db: Session = Depends(get_db)
) -> ParcelamentoReadComParcelas:
    return criar_parcelamento(db, payload)


@router.get("", response_model=list[ParcelamentoRead])
def list_parcelamentos(
    status_filter: StatusEnum | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db),
) -> list[Parcelamento]:
    q = db.query(Parcelamento)
    if status_filter is not None:
        q = q.filter(Parcelamento.status == status_filter)
    return q.order_by(Parcelamento.id).all()


@router.get("/{id}", response_model=ParcelamentoReadComParcelas)
def get_parcelamento(
    id: int, db: Session = Depends(get_db)
) -> ParcelamentoReadComParcelas:
    parcelamento: Parcelamento = get_or_404(
        db, Parcelamento, id, "Parcelamento não encontrado."
    )
    return _load_com_parcelas(db, parcelamento)


@router.post("/{id}/cancelar", response_model=CancelamentoResult)
def cancelar(
    id: int,
    db: Session = Depends(get_db),
    today: date = Depends(get_today),
) -> CancelamentoResult:
    return cancelar_parcelamento(db, id, today)
