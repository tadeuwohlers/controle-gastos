import { describe, expect, it } from "vitest";
import { formatBRL, parseValorBR, sinal } from "./dinheiro";

describe("parseValorBR", () => {
  it.each([
    ["1.234,56", "1234.56"],
    ["49,9", "49.90"],
    ["49", "49.00"],
    ["0,50", "0.50"],
    [" 10,00 ", "10.00"],
    ["9999999999,99", "9999999999.99"],
  ])("converte %j em %j", (entrada, esperado) => {
    expect(parseValorBR(entrada)).toBe(esperado);
  });

  it.each([
    ["0,00"],
    ["0"],
    ["-5"],
    ["1,234"],
    ["12345678901"],
    [""],
    ["   "],
    ["abc"],
    ["1,2,3"],
    ["12a"],
    [","],
  ])("rejeita %j", (entrada) => {
    expect(parseValorBR(entrada)).toBeNull();
  });
});

describe("formatBRL", () => {
  const norm = (s: string) => s.replace(/ /g, " ");
  it("formata positivo", () => {
    expect(norm(formatBRL("1234.56"))).toBe("R$ 1.234,56");
  });
  it("formata negativo com sinal na frente", () => {
    expect(norm(formatBRL("-100.00"))).toBe("-R$ 100,00");
  });
  it("formata zero", () => {
    expect(norm(formatBRL("0.00"))).toBe("R$ 0,00");
  });
});

describe("sinal", () => {
  it("positivo", () => expect(sinal("10.00")).toBe("positivo"));
  it("negativo", () => expect(sinal("-0.01")).toBe("negativo"));
  it("zero", () => {
    expect(sinal("0.00")).toBe("zero");
    expect(sinal("0")).toBe("zero");
  });
});
