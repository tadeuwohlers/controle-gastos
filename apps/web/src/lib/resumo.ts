import { comparar } from "./competencia";

/** Largura da barra em % (0-100), só visual. Único uso de `Number` fora de formatBRL. */
export function larguraBarra(total: string, maior: string): number {
  const max = Number(maior);
  if (!(max > 0)) return 0;
  const pct = (Number(total) / max) * 100;
  return Math.min(100, Math.max(0, pct));
}

/** Agrupa por `competencia`, em ordem cronológica, preservando a ordem de entrada dentro do grupo. */
export function agruparPorCompetencia<T extends { competencia: string }>(
  itens: T[],
): { competencia: string; itens: T[] }[] {
  const grupos = new Map<string, T[]>();
  for (const item of itens) {
    const grupo = grupos.get(item.competencia);
    if (grupo) grupo.push(item);
    else grupos.set(item.competencia, [item]);
  }
  return [...grupos.entries()]
    .sort(([a], [b]) => comparar(a, b))
    .map(([competencia, itens]) => ({ competencia, itens }));
}
