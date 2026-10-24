import { describe, expect, it } from "vitest";
import { lerFiltros } from "./filtros";

describe("lerFiltros", () => {
  it("lê valores válidos", () => {
    expect(lerFiltros({ mes: "2026-03", tipo: "receita", conta: "2", categoria: "9" })).toEqual({
      mes: "2026-03",
      tipo: "receita",
      contaId: 2,
      categoriaId: 9,
    });
  });
  it("ignora valores inválidos", () => {
    const f = lerFiltros({ mes: "2026-13", tipo: "x", conta: "abc", categoria: "0" });
    expect(f.tipo).toBeNull();
    expect(f.contaId).toBeNull();
    expect(f.categoriaId).toBeNull();
    expect(f.mes).toMatch(/^\d{4}-\d{2}$/);
    expect(f.mes).not.toBe("2026-13");
  });
  it("usa o primeiro de parâmetros repetidos", () => {
    expect(lerFiltros({ conta: ["3", "4"] }).contaId).toBe(3);
  });
});
