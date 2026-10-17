from datetime import datetime
from enum import StrEnum

from sqlalchemy import TIMESTAMP, CheckConstraint, String, func
from sqlalchemy.orm import Mapped, mapped_column

from controle_gastos.database import Base


class TipoEnum(StrEnum):
    GASTO = "gasto"
    RECEITA = "receita"


class Categoria(Base):
    __tablename__ = "categorias"

    id: Mapped[int] = mapped_column(primary_key=True)
    nome: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    tipo: Mapped[str] = mapped_column(String(7), nullable=False)
    criada_em: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        CheckConstraint("tipo IN ('gasto', 'receita')", name="chk_categoria_tipo"),
    )
