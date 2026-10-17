"""add transacoes

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-17
"""

import sqlalchemy as sa
from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "transacoes",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tipo", sa.String(7), nullable=False),
        sa.Column("valor", sa.Numeric(12, 2), nullable=False),
        sa.Column("descricao", sa.String(255), nullable=False),
        sa.Column("competencia", sa.Date(), nullable=False),
        sa.Column("conta_id", sa.Integer(), nullable=False),
        sa.Column("categoria_id", sa.Integer(), nullable=False),
        # parcelamento_id: FK adicionada na migration 0004 após criar parcelamentos
        sa.Column("parcelamento_id", sa.Integer(), nullable=True),
        sa.Column("numero_parcela", sa.Integer(), nullable=True),
        sa.Column(
            "criada_em",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "atualizada_em",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint("valor > 0", name="chk_transacao_valor_positivo"),
        sa.CheckConstraint(
            "numero_parcela >= 1",
            name="chk_transacao_numero_parcela",
        ),
        sa.CheckConstraint(
            "(parcelamento_id IS NULL AND numero_parcela IS NULL) OR "
            "(parcelamento_id IS NOT NULL AND numero_parcela IS NOT NULL)",
            name="chk_transacao_parcela_consistente",
        ),
        sa.ForeignKeyConstraint(["conta_id"], ["contas.id"]),
        sa.ForeignKeyConstraint(["categoria_id"], ["categorias.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "parcelamento_id", "numero_parcela", name="uq_transacao_parcelamento_numero"
        ),
    )


def downgrade() -> None:
    op.drop_table("transacoes")
