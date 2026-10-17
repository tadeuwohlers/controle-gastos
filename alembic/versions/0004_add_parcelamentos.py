"""add parcelamentos

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-17
"""

import sqlalchemy as sa
from alembic import op

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "parcelamentos",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("descricao", sa.String(255), nullable=False),
        sa.Column("valor_total", sa.Numeric(12, 2), nullable=False),
        sa.Column("num_parcelas", sa.Integer(), nullable=False),
        sa.Column("primeira_parcela", sa.Date(), nullable=False),
        sa.Column("conta_id", sa.Integer(), nullable=False),
        sa.Column("categoria_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(9), nullable=False, server_default="ativo"),
        sa.Column(
            "criado_em",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "atualizado_em",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint("valor_total > 0", name="chk_parcelamento_valor_positivo"),
        sa.CheckConstraint("num_parcelas >= 2", name="chk_parcelamento_num_parcelas"),
        sa.CheckConstraint(
            "status IN ('ativo', 'cancelado')", name="chk_parcelamento_status"
        ),
        sa.ForeignKeyConstraint(["conta_id"], ["contas.id"]),
        sa.ForeignKeyConstraint(["categoria_id"], ["categorias.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    # Adiciona FK de transacoes → parcelamentos (diferida da migration 0003)
    op.create_foreign_key(
        "fk_transacoes_parcelamentos",
        "transacoes",
        "parcelamentos",
        ["parcelamento_id"],
        ["id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_transacoes_parcelamentos", "transacoes", type_="foreignkey"
    )
    op.drop_table("parcelamentos")
