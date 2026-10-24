import { describe, expect, it } from "vitest";
import { extrairMensagem } from "./erros";

const PADRAO = "Algo deu errado. Tente de novo.";

describe("extrairMensagem", () => {
  it("devolve detail string", () => {
    expect(extrairMensagem({ detail: "Parcelamento já cancelado." })).toBe(
      "Parcelamento já cancelado.",
    );
  });
  it("junta msgs de lista e remove prefixo Value error", () => {
    expect(
      extrairMensagem({
        detail: [
          { loc: ["body", "valor"], msg: "Value error, valor deve ser positivo" },
          { loc: ["body", "descricao"], msg: "Field required" },
        ],
      }),
    ).toBe("valor deve ser positivo\nField required");
  });
  it.each([[null], [undefined], ["x"], [42], [{}], [{ detail: 1 }], [{ detail: [] }], [{ detail: [{}] }]])(
    "cai no padrão para %j",
    (corpo) => {
      expect(extrairMensagem(corpo)).toBe(PADRAO);
    },
  );
});
