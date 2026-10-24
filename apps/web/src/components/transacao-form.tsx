"use client";

import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { CriarCategoria, CriarConta } from "@/components/criar-cadastro";
import { ErroInline, MENSAGEM_SERVIDOR } from "@/components/erro-inline";
import { api } from "@/lib/api/client";
import type { Categoria, Conta, Transacao } from "@/lib/dados";
import { executar } from "@/lib/mutacao";
import {
  armazenamentoLocal,
  contaPadrao,
  salvarUltimaConta,
  validar,
  type ErrosForm,
  type EstadoForm,
  type Payload,
  type Tipo,
} from "@/lib/transacao-form";

const campo =
  "w-full rounded-md border border-foreground/30 bg-background px-2 py-1.5 text-sm";
const botao =
  "rounded-md border border-foreground/30 px-3 py-1.5 text-sm hover:bg-foreground/5 disabled:opacity-60";
const botaoPrimario =
  "rounded-md bg-foreground px-3 py-1.5 text-sm text-background hover:opacity-90 disabled:opacity-60";

type Aviso = { mensagem: string; reenviavel: boolean };

function Campo({
  rotulo,
  erro,
  children,
}: {
  rotulo: string;
  erro?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="flex flex-col gap-1 text-sm">
      <span className="font-medium">{rotulo}</span>
      {children}
      {erro && <span className="text-red-600 dark:text-red-400">{erro}</span>}
    </label>
  );
}

export function TransacaoForm({
  edicao,
  contas,
  categorias,
  competenciaPadrao,
  onContaCriada,
  onCategoriaCriada,
  onFechar,
}: {
  edicao: Transacao | null;
  contas: Conta[];
  categorias: Categoria[];
  competenciaPadrao: string;
  onContaCriada: (c: Conta) => void;
  onCategoriaCriada: (c: Categoria) => void;
  onFechar: () => void;
}) {
  const router = useRouter();
  const valorRef = useRef<HTMLInputElement>(null);
  const [estado, setEstado] = useState<EstadoForm>(() =>
    edicao
      ? {
          tipo: edicao.tipo,
          valor: edicao.valor.replace(".", ","),
          descricao: edicao.descricao,
          competencia: edicao.competencia,
          contaId: String(edicao.conta_id),
          categoriaId: String(edicao.categoria_id),
        }
      : {
          tipo: "gasto",
          valor: "",
          descricao: "",
          competencia: competenciaPadrao,
          contaId: contaPadrao(contas, armazenamentoLocal()),
          categoriaId: "",
        },
  );
  const [erros, setErros] = useState<ErrosForm>({});
  const [aviso, setAviso] = useState<Aviso | null>(null);
  const [salvoMsg, setSalvoMsg] = useState<string | null>(null);
  const [ocupado, setOcupado] = useState(false);
  const [criando, setCriando] = useState<"conta" | "categoria" | null>(null);
  const [pendente, setPendente] = useState<{ payload: Payload; nova: boolean } | null>(null);

  const categoriasDoTipo = categorias.filter((c) => c.tipo === estado.tipo);

  function mudar<K extends keyof EstadoForm>(k: K, v: EstadoForm[K]) {
    setEstado((e) => ({ ...e, [k]: v }));
  }

  function mudarTipo(tipo: Tipo) {
    setEstado((e) => ({ ...e, tipo, categoriaId: "" }));
    setCriando(null);
  }

  async function enviar(payload: Payload, nova: boolean) {
    setPendente({ payload, nova });
    setOcupado(true);
    setAviso(null);
    const r = await executar(() =>
      edicao
        ? api.PUT("/api/v1/transacoes/{id}", {
            params: { path: { id: edicao.id } },
            body: {
              valor: payload.valor,
              descricao: payload.descricao,
              competencia: payload.competencia,
              conta_id: payload.conta_id,
              categoria_id: payload.categoria_id,
            },
          })
        : api.POST("/api/v1/transacoes", { body: payload }),
    );
    setOcupado(false);
    if (!r.ok) {
      setAviso(
        r.tipo === "servidor"
          ? { mensagem: MENSAGEM_SERVIDOR, reenviavel: true }
          : { mensagem: r.mensagem, reenviavel: false },
      );
      return;
    }
    setPendente(null);
    salvarUltimaConta(payload.conta_id, armazenamentoLocal());
    router.refresh();
    if (nova) {
      setEstado((e) => ({ ...e, valor: "", descricao: "" }));
      setSalvoMsg("Transação salva.");
      valorRef.current?.focus();
    } else {
      onFechar();
    }
  }

  function submeter(nova: boolean) {
    setSalvoMsg(null);
    const v = validar(estado);
    if (!v.ok) {
      setErros(v.erros);
      setAviso(null);
      return;
    }
    setErros({});
    void enviar(v.payload, nova);
  }

  return (
    <form
      className="flex flex-col gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        submeter(false);
      }}
    >
      {aviso && (
        <ErroInline
          mensagem={aviso.mensagem}
          onTentarDeNovo={
            aviso.reenviavel && pendente
              ? () => void enviar(pendente.payload, pendente.nova)
              : undefined
          }
        />
      )}
      {salvoMsg && (
        <p role="status" className="text-sm text-green-700 dark:text-green-400">
          {salvoMsg}
        </p>
      )}

      {edicao ? (
        <p className="text-sm">
          <span className="font-medium">Tipo: </span>
          {edicao.tipo === "gasto" ? "Gasto" : "Receita"}
        </p>
      ) : (
        <fieldset className="flex gap-4 text-sm">
          <legend className="mb-1 font-medium">Tipo</legend>
          {(["gasto", "receita"] as const).map((t) => (
            <label key={t} className="flex items-center gap-1.5">
              <input
                type="radio"
                name="tipo"
                checked={estado.tipo === t}
                onChange={() => mudarTipo(t)}
              />
              {t === "gasto" ? "Gasto" : "Receita"}
            </label>
          ))}
        </fieldset>
      )}

      <Campo rotulo="Valor" erro={erros.valor}>
        <input
          ref={valorRef}
          className={campo}
          inputMode="decimal"
          placeholder="0,00"
          value={estado.valor}
          onChange={(e) => mudar("valor", e.target.value)}
          autoFocus
        />
      </Campo>

      <Campo rotulo="Descrição" erro={erros.descricao}>
        <input
          className={campo}
          value={estado.descricao}
          onChange={(e) => mudar("descricao", e.target.value)}
        />
      </Campo>

      <Campo rotulo="Competência" erro={erros.competencia}>
        <input
          className={campo}
          type="month"
          value={estado.competencia}
          onChange={(e) => mudar("competencia", e.target.value)}
        />
      </Campo>

      <div className="flex flex-col gap-2">
        <Campo rotulo="Conta" erro={erros.contaId}>
          <select
            className={campo}
            value={estado.contaId}
            onChange={(e) => mudar("contaId", e.target.value)}
          >
            <option value="">Selecione…</option>
            {contas.map((c) => (
              <option key={c.id} value={c.id}>
                {c.nome}
              </option>
            ))}
          </select>
        </Campo>
        {criando === "conta" ? (
          <CriarConta
            onCancelar={() => setCriando(null)}
            onCriada={(c) => {
              onContaCriada(c);
              mudar("contaId", String(c.id));
              setCriando(null);
              router.refresh();
            }}
          />
        ) : (
          <button type="button" className="self-start text-sm underline" onClick={() => setCriando("conta")}>
            Criar conta
          </button>
        )}
      </div>

      <div className="flex flex-col gap-2">
        <Campo rotulo="Categoria" erro={erros.categoriaId}>
          <select
            className={campo}
            value={estado.categoriaId}
            onChange={(e) => mudar("categoriaId", e.target.value)}
          >
            <option value="">Selecione…</option>
            {categoriasDoTipo.map((c) => (
              <option key={c.id} value={c.id}>
                {c.nome}
              </option>
            ))}
          </select>
        </Campo>
        {criando === "categoria" ? (
          <CriarCategoria
            tipoFixo={estado.tipo}
            onCancelar={() => setCriando(null)}
            onCriada={(c) => {
              onCategoriaCriada(c);
              mudar("categoriaId", String(c.id));
              setCriando(null);
              router.refresh();
            }}
          />
        ) : (
          <button type="button" className="self-start text-sm underline" onClick={() => setCriando("categoria")}>
            Criar categoria
          </button>
        )}
      </div>

      <div className="flex flex-wrap justify-end gap-2">
        <button type="button" className={botao} onClick={onFechar}>
          Cancelar
        </button>
        {!edicao && (
          <button type="button" className={botao} disabled={ocupado} onClick={() => submeter(true)}>
            Salvar e nova
          </button>
        )}
        <button type="submit" className={botaoPrimario} disabled={ocupado}>
          Salvar
        </button>
      </div>
    </form>
  );
}
