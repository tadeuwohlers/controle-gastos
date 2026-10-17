"""add categorias

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-17
"""

import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "categorias",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("nome", sa.String(100), nullable=False),
        sa.Column("tipo", sa.String(7), nullable=False),
        sa.Column(
            "criada_em",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint("tipo IN ('gasto', 'receita')", name="chk_categoria_tipo"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("nome"),
    )


def downgrade() -> None:
    op.drop_table("categorias")
