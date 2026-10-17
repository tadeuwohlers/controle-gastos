from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from controle_gastos.database import get_db
from controle_gastos.models.conta import Conta
from controle_gastos.schemas.conta import ContaCreate, ContaRead

router = APIRouter(prefix="/contas", tags=["contas"])


@router.post("", response_model=ContaRead, status_code=status.HTTP_201_CREATED)
def create_conta(payload: ContaCreate, db: Session = Depends(get_db)) -> Conta:
    conta = Conta(nome=payload.nome)
    db.add(conta)
    try:
        db.commit()
        db.refresh(conta)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe uma Conta com esse nome.",
        )
    return conta


@router.get("", response_model=list[ContaRead])
def list_contas(db: Session = Depends(get_db)) -> list[Conta]:
    return db.query(Conta).order_by(Conta.nome).all()
