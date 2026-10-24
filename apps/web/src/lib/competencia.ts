const FORMATO = /^(\d{4})-(0[1-9]|1[0-2])$/;

export function valida(c: string): boolean {
  return FORMATO.test(c);
}

export function competenciaAtual(): string {
  const partes = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Sao_Paulo",
    year: "numeric",
    month: "2-digit",
  }).formatToParts(new Date());
  const ano = partes.find((p) => p.type === "year")!.value;
  const mes = partes.find((p) => p.type === "month")!.value;
  return `${ano}-${mes}`;
}

export function deslocar(c: string, n: number): string {
  const [ano, mes] = c.split("-").map(Number);
  const total = ano * 12 + (mes - 1) + n;
  const novoAno = Math.floor(total / 12);
  const novoMes = (total % 12) + 1;
  return `${String(novoAno).padStart(4, "0")}-${String(novoMes).padStart(2, "0")}`;
}

export function formatar(c: string): string {
  const [ano, mes] = c.split("-").map(Number);
  const nome = new Intl.DateTimeFormat("pt-BR", {
    month: "long",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(ano, mes - 1, 1)));
  return `${nome} de ${ano}`;
}

export function comparar(a: string, b: string): -1 | 0 | 1 {
  return a < b ? -1 : a > b ? 1 : 0;
}
