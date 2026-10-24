import { api } from "@/lib/api/client";
import type { components } from "@/lib/api/schema";

export type Conta = components["schemas"]["ContaRead"];
export type Categoria = components["schemas"]["CategoriaRead"];
export type Transacao = components["schemas"]["TransacaoRead"];

function ou<T>(r: { data?: T; error?: unknown }): T {
  if (r.data === undefined) throw new Error("Falha ao ler dados da API.");
  return r.data;
}

export async function listarContas(): Promise<Conta[]> {
  return ou(await api.GET("/api/v1/contas"));
}

export async function listarCategorias(): Promise<Categoria[]> {
  return ou(await api.GET("/api/v1/categorias"));
}

export async function listarTransacoes(filtros: {
  competencia: string;
  conta_id?: number;
  categoria_id?: number;
}): Promise<Transacao[]> {
  return ou(await api.GET("/api/v1/transacoes", { params: { query: filtros } }));
}

export async function listarParcelamentos() {
  return ou(await api.GET("/api/v1/parcelamentos"));
}
