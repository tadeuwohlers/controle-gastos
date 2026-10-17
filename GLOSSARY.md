# Glossary

## Balanço Mensal

The net result of all income minus all expenses within a calendar month. Positive means surplus; negative means deficit.

## Categoria

A user-defined label used to classify a Transação. Categories are typed: a category belongs to either the Gasto domain or the Receita domain, and cannot be used for the other.

## Competência

The month/year in which a Transação is considered to have occurred, used as the basis for the Balanço Mensal. For a Parcelamento, each Parcela's competência is the month it falls due, not the month the original purchase was made.

## Conta

A user-managed entity representing a financial account or credit card (e.g., "Nubank", "Itaú Corrente"). Created and maintained via the API. Every Transação is associated with a Conta.

## Gasto

A money-outflow transaction recorded by the user. May be a one-time payment or a single Parcela of a Parcelamento.

## Parcela

A single monthly installment that is part of a Parcelamento. Each Parcela is treated as a Gasto in the month it falls due.

## Parcelamento

A purchase split into multiple monthly Parcelas (e.g., a R$ 1,200 purchase in 12× R$ 100). The system tracks the original purchase and auto-generates the individual Parcelas. Has an explicit status: `ativo` or `cancelado`. Cancelling removes only Parcelas with a competência strictly in the future; the current month's and past Parcelas are preserved.

## Receita

A money-inflow transaction recorded by the user (e.g., salary, freelance payment). Counted against Gastos to produce the Balanço Mensal.

## Transação

Umbrella term for any recorded financial event — either a Gasto or a Receita. Every Transação is associated with exactly one Conta and one Categoria of the matching type.

---

## Balanço Mensal / Monthly Balance

`total_receitas − total_gastos` for a given Competência. Positive = surplus; negative = deficit.

## Cancelamento / Cancellation

The act of setting a Parcelamento's status to `cancelado`. Removes all Parcelas whose Competência is strictly in the future (relative to the current month in `America/Sao_Paulo`); preserves the current month's and all past Parcelas.

## Competência / Competence Month

The month/year (stored as `YYYY-MM-01`) in which a Transação is accounted. For a Parcelamento, each Parcela's Competência is the month it falls due, not the month the original purchase was made.

## get_today()

An injectable dependency (FastAPI `Depends`) that returns today's date in the `America/Sao_Paulo` timezone. Tests override it via `app.dependency_overrides` to control the notion of "now."

## Parcelas Ativas / Active Installments

A report listing all Parcelas belonging to `ativo` Parcelamentos whose Competência is equal to or later than the current month.

## Transação Avulsa / Standalone Transaction

A Gasto or Receita that is not linked to any Parcelamento (`parcelamento_id IS NULL`). Only standalone transactions may be edited or deleted directly; Parcelas are managed exclusively through their Parcelamento.

## Valor Total / Total Amount

The full purchase amount entered when creating a Parcelamento. The system divides it into N installments: `floor(total * 100 / N) / 100` for the first N−1, with any remaining cent going to the last Parcela.
