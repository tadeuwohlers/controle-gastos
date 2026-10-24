import { competenciaAtual, valida } from "./competencia";
import type { Tipo } from "./transacao-form";

export type Filtros = {
  mes: string;
  tipo: Tipo | null;
  contaId: number | null;
  categoriaId: number | null;
};

type Param = string | string[] | undefined;

function primeiro(p: Param): string | undefined {
  return Array.isArray(p) ? p[0] : p;
}

function idValido(p: Param): number | null {
  const v = primeiro(p);
  return v !== undefined && /^[1-9]\d{0,9}$/.test(v) ? Number(v) : null;
}

/** Valor inválido em qualquer parâmetro é ignorado (cai no padrão). */
export function lerFiltros(sp: Record<string, Param>): Filtros {
  const mes = primeiro(sp.mes);
  const tipo = primeiro(sp.tipo);
  return {
    mes: mes !== undefined && valida(mes) ? mes : competenciaAtual(),
    tipo: tipo === "gasto" || tipo === "receita" ? tipo : null,
    contaId: idValido(sp.conta),
    categoriaId: idValido(sp.categoria),
  };
}
