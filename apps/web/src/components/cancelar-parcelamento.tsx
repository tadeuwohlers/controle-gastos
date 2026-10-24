"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { ErroInline, MENSAGEM_SERVIDOR } from "@/components/erro-inline";
import { api } from "@/lib/api/client";
import { executar } from "@/lib/mutacao";
import { plural, previaCancelamento } from "@/lib/parcelamento";

export function CancelarParcelamento({
  id,
  ativo,
  parcelas,
}: {
  id: number;
  ativo: boolean;
  parcelas: { competencia: string }[];
}) {
  const router = useRouter();
  const [aberto, setAberto] = useState(false);
  const [ocupado, setOcupado] = useState(false);
  const [erro, setErro] = useState<string | null>(null);
  const [reenviavel, setReenviavel] = useState(false);
  const [aviso, setAviso] = useState<string | null>(null);
  const [avisoErro, setAvisoErro] = useState<string | null>(null);

  // A prévia é recalculada a cada abertura do diálogo (o mês pode virar).
  const previa = aberto ? previaCancelamento(parcelas) : null;

  async function cancelar() {
    setOcupado(true);
    setErro(null);
    const r = await executar(() =>
      api.POST("/api/v1/parcelamentos/{id}/cancelar", { params: { path: { id } } }),
    );
    setOcupado(false);
    if (r.ok) {
      setAberto(false);
      setAvisoErro(null);
      setAviso(
        `Parcelamento cancelado. ${plural(r.data.parcelas_removidas, "parcela futura removida", "parcelas futuras removidas")}; ${plural(r.data.parcelas_preservadas, "preservada", "preservadas")}.`,
      );
      router.refresh();
      return;
    }
    if (r.tipo === "servidor") {
      setErro(MENSAGEM_SERVIDOR);
      setReenviavel(true);
      return;
    }
    // 422 "já cancelado" (outra aba) ou 404: a página recarregada tira o botão e o
    // diálogo, então a mensagem vai para o aviso da página, que sobrevive ao refresh.
    setAberto(false);
    setAvisoErro(r.mensagem);
    router.refresh();
  }

  return (
    <>
      {aviso && (
        <p role="status" className="rounded-md border border-green-600/40 bg-green-600/10 px-3 py-2 text-sm">
          {aviso}
        </p>
      )}
      {avisoErro && <ErroInline mensagem={avisoErro} />}
      {ativo && (
        <button
          type="button"
          onClick={() => {
            setErro(null);
            setAberto(true);
          }}
          className="rounded-md border border-red-600/50 px-3 py-1.5 text-sm text-red-700 hover:bg-red-600/10 dark:text-red-400"
        >
          Cancelar parcelamento
        </button>
      )}
      <ConfirmDialog
        aberto={aberto && ativo}
        titulo="Cancelar parcelamento?"
        rotuloConfirmar="Cancelar parcelamento"
        ocupado={ocupado}
        erro={erro}
        onConfirmar={cancelar}
        onTentarDeNovo={reenviavel ? cancelar : undefined}
        onFechar={() => setAberto(false)}
      >
        {previa &&
          (previa.removidas === 0 ? (
            <>Não há parcelas futuras: apenas o status muda para cancelado.</>
          ) : (
            <>
              Remove {plural(previa.removidas, "parcela futura", "parcelas futuras")};{" "}
              {previa.preservadas} (a do mês atual e as passadas) permanecem.
            </>
          ))}
      </ConfirmDialog>
    </>
  );
}
