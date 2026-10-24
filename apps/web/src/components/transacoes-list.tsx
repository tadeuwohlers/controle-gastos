"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { useTransacaoDrawer } from "@/components/transacao-drawer";
import { api } from "@/lib/api/client";
import type { Transacao } from "@/lib/dados";
import { formatBRL } from "@/lib/dinheiro";
import { MENSAGEM_SERVIDOR } from "@/components/erro-inline";
import { executar } from "@/lib/mutacao";

export type Linha = Transacao & {
  contaNome: string;
  categoriaNome: string;
  /** N do selo n/N, só em Parcelas. */
  totalParcelas: number | null;
};

const botaoLink =
  "rounded-md px-2 py-1 text-sm underline underline-offset-2 hover:bg-foreground/5";

export function TransacoesList({ linhas }: { linhas: Linha[] }) {
  const router = useRouter();
  const { abrirEdicao } = useTransacaoDrawer();
  const [excluindo, setExcluindo] = useState<Linha | null>(null);
  const [ocupado, setOcupado] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const [reenviavel, setReenviavel] = useState(false);
  const alvo = useRef<Linha | null>(null);

  async function excluir() {
    const t = alvo.current ?? excluindo;
    if (!t) return;
    setOcupado(true);
    setErro(null);
    const r = await executar(() =>
      api.DELETE("/api/v1/transacoes/{id}", { params: { path: { id: t.id } } }),
    );
    setOcupado(false);
    if (r.ok) {
      setExcluindo(null);
      router.refresh();
      return;
    }
    if (r.tipo === "servidor") {
      setErro(MENSAGEM_SERVIDOR);
      setReenviavel(true);
    } else {
      setErro(r.mensagem);
      setReenviavel(false);
      // 404: já foi excluída em outra aba; atualiza a lista.
      router.refresh();
    }
  }

  return (
    <>
      <ul className="divide-y divide-foreground/10 rounded-lg border border-foreground/15">
        {linhas.map((t) => {
          const avulsa = t.parcelamento_id === null;
          const gasto = t.tipo === "gasto";
          return (
            <li key={t.id} className="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 px-4 py-3">
              <div className="min-w-0">
                <p className="truncate font-medium">
                  {t.descricao}
                  {!avulsa && (
                    <Link
                      href={`/parcelamentos/${t.parcelamento_id}`}
                      className="ml-2 rounded-full border border-foreground/30 px-2 py-0.5 text-xs font-normal underline-offset-2 hover:underline"
                      aria-label={`Parcela ${t.numero_parcela} de ${t.totalParcelas} — ver Parcelamento`}
                    >
                      {t.numero_parcela}/{t.totalParcelas}
                    </Link>
                  )}
                </p>
                <p className="text-sm text-foreground/70">
                  {t.categoriaNome} · {t.contaNome}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <span
                  className={`font-medium tabular-nums ${
                    gasto ? "text-red-700 dark:text-red-400" : "text-green-700 dark:text-green-400"
                  }`}
                >
                  {gasto ? "− " : "+ "}
                  {formatBRL(t.valor)}
                </span>
                {avulsa && (
                  <>
                    <button type="button" className={botaoLink} onClick={() => abrirEdicao(t)}>
                      Editar
                    </button>
                    <button
                      type="button"
                      className={botaoLink}
                      onClick={() => {
                        alvo.current = t;
                        setErro(null);
                        setExcluindo(t);
                      }}
                    >
                      Excluir
                    </button>
                  </>
                )}
              </div>
            </li>
          );
        })}
      </ul>
      <ConfirmDialog
        aberto={excluindo !== null}
        titulo="Excluir transação?"
        rotuloConfirmar="Excluir"
        ocupado={ocupado}
        erro={erro}
        onConfirmar={excluir}
        onTentarDeNovo={reenviavel ? excluir : undefined}
        onFechar={() => setExcluindo(null)}
      >
        {excluindo && (
          <>
            “{excluindo.descricao}” ({formatBRL(excluindo.valor)}) será removida. Isso não pode ser desfeito.
          </>
        )}
      </ConfirmDialog>
    </>
  );
}
