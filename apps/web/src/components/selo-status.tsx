export function SeloStatus({ status }: { status: string }) {
  const ativo = status === "ativo";
  return (
    <span
      className={`rounded-full border px-2 py-0.5 text-xs ${
        ativo
          ? "border-green-600/50 text-green-700 dark:text-green-400"
          : "border-foreground/30 text-foreground/70"
      }`}
    >
      {ativo ? "ativo" : "cancelado"}
    </span>
  );
}
