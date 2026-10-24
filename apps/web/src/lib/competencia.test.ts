import { afterEach, describe, expect, it, vi } from "vitest";
import {
  comparar,
  competenciaAtual,
  deslocar,
  formatar,
  valida,
} from "./competencia";

describe("valida", () => {
  it.each(["2026-01", "2026-12", "1999-06"])("aceita %s", (c) => {
    expect(valida(c)).toBe(true);
  });
  it.each(["2026-00", "2026-13", "26-10", "2026-1", "2026/10", "", "abc", "2026-10-01"])(
    "rejeita %j",
    (c) => {
      expect(valida(c)).toBe(false);
    },
  );
});

describe("deslocar", () => {
  it("vira o ano para frente", () => expect(deslocar("2026-12", 1)).toBe("2027-01"));
  it("vira o ano para trás", () => expect(deslocar("2026-01", -1)).toBe("2025-12"));
  it("desloca vários meses", () => expect(deslocar("2026-10", 14)).toBe("2027-12"));
  it("zero mantém", () => expect(deslocar("2026-10", 0)).toBe("2026-10"));
});

describe("formatar", () => {
  it("escreve por extenso", () => {
    expect(formatar("2026-10")).toBe("outubro de 2026");
    expect(formatar("2027-03")).toBe("março de 2027");
  });
});

describe("comparar", () => {
  it("ordena cronologicamente", () => {
    expect(comparar("2026-09", "2026-10")).toBe(-1);
    expect(comparar("2027-01", "2026-12")).toBe(1);
    expect(comparar("2026-10", "2026-10")).toBe(0);
  });
});

describe("competenciaAtual", () => {
  afterEach(() => vi.useRealTimers());

  const em = (iso: string) => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(iso));
    return competenciaAtual();
  };

  it("usa o mês de São Paulo quando UTC já virou o mês", () => {
    // 01/nov 01:00 UTC = 31/out 22:00 em São Paulo (UTC-3)
    expect(em("2026-11-01T01:00:00Z")).toBe("2026-10");
  });
  it("usa o mês de São Paulo quando UTC já virou o ano", () => {
    expect(em("2027-01-01T02:59:59Z")).toBe("2026-12");
  });
  it("vira o mês exatamente à meia-noite de São Paulo", () => {
    expect(em("2026-11-01T03:00:00Z")).toBe("2026-11");
  });
  it("meio do mês", () => {
    expect(em("2026-10-15T12:00:00Z")).toBe("2026-10");
  });
});
