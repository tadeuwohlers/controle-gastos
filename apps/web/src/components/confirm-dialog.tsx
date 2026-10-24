"use client";

import { useEffect, useRef } from "react";
import { ErroInline } from "@/components/erro-inline";

export function ConfirmDialog({
  aberto,
  titulo,
  children,
  rotuloConfirmar,
  ocupado,
  erro,
  onConfirmar,
  onTentarDeNovo,
  onFechar,
}: {
  aberto: boolean;
  titulo: string;
  children: React.ReactNode;
  rotuloConfirmar: string;
  ocupado: boolean;
  erro: string | null;
  onConfirmar: () => void;
  onTentarDeNovo?: () => void;
  onFechar: () => void;
}) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (aberto && !d.open) d.showModal();
    if (!aberto && d.open) d.close();
  }, [aberto]);

  return (
    <dialog
      ref={ref}
      onClose={onFechar}
      className="m-auto w-[min(28rem,calc(100vw-2rem))] rounded-lg border border-foreground/20 bg-background p-5 text-foreground backdrop:bg-black/40"
    >
      <h2 className="mb-2 text-lg font-semibold">{titulo}</h2>
      <div className="mb-4 text-sm text-foreground/80">{children}</div>
      {erro && (
        <div className="mb-4">
          <ErroInline mensagem={erro} onTentarDeNovo={onTentarDeNovo} />
        </div>
      )}
      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={onFechar}
          className="rounded-md border border-foreground/30 px-3 py-1.5 text-sm hover:bg-foreground/5"
        >
          Cancelar
        </button>
        <button
          type="button"
          disabled={ocupado}
          onClick={onConfirmar}
          className="rounded-md bg-red-600 px-3 py-1.5 text-sm text-white hover:bg-red-700 disabled:opacity-60"
        >
          {rotuloConfirmar}
        </button>
      </div>
    </dialog>
  );
}
