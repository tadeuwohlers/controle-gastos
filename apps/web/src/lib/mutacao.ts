import { extrairMensagem } from "./erros";

export type Resultado<T> =
  | { ok: true; data: T }
  // 4xx: erro de regra de negócio ou validação, mostrado inline.
  | { ok: false; tipo: "formulario"; mensagem: string }
  // Falha de rede ou 5xx: o mesmo payload pode ser reenviado.
  | { ok: false; tipo: "servidor" };

type RespostaApi<T> = { data?: T; error?: unknown; response: Response };

/** Normaliza o retorno do `openapi-fetch` (ou uma exceção de rede) em `Resultado`. */
export async function executar<T>(
  chamada: () => Promise<RespostaApi<T>>,
): Promise<Resultado<T>> {
  let resposta: RespostaApi<T>;
  try {
    resposta = await chamada();
  } catch {
    return { ok: false, tipo: "servidor" };
  }
  const { data, error, response } = resposta;
  if (response.ok) return { ok: true, data: data as T };
  if (response.status >= 500) return { ok: false, tipo: "servidor" };
  return { ok: false, tipo: "formulario", mensagem: extrairMensagem(error) };
}
