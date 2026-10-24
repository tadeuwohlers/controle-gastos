import { describe, expect, it } from "vitest";
import { agruparPorCompetencia, larguraBarra } from "./resumo";

describe("larguraBarra", () => {
  it("é 100 para o maior e proporcional para os demais", () => {
    expect(larguraBarra("200.00", "200.00")).toBe(100);
    expect(larguraBarra("50.00", "200.00")).toBe(25);
  });
  it("devolve 0 quando o maior é zero ou inválido", () => {
    expect(larguraBarra("0.00", "0.00")).toBe(0);
    expect(larguraBarra("10.00", "abc")).toBe(0);
  });
  it("limita ao intervalo 0-100", () => {
    expect(larguraBarra("300.00", "200.00")).toBe(100);
    expect(larguraBarra("-5.00", "200.00")).toBe(0);
  });
});

describe("agruparPorCompetencia", () => {
  it("agrupa em ordem cronológica preservando a ordem interna", () => {
    const r = agruparPorCompetencia([
      { competencia: "2026-12", id: 1 },
      { competencia: "2026-11", id: 2 },
      { competencia: "2026-12", id: 3 },
    ]);
    expect(r).toEqual([
      { competencia: "2026-11", itens: [{ competencia: "2026-11", id: 2 }] },
      {
        competencia: "2026-12",
        itens: [
          { competencia: "2026-12", id: 1 },
          { competencia: "2026-12", id: 3 },
        ],
      },
    ]);
  });
  it("lista vazia gera nenhum grupo", () => {
    expect(agruparPorCompetencia([])).toEqual([]);
  });
});
