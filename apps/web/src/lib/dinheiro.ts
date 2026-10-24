const ENTRADA_BR = /^(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{0,2}))?$/;

/** "1.234,56" -> "1234.56". Puramente textual; null se inválido. */
export function parseValorBR(entrada: string): string | null {
  const m = ENTRADA_BR.exec(entrada.trim());
  if (!m) return null;
  const inteiro = m[1].replaceAll(".", "").replace(/^0+(?=\d)/, "");
  if (inteiro.length > 10) return null;
  const centavos = (m[2] ?? "").padEnd(2, "0");
  if (/^0*$/.test(inteiro + centavos)) return null;
  return `${inteiro}.${centavos}`;
}

const brl = new Intl.NumberFormat("pt-BR", {
  style: "currency",
  currency: "BRL",
});

/** "1234.56" -> "R$ 1.234,56". Único lugar onde `Number` é permitido. */
export function formatBRL(valor: string): string {
  return brl.format(Number(valor)).replace(/ /g, " ");
}

export function sinal(valor: string): "positivo" | "negativo" | "zero" {
  if (/^-?[0.]*$/.test(valor)) return "zero";
  return valor.startsWith("-") ? "negativo" : "positivo";
}
