import { Suspense } from "react";
import { NovaCategoria, NovaConta } from "@/components/cadastros-forms";
import { listarCategorias, listarContas } from "@/lib/dados";

const TIPOS = [
  { tipo: "gasto", rotulo: "Gasto" },
  { tipo: "receita", rotulo: "Receita" },
] as const;

async function Listas() {
  const [contas, categorias] = await Promise.all([listarContas(), listarCategorias()]);
  return (
    <div className="grid gap-8 md:grid-cols-2">
      <section aria-labelledby="h-contas" className="flex flex-col gap-4">
        <h2 id="h-contas" className="text-lg font-semibold">Contas</h2>
        <p className="text-sm text-foreground/70">
          Uma Conta representa uma conta bancária ou cartão. Toda transação pertence a uma.
        </p>
        <NovaConta />
        {contas.length === 0 ? (
          <p className="text-sm text-foreground/70">Nenhuma Conta cadastrada.</p>
        ) : (
          <ul className="divide-y divide-foreground/10 rounded-lg border border-foreground/15">
            {contas.map((c) => (
              <li key={c.id} className="px-4 py-2">{c.nome}</li>
            ))}
          </ul>
        )}
      </section>

      <section aria-labelledby="h-categorias" className="flex flex-col gap-4">
        <h2 id="h-categorias" className="text-lg font-semibold">Categorias</h2>
        <p className="text-sm text-foreground/70">
          Categorias classificam as transações e têm tipo: Gasto ou Receita.
        </p>
        <NovaCategoria />
        {TIPOS.map(({ tipo, rotulo }) => {
          const doTipo = categorias.filter((c) => c.tipo === tipo);
          return (
            <div key={tipo}>
              <h3 className="mb-1 text-sm font-medium">{rotulo}</h3>
              {doTipo.length === 0 ? (
                <p className="text-sm text-foreground/70">Nenhuma Categoria de {rotulo}.</p>
              ) : (
                <ul className="divide-y divide-foreground/10 rounded-lg border border-foreground/15">
                  {doTipo.map((c) => (
                    <li key={c.id} className="px-4 py-2">{c.nome}</li>
                  ))}
                </ul>
              )}
            </div>
          );
        })}
      </section>
    </div>
  );
}

export default function Cadastros() {
  return (
    <>
      <h1 className="mb-4 text-2xl font-semibold">Cadastros</h1>
      <Suspense fallback={<p className="text-foreground/70">Carregando…</p>}>
        <Listas />
      </Suspense>
    </>
  );
}
