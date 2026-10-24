import { comparar, competenciaAtual, valida } from "./competencia";
import { parseValorBR } from "./dinheiro";
import type { EstadoForm } from "./transacao-form";

export type ErrosParcelado = Partial<
  Record<"valor" | "descricao" | "competencia" | "contaId" | "categoriaId" | "numParcelas", string>
>;

export type PayloadParcelamento = {
  descricao: string;
  valor_total: string;
  num_parcelas: number;
  primeira_parcela: string;
  conta_id: number;
  categoria_id: number;
};

/** No modo Parcelado, `estado.valor` é o valor total e `estado.competencia` a primeira parcela. */
export function validarParcelado(
  estado: EstadoForm,
  numParcelas: string,
): { ok: true; payload: PayloadParcelamento } | { ok: false; erros: ErrosParcelado } {
  const erros: ErrosParcelado = {};
  const valor = parseValorBR(estado.valor);
  if (valor === null) erros.valor = "Informe um valor maior que zero, com até 2 casas decimais.";
  if (estado.descricao.trim() === "") erros.descricao = "Informe a descrição.";
  if (!valida(estado.competencia)) erros.competencia = "Informe a primeira parcela.";
  if (estado.contaId === "") erros.contaId = "Escolha a Conta.";
  if (estado.categoriaId === "") erros.categoriaId = "Escolha a Categoria.";
  const n = /^\d{1,4}$/.test(numParcelas.trim()) ? Number(numParcelas.trim()) : NaN;
  if (!(n >= 2)) erros.numParcelas = "Informe um número inteiro de parcelas, no mínimo 2.";
  if (Object.keys(erros).length > 0 || valor === null) return { ok: false, erros };
  return {
    ok: true,
    payload: {
      descricao: estado.descricao.trim(),
      valor_total: valor,
      num_parcelas: n,
      primeira_parcela: estado.competencia,
      conta_id: Number(estado.contaId),
      categoria_id: Number(estado.categoriaId),
    },
  };
}

/** Prévia do cancelamento: futuras (Competência após o mês corrente) serão removidas. */
export function previaCancelamento(
  parcelas: { competencia: string }[],
  atual: string = competenciaAtual(),
): { removidas: number; preservadas: number } {
  const removidas = parcelas.filter((p) => comparar(p.competencia, atual) > 0).length;
  return { removidas, preservadas: parcelas.length - removidas };
}

export type StatusFiltro = "ativo" | "cancelado" | null;

/** Valor inválido é ignorado (sem filtro). */
export function lerStatus(p: string | string[] | undefined): StatusFiltro {
  const v = Array.isArray(p) ? p[0] : p;
  return v === "ativo" || v === "cancelado" ? v : null;
}

export function plural(n: number, singular: string, plural: string): string {
  return `${n} ${n === 1 ? singular : plural}`;
}
