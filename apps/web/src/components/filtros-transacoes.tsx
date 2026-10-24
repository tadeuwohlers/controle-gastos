"use client";

import { useEffect, useRef } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import type { Categoria, Conta } from "@/lib/dados";

const campo = "rounded-md border border-foreground/30 bg-background px-2 py-1.5 text-sm";

export function FiltrosTransacoes({
  contas,
  categorias,
  tipo,
  contaId,
  categoriaId,
}: {
  contas: Conta[];
  categorias: Categoria[];
  tipo: string | null;
  contaId: number | null;
  categoriaId: number | null;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Trocas em sequência rápida partem da URL já pedida, não da que ainda está na tela
  // (o `router.replace` de uma página dinâmica demora a refletir em `searchParams`).
  const pedido = useRef<URLSearchParams | null>(null);
  const atual = searchParams.toString();
  useEffect(() => {
    pedido.current = null;
  }, [atual]);

  function definir(chave: string, valor: string) {
    const params = pedido.current ?? new URLSearchParams(atual);
    pedido.current = params;
    if (valor === "") params.delete(chave);
    else params.set(chave, valor);
    const qs = params.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname);
  }

  return (
    <div className="mb-4 flex flex-wrap gap-3" role="group" aria-label="Filtros">
      <label className="flex flex-col gap-1 text-sm">
        Tipo
        <select className={campo} value={tipo ?? ""} onChange={(e) => definir("tipo", e.target.value)}>
          <option value="">Todos</option>
          <option value="gasto">Gasto</option>
          <option value="receita">Receita</option>
        </select>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        Conta
        <select className={campo} value={contaId ?? ""} onChange={(e) => definir("conta", e.target.value)}>
          <option value="">Todas</option>
          {contas.map((c) => (
            <option key={c.id} value={c.id}>
              {c.nome}
            </option>
          ))}
        </select>
      </label>
      <label className="flex flex-col gap-1 text-sm">
        Categoria
        <select
          className={campo}
          value={categoriaId ?? ""}
          onChange={(e) => definir("categoria", e.target.value)}
        >
          <option value="">Todas</option>
          {categorias.map((c) => (
            <option key={c.id} value={c.id}>
              {c.nome}
            </option>
          ))}
        </select>
      </label>
    </div>
  );
}
