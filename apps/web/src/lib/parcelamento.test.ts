import { describe, expect, it } from "vitest";
import { lerStatus, previaCancelamento, validarParcelado } from "./parcelamento";
import type { EstadoForm } from "./transacao-form";

const base: EstadoForm = {
  tipo: "gasto",
  valor: "100",
  descricao: " Notebook ",
  competencia: "2026-10",
  contaId: "1",
  categoriaId: "2",
};

describe("previaCancelamento", () => {
  const parcelas = ["2026-09", "2026-10", "2026-11", "2026-12"].map((competencia) => ({ competencia }));
  it("remove só as posteriores ao mês corrente", () => {
    expect(previaCancelamento(parcelas, "2026-10")).toEqual({ removidas: 2, preservadas: 2 });
  });
  it("sem futuras, nada é removido", () => {
    expect(previaCancelamento(parcelas, "2026-12")).toEqual({ removidas: 0, preservadas: 4 });
  });
  it("tudo futuro", () => {
    expect(previaCancelamento(parcelas, "2026-01")).toEqual({ removidas: 4, preservadas: 0 });
  });
  it("compara na virada de ano", () => {
    expect(previaCancelamento([{ competencia: "2027-01" }], "2026-12").removidas).toBe(1);
  });
});

describe("validarParcelado", () => {
  it("monta o payload com valor total como string", () => {
    expect(validarParcelado(base, "3")).toEqual({
      ok: true,
      payload: {
        descricao: "Notebook",
        valor_total: "100.00",
        num_parcelas: 3,
        primeira_parcela: "2026-10",
        conta_id: 1,
        categoria_id: 2,
      },
    });
  });
  it.each(["", "1", "0", "2,5", "abc", "-3"])("rejeita parcelas %j", (n) => {
    const r = validarParcelado(base, n);
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.erros.numParcelas).toBeDefined();
  });
  it("aponta os demais campos", () => {
    const r = validarParcelado({ ...base, valor: "0", descricao: "", contaId: "", categoriaId: "", competencia: "" }, "3");
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(Object.keys(r.erros).sort()).toEqual(["categoriaId", "competencia", "contaId", "descricao", "valor"]);
    }
  });
});

describe("lerStatus", () => {
  it("aceita ativo/cancelado e ignora o resto", () => {
    expect(lerStatus("ativo")).toBe("ativo");
    expect(lerStatus(["cancelado", "x"])).toBe("cancelado");
    expect(lerStatus("foo")).toBeNull();
    expect(lerStatus(undefined)).toBeNull();
  });
});
