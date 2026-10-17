from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    TIMESTAMP,
    CheckConstraint,
    Date,
    ForeignKey,
    Integer,
    Numeric,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column

from controle_gastos.database import Base


class Transacao(Base):
    __tablename__ = "transacoes"

    id: Mapped[int] = mapped_column(primary_key=True)
    tipo: Mapped[str] = mapped_column(String(7), nullable=False)
    valor: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    descricao: Mapped[str] = mapped_column(String(255), nullable=False)
    competencia: Mapped[date] = mapped_column(Date(), nullable=False)
    conta_id: Mapped[int] = mapped_column(ForeignKey("contas.id"), nullable=False)
    categoria_id: Mapped[int] = mapped_column(ForeignKey("categorias.id"), nullable=False)
    # FK para parcelamentos diferida para Fase 4 (evita dependência circular na migration)
    parcelamento_id: Mapped[int | None] = mapped_column(Integer(), nullable=True)
    numero_parcela: Mapped[int | None] = mapped_column(Integer(), nullable=True)
    criada_em: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )
    atualizada_em: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        CheckConstraint("valor > 0", name="chk_transacao_valor_positivo"),
        CheckConstraint(
            "numero_parcela >= 1",
            name="chk_transacao_numero_parcela",
        ),
        CheckConstraint(
            "(parcelamento_id IS NULL AND numero_parcela IS NULL) OR "
            "(parcelamento_id IS NOT NULL AND numero_parcela IS NOT NULL)",
            name="chk_transacao_parcela_consistente",
        ),
        UniqueConstraint(
            "parcelamento_id",
            "numero_parcela",
            name="uq_transacao_parcelamento_numero",
        ),
    )
