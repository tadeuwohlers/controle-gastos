import { describe, expect, it } from "vitest";
import {
  contaPadrao,
  foiAtalhoNovaTransacao,
  validar,
  type EstadoForm,
} from "./transacao-form";
import { executar } from "./mutacao";

const base: EstadoForm = {
  tipo: "gasto",
  valor: "1.234,5",
  descricao: " Mercado ",
  competencia: "2026-10",
  contaId: "3",
  categoriaId: "7",
};

describe("validar", () => {
  it("monta o payload com valor como string", () => {
    expect(validar(base)).toEqual({
      ok: true,
      payload: {
        tipo: "gasto",
        valor: "1234.50",
        descricao: "Mercado",
        competencia: "2026-10",
        conta_id: 3,
        categoria_id: 7,
      },
    });
  });

  it("aponta cada campo inválido", () => {
    const r = validar({ ...base, valor: "0", descricao: " ", contaId: "", categoriaId: "", competencia: "" });
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(Object.keys(r.erros).sort()).toEqual(
        ["categoriaId", "competencia", "contaId", "descricao", "valor"],
      );
    }
  });
});

describe("contaPadrao", () => {
  const contas = [{ id: 1 }, { id: 2 }];
  it("usa a conta salva se existir", () => {
    expect(contaPadrao(contas, { getItem: () => "2" })).toBe("2");
  });
  it("ignora conta que não existe mais", () => {
    expect(contaPadrao(contas, { getItem: () => "9" })).toBe("");
  });
  it("ignora falha de leitura e ausência de storage", () => {
    expect(contaPadrao(contas, { getItem: () => { throw new Error("x"); } })).toBe("");
    expect(contaPadrao(contas, null)).toBe("");
  });
});

describe("foiAtalhoNovaTransacao", () => {
  const ev = (over: object) => ({
    key: "n", ctrlKey: false, metaKey: false, altKey: false, target: { tagName: "BODY" }, ...over,
  });
  it("dispara fora de campos", () => {
    expect(foiAtalhoNovaTransacao(ev({}))).toBe(true);
  });
  it("ignora campos de entrada e contenteditable", () => {
    for (const tagName of ["INPUT", "TEXTAREA", "SELECT"]) {
      expect(foiAtalhoNovaTransacao(ev({ target: { tagName } }))).toBe(false);
    }
    expect(foiAtalhoNovaTransacao(ev({ target: { tagName: "DIV", isContentEditable: true } }))).toBe(false);
  });
  it("ignora outras teclas e modificadores", () => {
    expect(foiAtalhoNovaTransacao(ev({ key: "m" }))).toBe(false);
    expect(foiAtalhoNovaTransacao(ev({ metaKey: true }))).toBe(false);
  });
});

describe("executar", () => {
  const resp = (status: number) => new Response(null, { status });
  it("sucesso", async () => {
    expect(await executar(async () => ({ data: 1, response: resp(201) }))).toEqual({ ok: true, data: 1 });
  });
  it("4xx vira mensagem inline", async () => {
    const r = await executar(async () => ({ error: { detail: "Conta não encontrada." }, response: resp(404) }));
    expect(r).toEqual({ ok: false, tipo: "formulario", mensagem: "Conta não encontrada." });
  });
  it("5xx e rede viram servidor", async () => {
    expect(await executar(async () => ({ error: {}, response: resp(503) }))).toEqual({ ok: false, tipo: "servidor" });
    expect(await executar(async () => { throw new TypeError("fetch"); })).toEqual({ ok: false, tipo: "servidor" });
  });
});
