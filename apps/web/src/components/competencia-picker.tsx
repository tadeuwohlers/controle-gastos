"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  comparar,
  competenciaAtual,
  deslocar,
  formatar,
  valida,
} from "@/lib/competencia";

const ROTAS_COM_SELETOR = ["/", "/transacoes"];

export function CompetenciaPicker() {
  const pathname = usePathname();
  const router = useRouter();
  const searchParams = useSearchParams();

  if (!ROTAS_COM_SELETOR.includes(pathname)) return null;

  const atual = competenciaAtual();
  const param = searchParams.get("mes");
  const mes = param !== null && valida(param) ? param : atual;

  function ir(destino: string) {
    const params = new URLSearchParams(searchParams.toString());
    params.set("mes", destino);
    router.replace(`${pathname}?${params.toString()}`);
  }

  const botao =
    "rounded-md border border-foreground/20 px-3 py-1.5 text-sm hover:bg-foreground/5 focus-visible:outline-2 focus-visible:outline-offset-2";

  return (
    <div className="flex items-center gap-2" role="group" aria-label="Competência">
      <button type="button" className={botao} aria-label="Mês anterior" onClick={() => ir(deslocar(mes, -1))}>
        ←
      </button>
      <span className="min-w-40 text-center font-medium first-letter:uppercase" aria-live="polite">
        {formatar(mes)}
      </span>
      <button type="button" className={botao} aria-label="Próximo mês" onClick={() => ir(deslocar(mes, 1))}>
        →
      </button>
      {comparar(mes, atual) !== 0 && (
        <button type="button" className={botao} onClick={() => ir(atual)}>
          Hoje
        </button>
      )}
    </div>
  );
}
