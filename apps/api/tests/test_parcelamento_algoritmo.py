"""Unit tests do algoritmo puro de cálculo de parcelas (sem DB, sem I/O)."""

from datetime import date
from decimal import Decimal

import pytest

from controle_gastos.services.parcelamento import calcular_parcelas


def test_10_reais_em_3_parcelas_valores_corretos() -> None:
    result = calcular_parcelas(Decimal("10.00"), 3, date(2026, 10, 1))
    valores = [p["valor"] for p in result]
    assert valores == [Decimal("3.33"), Decimal("3.33"), Decimal("3.34")]


def test_10_reais_em_3_parcelas_soma_exata() -> None:
    result = calcular_parcelas(Decimal("10.00"), 3, date(2026, 10, 1))
    assert sum(p["valor"] for p in result) == Decimal("10.00")


def test_1_real_em_3_parcelas_valores_corretos() -> None:
    result = calcular_parcelas(Decimal("1.00"), 3, date(2026, 10, 1))
    valores = [p["valor"] for p in result]
    assert valores == [Decimal("0.33"), Decimal("0.33"), Decimal("0.34")]


def test_1_real_em_3_parcelas_soma_exata() -> None:
    result = calcular_parcelas(Decimal("1.00"), 3, date(2026, 10, 1))
    assert sum(p["valor"] for p in result) == Decimal("1.00")


def test_3600_em_12_parcelas_sem_residuo() -> None:
    result = calcular_parcelas(Decimal("3600.00"), 12, date(2026, 10, 1))
    assert all(p["valor"] == Decimal("300.00") for p in result)
    assert sum(p["valor"] for p in result) == Decimal("3600.00")


def test_999_99_em_7_parcelas_soma_exata() -> None:
    result = calcular_parcelas(Decimal("999.99"), 7, date(2026, 10, 1))
    assert sum(p["valor"] for p in result) == Decimal("999.99")


def test_ultima_parcela_absorve_residuo() -> None:
    result = calcular_parcelas(Decimal("10.00"), 3, date(2026, 10, 1))
    assert result[-1]["valor"] > result[0]["valor"]
    assert result[0]["valor"] == result[1]["valor"]


def test_competencia_sequencia_simples() -> None:
    result = calcular_parcelas(Decimal("100.00"), 3, date(2026, 10, 1))
    competencias = [p["competencia"] for p in result]
    assert competencias == [date(2026, 10, 1), date(2026, 11, 1), date(2026, 12, 1)]


def test_competencia_virada_de_ano() -> None:
    result = calcular_parcelas(Decimal("100.00"), 4, date(2026, 11, 1))
    competencias = [p["competencia"] for p in result]
    assert competencias == [
        date(2026, 11, 1),
        date(2026, 12, 1),
        date(2027, 1, 1),
        date(2027, 2, 1),
    ]


def test_numero_parcela_sequencial() -> None:
    result = calcular_parcelas(Decimal("100.00"), 5, date(2026, 10, 1))
    assert [p["numero"] for p in result] == [1, 2, 3, 4, 5]


def test_quantidade_correta_de_parcelas() -> None:
    result = calcular_parcelas(Decimal("100.00"), 7, date(2026, 10, 1))
    assert len(result) == 7


@pytest.mark.parametrize(
    "valor,n",
    [
        ("100.00", 2),
        ("100.00", 3),
        ("100.01", 3),
        ("999.99", 7),
        ("1.00", 12),
        ("3600.00", 12),
    ],
)
def test_soma_invariante_para_varios_casos(valor: str, n: int) -> None:
    v = Decimal(valor)
    result = calcular_parcelas(v, n, date(2026, 10, 1))
    assert sum(p["valor"] for p in result) == v
