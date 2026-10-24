"use client";

import { usePathname, useSearchParams } from "next/navigation";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { ErroInline } from "@/components/erro-inline";
import { TransacaoForm } from "@/components/transacao-form";
import { api } from "@/lib/api/client";
import { competenciaAtual, valida } from "@/lib/competencia";
import type { Categoria, Conta, Transacao } from "@/lib/dados";
import { foiAtalhoNovaTransacao } from "@/lib/transacao-form";

type Acoes = {
  abrirNova: () => void;
  abrirEdicao: (t: Transacao) => void;
};

const DrawerContext = createContext<Acoes | null>(null);

export function useTransacaoDrawer(): Acoes {
  const ctx = useContext(DrawerContext);
  if (!ctx) throw new Error("useTransacaoDrawer fora do TransacaoDrawerProvider");
  return ctx;
}

const ROTAS_COM_SELETOR = ["/", "/transacoes"];

// `useSearchParams` exige Suspense; fica num componente à parte para o provider
// (e o layout inteiro) não depender dele.
const MesPadraoContext = createContext<{ current: string } | null>(null);

export function MesPadraoSync() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const ref = useContext(MesPadraoContext);
  const mesParam = searchParams.get("mes");
  const mes =
    ROTAS_COM_SELETOR.includes(pathname) && mesParam !== null && valida(mesParam)
      ? mesParam
      : null;
  useEffect(() => {
    if (ref) ref.current = mes ?? "";
  }, [ref, mes]);
  return null;
}

type Sessao = { id: number; edicao: Transacao | null; competenciaPadrao: string };

export function TransacaoDrawerProvider({ children }: { children: React.ReactNode }) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [sessao, setSessao] = useState<Sessao | null>(null);
  // `chave` identifica a leitura (sessão + tentativa); resultado de outra chave = carregando.
  const [leitura, setLeitura] = useState<{
    chave: string;
    listas: { contas: Conta[]; categorias: Categoria[] } | null;
  } | null>(null);
  const [tentativa, setTentativa] = useState(0);

  const mesRef = useRef("");

  const abrir = useCallback((edicao: Transacao | null) => {
    setSessao((s) => ({
      id: (s?.id ?? 0) + 1,
      edicao,
      competenciaPadrao: mesRef.current || competenciaAtual(),
    }));
  }, []);

  const acoes = useMemo<Acoes>(
    () => ({ abrirNova: () => abrir(null), abrirEdicao: (t) => abrir(t) }),
    [abrir],
  );

  // Contas e Categorias sempre frescas ao abrir (mutadas pelo próprio usuário a qualquer momento).
  const sessaoId = sessao?.id;
  useEffect(() => {
    if (sessaoId === undefined) return;
    let cancelado = false;
    const chave = `${sessaoId}:${tentativa}`;
    Promise.all([api.GET("/api/v1/contas"), api.GET("/api/v1/categorias")])
      .then(([c, k]) => {
        if (cancelado) return;
        setLeitura({
          chave,
          listas: c.data && k.data ? { contas: c.data, categorias: k.data } : null,
        });
      })
      .catch(() => !cancelado && setLeitura({ chave, listas: null }));
    return () => {
      cancelado = true;
    };
  }, [sessaoId, tentativa]);

  const atual = leitura?.chave === `${sessaoId}:${tentativa}` ? leitura : null;
  const listas = atual?.listas ?? null;
  const falhaLeitura = atual !== null && atual.listas === null;

  useEffect(() => {
    const d = dialogRef.current;
    if (!d) return;
    if (sessao && !d.open) d.showModal();
    if (!sessao && d.open) d.close();
  }, [sessao]);

  useEffect(() => {
    function aoTeclar(e: KeyboardEvent) {
      if (!foiAtalhoNovaTransacao(e) || dialogRef.current?.open) return;
      e.preventDefault();
      abrir(null);
    }
    window.addEventListener("keydown", aoTeclar);
    return () => window.removeEventListener("keydown", aoTeclar);
  }, [abrir]);

  return (
    <DrawerContext value={acoes}>
      <MesPadraoContext value={mesRef}>{children}</MesPadraoContext>
      <dialog
        ref={dialogRef}
        onClose={() => setSessao(null)}
        aria-labelledby="titulo-gaveta"
        className="m-0 ml-auto h-dvh max-h-none w-full max-w-none border-l border-foreground/20 bg-background p-5 text-foreground backdrop:bg-black/40 md:w-[28rem]"
      >
        {sessao && (
          <>
            <h2 id="titulo-gaveta" className="mb-4 text-lg font-semibold">
              {sessao.edicao ? "Editar transação" : "Nova transação"}
            </h2>
            {falhaLeitura ? (
              <ErroInline
                mensagem="Não foi possível carregar Contas e Categorias."
                onTentarDeNovo={() => setTentativa((n) => n + 1)}
              />
            ) : listas === null ? (
              <p className="text-sm text-foreground/70">Carregando…</p>
            ) : (
              <TransacaoForm
                key={sessao.id}
                edicao={sessao.edicao}
                contas={listas.contas}
                categorias={listas.categorias}
                competenciaPadrao={sessao.competenciaPadrao}
                onContaCriada={(c) =>
                  setLeitura((l) => l?.listas ? { ...l, listas: { ...l.listas, contas: [...l.listas.contas, c] } } : l)
                }
                onCategoriaCriada={(c) =>
                  setLeitura((l) => l?.listas ? { ...l, listas: { ...l.listas, categorias: [...l.listas.categorias, c] } } : l)
                }
                onFechar={() => setSessao(null)}
              />
            )}
          </>
        )}
      </dialog>
    </DrawerContext>
  );
}

export function BotaoNovaTransacao() {
  const { abrirNova } = useTransacaoDrawer();
  return (
    <button
      type="button"
      onClick={abrirNova}
      className="rounded-md bg-foreground px-3 py-1.5 text-sm text-background hover:opacity-90"
    >
      Nova transação
    </button>
  );
}
