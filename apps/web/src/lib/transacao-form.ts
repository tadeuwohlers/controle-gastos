import { valida } from "./competencia";
import { parseValorBR } from "./dinheiro";

export type Tipo = "gasto" | "receita";

export type EstadoForm = {
  tipo: Tipo;
  valor: string;
  descricao: string;
  competencia: string;
  contaId: string;
  categoriaId: string;
};

export type ErrosForm = Partial<Record<keyof EstadoForm, string>>;

export type Payload = {
  tipo: Tipo;
  valor: string;
  descricao: string;
  competencia: string;
  conta_id: number;
  categoria_id: number;
};

export const CHAVE_ULTIMA_CONTA = "ultima_conta_id";

/** Valida o formulário no cliente; a API continua sendo a fonte da verdade. */
export function validar(
  estado: EstadoForm,
): { ok: true; payload: Payload } | { ok: false; erros: ErrosForm } {
  const erros: ErrosForm = {};
  const valor = parseValorBR(estado.valor);
  if (valor === null) erros.valor = "Informe um valor maior que zero, com até 2 casas decimais.";
  if (estado.descricao.trim() === "") erros.descricao = "Informe a descrição.";
  if (!valida(estado.competencia)) erros.competencia = "Informe a Competência.";
  if (estado.contaId === "") erros.contaId = "Escolha a Conta.";
  if (estado.categoriaId === "") erros.categoriaId = "Escolha a Categoria.";
  if (Object.keys(erros).length > 0 || valor === null) return { ok: false, erros };
  return {
    ok: true,
    payload: {
      tipo: estado.tipo,
      valor,
      descricao: estado.descricao.trim(),
      competencia: estado.competencia,
      conta_id: Number(estado.contaId),
      categoria_id: Number(estado.categoriaId),
    },
  };
}

/** Última Conta usada, só se ainda existir na lista; falha de leitura é ignorada. */
export function contaPadrao(
  contas: { id: number }[],
  armazenamento: Pick<Storage, "getItem"> | null,
): string {
  try {
    const salvo = armazenamento?.getItem(CHAVE_ULTIMA_CONTA) ?? null;
    if (salvo !== null && contas.some((c) => String(c.id) === salvo)) return salvo;
  } catch {
    // localStorage indisponível: sem padrão.
  }
  return "";
}

export function salvarUltimaConta(
  id: number,
  armazenamento: Pick<Storage, "setItem"> | null,
) {
  try {
    armazenamento?.setItem(CHAVE_ULTIMA_CONTA, String(id));
  } catch {
    // ignora
  }
}

/** `localStorage`, ou null quando o acesso lança (modo privado, bloqueio). */
export function armazenamentoLocal(): Storage | null {
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

/** O atalho `n` não pode disparar enquanto a pessoa digita. */
export function foiAtalhoNovaTransacao(e: {
  key: string;
  ctrlKey: boolean;
  metaKey: boolean;
  altKey: boolean;
  target: unknown;
}): boolean {
  if (e.key !== "n" || e.ctrlKey || e.metaKey || e.altKey) return false;
  const t = e.target as { tagName?: string; isContentEditable?: boolean } | null;
  const tag = t?.tagName?.toUpperCase();
  if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return false;
  if (t?.isContentEditable) return false;
  return true;
}
