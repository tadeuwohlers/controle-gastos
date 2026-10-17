# 001 — Controle de Gastos Pessoal

**Autor:** Tadeu Wohlers  
**Data:** 2026-10-17  
**Status:** Rascunho

---

## Problema

O usuário controla gastos pessoais via planilhas eletrônicas. Planilhas são trabalhosas de manter, não suportam parcelamento automático, e não permitem consultas programáticas ou integração com outras ferramentas. O resultado é perda de visibilidade sobre onde o dinheiro vai e quanto ainda será comprometido por compras parceladas futuras.

---

## Resultado desejado

Uma REST API local em Python que permita:

1. **Registrar e consultar Transações** — Gastos e Receitas associados a uma Conta e a uma Categoria tipada, com data de competência.
2. **Gerenciar Parcelamentos** — Registrar uma compra parcelada informando valor, número de parcelas e mês/ano da primeira parcela; o sistema gera as Parcelas automaticamente como Gastos nos meses corretos. Um Parcelamento tem status explícito (`ativo` / `cancelado`). Ao cancelar, as Parcelas cujo mês de competência é posterior ao mês atual são removidas; a Parcela do mês atual e todas as passadas são preservadas.
3. **Editar Transações** — Atualizar campos de um Gasto ou Receita já registrado via PUT/PATCH simples, sem histórico de mudanças.
4. **Gerenciar entidades de suporte** — Criar e listar Contas (ex: "Nubank", "Itaú Corrente") e Categorias tipadas (domínio Gasto ou Receita).
5. **Consultar relatórios**:
   - Balanço Mensal: total de Receitas − total de Gastos em um mês/ano de competência.
   - Gastos por Categoria: breakdown de Gastos em um mês/ano de competência, agrupado por Categoria.
   - Parcelas Ativas: lista de todas as Parcelas de Parcelamentos com status `ativo` cujo mês de competência é igual ou posterior ao mês atual.

O cliente principal é o Postman; a API expõe documentação OpenAPI automática via FastAPI.

---

## Usuários e sistemas afetados

| Ator | Papel |
|---|---|
| Tadeu Wohlers | Único usuário — registra e consulta todas as transações |
| Postman | Cliente HTTP para todas as chamadas à API |
| PostgreSQL (local) | Armazenamento persistente de todos os dados |

---

## Restrições

- **Linguagem:** Python 3.12+
- **Framework HTTP:** FastAPI
- **ORM / Migrações:** SQLAlchemy + Alembic
- **Banco de dados:** PostgreSQL (instância local)
- **Usuário único:** sem autenticação ou controle de acesso no MVP
- **Categorias:** lista plana, sem hierarquia; cada Categoria pertence exclusivamente ao domínio Gasto ou Receita
- **Balanço por competência:** toda Transação é contabilizada pelo mês/ano em que ocorreu, não pelo mês de pagamento efetivo
- **Parcelamento:** o usuário informa explicitamente o mês/ano da primeira Parcela ao criar um Parcelamento; Parcelamento possui status explícito `ativo` / `cancelado`
- **Cancelamento de Parcelamento:** remove Parcelas com competência estritamente futura; Parcela do mês corrente e passadas são preservadas
- **Edição de Transações:** suporte a PUT/PATCH simples sem log de mudanças
- **Conta obrigatória:** toda Transação (Gasto ou Receita) deve estar associada a uma Conta

---

## Fora de escopo (MVP)

- Orçamento por categoria e alertas de limite
- Importação de dados das planilhas existentes
- Categorias hierárquicas
- Autenticação e autorização *(prevista para quando a API for hospedada remotamente)*
- Deploy em servidor remoto ou nuvem
- Interface gráfica / frontend / TUI
- Relatórios de comparação entre meses
- Histórico de edições de transações

---

## Perguntas em aberto

1. **Valor do Parcelamento e arredondamento de centavos.** O valor informado é o total ou o valor de cada parcela? R$ 100,00 em 3× resulta em 33,33 + 33,33 + 33,34 — quem fica com o centavo? *(Pode ser resolvida no Design; manter aberta até lá.)*
   - *Decisão:* —

2. **Conta e Categoria do Parcelamento.** As Parcelas são Gastos, e todo Gasto exige Conta e Categoria; o documento não diz de onde elas vêm. Hipótese: são informadas no Parcelamento e herdadas por todas as suas Parcelas.
   - *Decisão:* —

3. **Editar e excluir Transações.** O documento prevê edição, mas não exclusão, e o fora de escopo também não menciona. Falta também definir o que ocorre ao editar uma Parcela individual (o total do Parcelamento desalinha?). Sugestão: exclusão de Transação avulsa entra no MVP; Parcelas só se alteram via Parcelamento.
   - *Decisão:* —

4. **Contas e Categorias — operações além de criar/listar.** Renomear, excluir e desativar ficam explicitamente fora do MVP?
   - *Decisão:* —

5. **Fuso horário e controle de "hoje".** Cancelamento e Parcelas Ativas dependem da data corrente; o fuso relevante é `America/Sao_Paulo`. Isso também afeta os testes, que precisam controlar o "hoje".
   - *Decisão:* —

6. **Moeda e consultas de Transações.** A API suporta apenas BRL? A listagem de Transações terá filtros (mês, conta, categoria) e paginação?
   - *Decisão:* —
