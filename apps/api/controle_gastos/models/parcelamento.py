from datetime import date, datetime
from decimal import Decimal
from enum import StrEnum

from sqlalchemy import (
    TIMESTAMP,
    CheckConstraint,
    Date,
    ForeignKey,
    Integer,
    Numeric,
    String,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from controle_gastos.database import Base


class StatusEnum(StrEnum):
    ATIVO = "ativo"
    CANCELADO = "cancelado"


class Parcelamento(Base):
    __tablename__ = "parcelamentos"

    id: Mapped[int] = mapped_column(primary_key=True)
    descricao: Mapped[str] = mapped_column(String(255), nullable=False)
    valor_total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    num_parcelas: Mapped[int] = mapped_column(Integer(), nullable=False)
    primeira_parcela: Mapped[date] = mapped_column(Date(), nullable=False)
    conta_id: Mapped[int] = mapped_column(ForeignKey("contas.id"), nullable=False)
    categoria_id: Mapped[int] = mapped_column(
        ForeignKey("categorias.id"), nullable=False
    )
    status: Mapped[str] = mapped_column(
        String(9), nullable=False, server_default="ativo"
    )
    criado_em: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )
    atualizado_em: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        CheckConstraint("valor_total > 0", name="chk_parcelamento_valor_positivo"),
        CheckConstraint("num_parcelas >= 2", name="chk_parcelamento_num_parcelas"),
        CheckConstraint(
            "status IN ('ativo', 'cancelado')", name="chk_parcelamento_status"
        ),
    )
