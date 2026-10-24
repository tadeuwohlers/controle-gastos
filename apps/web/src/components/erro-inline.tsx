export function ErroInline({
  mensagem,
  onTentarDeNovo,
}: {
  mensagem: string;
  onTentarDeNovo?: () => void;
}) {
  return (
    <div
      role="alert"
      className="flex flex-wrap items-center justify-between gap-2 whitespace-pre-line rounded-md border border-red-500/40 bg-red-500/10 px-3 py-2 text-sm"
    >
      <span>{mensagem}</span>
      {onTentarDeNovo && (
        <button
          type="button"
          onClick={onTentarDeNovo}
          className="rounded-md border border-foreground/30 px-2 py-1 hover:bg-foreground/5"
        >
          Tentar de novo
        </button>
      )}
    </div>
  );
}

export const MENSAGEM_SERVIDOR =
  "Não foi possível falar com o servidor. Seus dados continuam aqui.";
