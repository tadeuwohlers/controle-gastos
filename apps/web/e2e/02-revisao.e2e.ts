import { expect, test, type APIRequestContext, type Page } from "@playwright/test";
import { competenciaAtual } from "../src/lib/competencia";

// Casos que o fluxo único não cobre: erros reais da API, falhas de rede/5xx,
// filtros e layout mobile. Cada teste cria os próprios dados (nomes únicos) direto na API.

const API = "http://localhost:8100/api/v1";
const mes = competenciaAtual();
let n = 0;
const unico = (base: string) => `${base} ${Date.now()}-${++n}`;

async function criarConta(api: APIRequestContext, nome = unico("Conta")) {
  const r = await api.post(`${API}/contas`, { data: { nome } });
  return (await r.json()) as { id: number; nome: string };
}
async function criarCategoria(api: APIRequestContext, tipo: "gasto" | "receita", nome = unico("Cat")) {
  const r = await api.post(`${API}/categorias`, { data: { nome, tipo } });
  return (await r.json()) as { id: number; nome: string };
}
async function criarParcelamento(api: APIRequestContext, descricao = unico("Parcelado")) {
  const conta = await criarConta(api);
  const cat = await criarCategoria(api, "gasto");
  const r = await api.post(`${API}/parcelamentos`, {
    data: {
      descricao,
      valor_total: "100.00",
      num_parcelas: 3,
      primeira_parcela: mes,
      conta_id: conta.id,
      categoria_id: cat.id,
    },
  });
  return { ...((await r.json()) as { id: number }), descricao, conta, cat };
}

// O Next injeta um role=alert próprio (anunciador de rotas); ignoramos.
const alertas = (l: Page | import("@playwright/test").Locator) =>
  l.locator('[role="alert"]:not(#__next-route-announcer__)');
const gaveta = (page: Page) => page.getByRole("dialog", { name: "Nova transação" });

test("cancelar um Parcelamento já cancelado em outra aba mostra a mensagem da API", async ({ page, request }) => {
  const p = await criarParcelamento(request);
  await page.goto(`/parcelamentos/${p.id}`);
  await page.getByRole("button", { name: "Cancelar parcelamento" }).click();
  // Outra aba cancela antes da confirmação.
  expect((await request.post(`${API}/parcelamentos/${p.id}/cancelar`)).ok()).toBe(true);
  await page
    .getByRole("dialog", { name: "Cancelar parcelamento?" })
    .getByRole("button", { name: "Cancelar parcelamento" })
    .click();
  // A página recarrega (status vira cancelado, botão some) e a mensagem continua visível.
  await expect(page.getByText("cancelado", { exact: true })).toBeVisible();
  await expect(page.getByRole("button", { name: "Cancelar parcelamento" })).toHaveCount(0);
  await expect(alertas(page)).toContainText("Parcelamento já cancelado.");
});

test("falha de rede no cancelamento oferece 'Tentar de novo' e reenvia", async ({ page, request }) => {
  const p = await criarParcelamento(request);
  await page.goto(`/parcelamentos/${p.id}`);
  let falhou = false;
  await page.route("**/parcelamentos/*/cancelar", (route) => {
    if (!falhou) {
      falhou = true;
      return route.abort("failed");
    }
    return route.continue();
  });
  await page.getByRole("button", { name: "Cancelar parcelamento" }).click();
  const d = page.getByRole("dialog", { name: "Cancelar parcelamento?" });
  await d.getByRole("button", { name: "Cancelar parcelamento" }).click();
  await expect(alertas(d)).toContainText("Não foi possível falar com o servidor");
  await d.getByRole("button", { name: "Tentar de novo" }).click();
  await expect(page.getByRole("status")).toContainText("2 parcelas futuras removidas");
});

test("5xx ao salvar mantém o formulário e 'Tentar de novo' reenvia o mesmo payload", async ({ page, request }) => {
  const conta = await criarConta(request);
  const cat = await criarCategoria(request, "gasto");
  await page.goto("/transacoes");
  await page.keyboard.press("n");
  const g = gaveta(page);
  await g.getByRole("combobox", { name: /^Conta/ }).selectOption(String(conta.id));
  await g.getByRole("combobox", { name: /^Categoria/ }).selectOption(String(cat.id));
  await g.getByLabel("Valor", { exact: true }).fill("12,30");
  const descricao = unico("Lanche");
  await g.getByLabel("Descrição").fill(descricao);
  let falhou = false;
  await page.route("**/api/v1/transacoes", (route) => {
    if (route.request().method() === "POST" && !falhou) {
      falhou = true;
      return route.fulfill({ status: 500, body: "boom" });
    }
    return route.continue();
  });
  await g.getByRole("button", { name: "Salvar", exact: true }).click();
  await expect(alertas(g)).toContainText("Não foi possível falar com o servidor");
  await expect(g.getByLabel("Descrição")).toHaveValue(descricao);
  await g.getByRole("button", { name: "Tentar de novo" }).click();
  await expect(g).toBeHidden();
  await expect(page.getByRole("listitem").filter({ hasText: descricao })).toContainText("R$ 12,30");
});

test("409 de Conta duplicada aparece inline em /cadastros e na gaveta", async ({ page, request }) => {
  const conta = await criarConta(request);
  await page.goto("/cadastros");
  await page.getByLabel("Nome da Conta").fill(conta.nome);
  await page.getByRole("button", { name: "Criar conta" }).click();
  await expect(alertas(page)).toContainText(/já existe/i);

  await page.keyboard.press("n");
  const g = gaveta(page);
  await g.getByRole("button", { name: "Criar conta", exact: true }).click();
  await g.getByLabel("Nome da Conta").fill(conta.nome);
  await g.getByRole("button", { name: "Criar conta" }).last().click();
  await expect(alertas(g)).toContainText(/já existe/i);
  await expect(g.getByLabel("Nome da Conta")).toHaveValue(conta.nome);
});

test("422 do Pydantic é normalizado (sem 'Value error, ') na gaveta", async ({ page, request }) => {
  const invalida = await request.post(`${API}/contas`, { data: { nome: "   " } });
  expect(invalida.status()).toBe(422);
  const corpo = await invalida.json();
  await page.route("**/api/v1/contas", (route) =>
    route.request().method() === "POST"
      ? route.fulfill({ status: 422, json: corpo })
      : route.continue(),
  );
  await page.goto("/cadastros");
  await page.getByLabel("Nome da Conta").fill("x");
  await page.getByRole("button", { name: "Criar conta" }).click();
  const alerta = alertas(page);
  await expect(alerta).toContainText("nome não pode ser vazio ou apenas espaços");
  await expect(alerta).not.toContainText("Value error");
});

test("filtros de /transacoes (tipo, conta, categoria) e valores inválidos na URL", async ({ page, request }) => {
  const conta1 = await criarConta(request, unico("ContaA"));
  const conta2 = await criarConta(request, unico("ContaB"));
  const gasto = await criarCategoria(request, "gasto", unico("CatGasto"));
  const receita = await criarCategoria(request, "receita", unico("CatReceita"));
  const mk = (descricao: string, tipo: "gasto" | "receita", conta: number, cat: number) =>
    request.post(`${API}/transacoes`, {
      data: { tipo, valor: "10.00", descricao, competencia: mes, conta_id: conta, categoria_id: cat },
    });
  await mk("fx-gasto-a", "gasto", conta1.id, gasto.id);
  await mk("fx-gasto-b", "gasto", conta2.id, gasto.id);
  await mk("fx-receita-a", "receita", conta1.id, receita.id);

  await page.goto(`/transacoes?mes=${mes}`);
  const item = (t: string) => page.getByRole("listitem").filter({ hasText: t });
  await expect(item("fx-gasto-a")).toBeVisible();

  await page.getByRole("combobox", { name: /^Tipo/ }).selectOption("receita");
  await expect(item("fx-receita-a")).toBeVisible();
  await expect(item("fx-gasto-a")).toHaveCount(0);
  await expect(page).toHaveURL(/tipo=receita/);

  await page.getByRole("combobox", { name: /^Tipo/ }).selectOption("");
  await page.getByRole("combobox", { name: /^Conta/ }).selectOption(String(conta2.id));
  await expect(item("fx-gasto-b")).toBeVisible();
  await expect(item("fx-gasto-a")).toHaveCount(0);

  await page.getByRole("combobox", { name: /^Conta/ }).selectOption("");
  await page.getByRole("combobox", { name: /^Categoria/ }).selectOption(String(receita.id));
  await expect(item("fx-receita-a")).toBeVisible();
  await expect(item("fx-gasto-a")).toHaveCount(0);

  await page.goto("/transacoes?mes=lixo&tipo=xx&conta=abc&categoria=-1");
  await expect(page.getByRole("heading", { name: "Transações" })).toBeVisible();
  await expect(item("fx-gasto-a")).toBeVisible();
});

test.describe("mobile (375×812)", () => {
  test.use({ viewport: { width: 375, height: 812 } });

  test("navegação inferior, sem rolagem horizontal e gaveta em tela cheia", async ({ page, request }) => {
    await criarParcelamento(request);
    for (const rota of ["/", "/transacoes", "/parcelamentos", "/cadastros"]) {
      await page.goto(rota);
      await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
      const sobra = await page.evaluate(
        () => document.documentElement.scrollWidth - document.documentElement.clientWidth,
      );
      expect(sobra, `rolagem horizontal em ${rota}`).toBeLessThanOrEqual(0);
    }
    const nav = page.getByRole("navigation", { name: "Principal" });
    const caixa = (await nav.boundingBox())!;
    expect(caixa.y + caixa.height).toBeGreaterThan(800); // colada no rodapé

    await page.keyboard.press("n");
    const g = gaveta(page);
    await expect(g).toBeVisible();
    const gc = (await g.boundingBox())!;
    expect(gc.width).toBeGreaterThanOrEqual(374);
    expect(gc.height).toBeGreaterThanOrEqual(811);
    await page.keyboard.press("Escape");
    await expect(g).toBeHidden();
  });
});

test("gaveta: Esc fecha e o foco fica preso no diálogo", async ({ page }) => {
  await page.goto("/transacoes");
  await page.keyboard.press("n");
  const g = gaveta(page);
  await expect(g).toBeVisible();
  for (let i = 0; i < 25; i++) {
    await page.keyboard.press("Tab");
    // Fora do diálogo o foco só pode ir para o navegador (activeElement vira o body), nunca para a página inerte.
    const foco = await page.evaluate(() => {
      const a = document.activeElement;
      return a === document.body || a?.closest("dialog") != null;
    });
    expect(foco).toBe(true);
  }
  await page.keyboard.press("Escape");
  await expect(g).toBeHidden();
});
