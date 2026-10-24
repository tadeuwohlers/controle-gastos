const PADRAO = "Algo deu errado. Tente de novo.";
const PREFIXO_PYDANTIC = "Value error, ";

export function extrairMensagem(error: unknown): string {
  if (typeof error !== "object" || error === null || !("detail" in error)) {
    return PADRAO;
  }
  const { detail } = error as { detail: unknown };
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) {
    const msgs = detail
      .map((d) => (d as { msg?: unknown } | null)?.msg)
      .filter((m): m is string => typeof m === "string")
      .map((m) => m.replace(PREFIXO_PYDANTIC, ""));
    if (msgs.length > 0) return msgs.join("\n");
  }
  return PADRAO;
}
