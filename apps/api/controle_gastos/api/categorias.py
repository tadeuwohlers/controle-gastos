from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from controle_gastos.database import get_db
from controle_gastos.models.categoria import Categoria, TipoEnum
from controle_gastos.schemas.categoria import CategoriaCreate, CategoriaRead

router = APIRouter(prefix="/categorias", tags=["categorias"])


@router.post("", response_model=CategoriaRead, status_code=status.HTTP_201_CREATED)
def create_categoria(
    payload: CategoriaCreate, db: Session = Depends(get_db)
) -> Categoria:
    categoria = Categoria(nome=payload.nome, tipo=payload.tipo)
    db.add(categoria)
    try:
        db.commit()
        db.refresh(categoria)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe uma Categoria com esse nome.",
        )
    return categoria


@router.get("", response_model=list[CategoriaRead])
def list_categorias(
    tipo: TipoEnum | None = Query(default=None),
    db: Session = Depends(get_db),
) -> list[Categoria]:
    q = db.query(Categoria)
    if tipo is not None:
        q = q.filter(Categoria.tipo == tipo)
    return q.order_by(Categoria.nome).all()
