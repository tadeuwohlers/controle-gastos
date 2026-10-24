"use client";

import { useState } from "react";
import { ErroInline, MENSAGEM_SERVIDOR } from "@/components/erro-inline";
import { api } from "@/lib/api/client";
import type { Categoria, Conta } from "@/lib/dados";
import { executar } from "@/lib/mutacao";
import type { Tipo } from "@/lib/transacao-form";

const campo =
  "rounded-md border border-foreground/30 bg-background px-2 py-1.5 text-sm";
const botao =
  "rounded-md border border-foreground/30 px-3 py-1.5 text-sm hover:bg-foreground/5 disabled:opacity-60";

type Aviso = { mensagem: string; reenviavel: boolean };

/**
 * Mini-formulário sem <form> (precisa caber dentro da gaveta, que já é um form);
 * Enter no campo de nome envia.
 */
function CriarNome({
  rotulo,
  rotuloBotao,
  extra,
  enviar,
  onCancelar,
}: {
  rotulo: string;
  rotuloBotao: string;
  extra?: React.ReactNode;
  enviar: (nome: string) => Promise<Aviso | null>;
  onCancelar?: () => void;
}) {
  const [nome, setNome] = useState("");
  const [aviso, setAviso] = useState<Aviso | null>(null);
  const [ocupado, setOcupado] = useState(false);

  async function submeter() {
    if (nome.trim() === "") {
      setAviso({ mensagem: "Informe o nome.", reenviavel: false });
      return;
    }
    setOcupado(true);
    const resultado = await enviar(nome.trim());
    setOcupado(false);
    if (resultado === null) setNome("");
    setAviso(resultado);
  }

  return (
    <div className="flex flex-col gap-2">
      {aviso && (
        <ErroInline
          mensagem={aviso.mensagem}
          onTentarDeNovo={aviso.reenviavel ? submeter : undefined}
        />
      )}
      <div className="flex flex-wrap items-end gap-2">
        <label className="flex flex-col gap-1 text-sm">
          {rotulo}
          <input
            className={campo}
            value={nome}
            autoFocus={onCancelar !== undefined}
            onChange={(e) => setNome(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                e.stopPropagation();
                void submeter();
              }
            }}
          />
        </label>
        {extra}
        <button type="button" className={botao} disabled={ocupado} onClick={submeter}>
          {rotuloBotao}
        </button>
        {onCancelar && (
          <button type="button" className={botao} onClick={onCancelar}>
            Cancelar
          </button>
        )}
      </div>
    </div>
  );
}

export function CriarConta({
  onCriada,
  onCancelar,
}: {
  onCriada: (conta: Conta) => void;
  onCancelar?: () => void;
}) {
  return (
    <CriarNome
      rotulo="Nome da Conta"
      rotuloBotao="Criar conta"
      onCancelar={onCancelar}
      enviar={async (nome) => {
        const r = await executar(() => api.POST("/api/v1/contas", { body: { nome } }));
        if (r.ok) {
          onCriada(r.data);
          return null;
        }
        return r.tipo === "servidor"
          ? { mensagem: MENSAGEM_SERVIDOR, reenviavel: true }
          : { mensagem: r.mensagem, reenviavel: false };
      }}
    />
  );
}

export function CriarCategoria({
  tipoFixo,
  onCriada,
  onCancelar,
}: {
  /** Na gaveta o tipo já está escolhido; em /cadastros a pessoa escolhe. */
  tipoFixo?: Tipo;
  onCriada: (categoria: Categoria) => void;
  onCancelar?: () => void;
}) {
  const [tipo, setTipo] = useState<Tipo>("gasto");
  const tipoEfetivo = tipoFixo ?? tipo;
  return (
    <CriarNome
      rotulo="Nome da Categoria"
      rotuloBotao="Criar categoria"
      onCancelar={onCancelar}
      extra={
        tipoFixo ? null : (
          <label className="flex flex-col gap-1 text-sm">
            Tipo
            <select
              className={campo}
              value={tipo}
              onChange={(e) => setTipo(e.target.value as Tipo)}
            >
              <option value="gasto">Gasto</option>
              <option value="receita">Receita</option>
            </select>
          </label>
        )
      }
      enviar={async (nome) => {
        const r = await executar(() =>
          api.POST("/api/v1/categorias", { body: { nome, tipo: tipoEfetivo } }),
        );
        if (r.ok) {
          onCriada(r.data);
          return null;
        }
        return r.tipo === "servidor"
          ? { mensagem: MENSAGEM_SERVIDOR, reenviavel: true }
          : { mensagem: r.mensagem, reenviavel: false };
      }}
    />
  );
}
