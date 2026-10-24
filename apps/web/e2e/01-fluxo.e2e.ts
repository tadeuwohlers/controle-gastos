import { expect, test, type Page } from "@playwright/test";
import { competenciaAtual, deslocar } from "../src/lib/competencia";

// Banco vazio (recriado por `scripts.recriar_banco_teste`) → um único fluxo encadeado.

const mes = competenciaAtual();
const proximo = deslocar(mes, 1);
const gaveta = (page: Page) => page.getByRole("dialog", { name: "Nova transação" });

async function abrirGavetaComN(page: Page) {
  await page.keyboard.press("n");
  await expect(gaveta(page)).toBeVisible();
}

test("do banco vazio ao cancelamento de um Parcelamento", async ({ page }) => {
  await page.goto("/transacoes");
  await expect(page.getByText("Nenhuma transação neste mês.")).toBeVisible();

  // 1. Conta e Categoria de Gasto inline + Gasto.
  await abrirGavetaComN(page);
  const g = gaveta(page);
  await g.getByRole("button", { name: "Criar conta", exact: true }).click();
  await g.getByLabel("Nome da Conta").fill("Nubank");
  await g.getByRole("button", { name: "Criar conta" }).last().click();
  await expect(g.getByRole("combobox", { name: /^Conta/ })).toHaveValue(/\d+/);

  await g.getByRole("button", { name: "Criar categoria", exact: true }).click();
  await g.getByLabel("Nome da Categoria").fill("Alimentação");
  await g.getByRole("button", { name: "Criar categoria" }).last().click();
  await expect(g.getByRole("combobox", { name: /^Categoria/ })).toHaveValue(/\d+/);

  await g.getByLabel("Valor", { exact: true }).fill("50,00");
  await g.getByLabel("Descrição").fill("Mercado");
  await g.getByRole("button", { name: "Salvar", exact: true }).click();
  await expect(gaveta(page)).toBeHidden();
  await expect(page.getByRole("listitem").filter({ hasText: "Mercado" })).toContainText("− R$ 50,00");

  // 2. Categoria de Receita inline + Receita.
  await abrirGavetaComN(page);
  await g.getByLabel("Receita", { exact: true }).check();
  await g.getByRole("button", { name: "Criar categoria", exact: true }).click();
  await g.getByLabel("Nome da Categoria").fill("Salário");
  await g.getByRole("button", { name: "Criar categoria" }).last().click();
  await g.getByLabel("Valor", { exact: true }).fill("1.000,00");
  await g.getByLabel("Descrição").fill("Salário do mês");
  await g.getByRole("button", { name: "Salvar", exact: true }).click();
  await expect(gaveta(page)).toBeHidden();
  await expect(page.getByRole("listitem").filter({ hasText: "Salário do mês" })).toContainText("+ R$ 1.000,00");

  // 3. Parcelamento de R$ 100,00 em 3×, primeira parcela no mês corrente.
  await abrirGavetaComN(page);
  await g.getByLabel("Parcelado").check();
  await g.getByRole("button", { name: "Criar categoria", exact: true }).click();
  await g.getByLabel("Nome da Categoria").fill("Eletrônicos");
  await g.getByRole("button", { name: "Criar categoria" }).last().click();
  await g.getByLabel("Valor total").fill("100,00");
  await g.getByLabel("Descrição").fill("Fone de ouvido");
  await g.getByLabel("Número de parcelas").fill("3");
  await expect(g.getByLabel("Primeira parcela")).toHaveValue(mes);
  await g.getByRole("button", { name: "Salvar", exact: true }).click();

  await expect(page).toHaveURL(/\/parcelamentos\/\d+$/);
  await expect(page.getByRole("heading", { name: /Fone de ouvido/ })).toBeVisible();
  const linhas = page.getByRole("table", { name: "Parcelas" }).getByRole("row");
  await expect(linhas).toHaveCount(4); // cabeçalho + 3
  await expect(linhas.nth(1)).toContainText("1/3");
  await expect(linhas.nth(1)).toContainText("R$ 33,33");
  await expect(linhas.nth(2)).toContainText("R$ 33,33");
  await expect(linhas.nth(3)).toContainText("3/3");
  await expect(linhas.nth(3)).toContainText("R$ 33,34");

  // 4. Resumo do mês corrente.
  await page.getByRole("link", { name: "Resumo", exact: true }).click();
  await expect(page.getByRole("heading", { name: "Balanço Mensal" })).toBeVisible();
  const balanco = page.getByRole("region", { name: "Balanço Mensal" });
  await expect(balanco.locator("div").filter({ hasText: /^Receitas/ })).toContainText("R$ 1.000,00");
  await expect(balanco.locator("div").filter({ hasText: /^Gastos/ })).toContainText("R$ 83,33");
  await expect(balanco.locator("div").filter({ hasText: /^Saldo/ })).toContainText("R$ 916,67");
  const porCategoria = page.getByRole("region", { name: "Gastos por Categoria" });
  await expect(porCategoria.getByRole("listitem").filter({ hasText: "Alimentação" })).toContainText("R$ 50,00");
  await expect(porCategoria.getByRole("listitem").filter({ hasText: "Eletrônicos" })).toContainText("R$ 33,33");

  // 5. Cancelamento: a 1ª parcela fica, as demais somem.
  await page.getByRole("link", { name: /Fone de ouvido/ }).first().click();
  await page.getByRole("button", { name: "Cancelar parcelamento" }).click();
  const dialogo = page.getByRole("dialog", { name: "Cancelar parcelamento?" });
  await expect(dialogo).toContainText("2 parcelas futuras");
  await dialogo.getByRole("button", { name: "Cancelar parcelamento" }).click();
  await expect(page.getByRole("status")).toContainText("2 parcelas futuras removidas; 1 preservada");
  await expect(page.getByRole("button", { name: "Cancelar parcelamento" })).toHaveCount(0);

  await page.goto(`/transacoes?mes=${mes}`);
  await expect(page.getByRole("listitem").filter({ hasText: "Fone de ouvido" })).toContainText("R$ 33,33");
  await page.goto(`/transacoes?mes=${proximo}`);
  await expect(page.getByText("Nenhuma transação neste mês.")).toBeVisible();
  await page.goto(`/transacoes?mes=${deslocar(mes, 2)}`);
  await expect(page.getByText("Nenhuma transação neste mês.")).toBeVisible();
});
