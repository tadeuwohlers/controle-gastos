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
