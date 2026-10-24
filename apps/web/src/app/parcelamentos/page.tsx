import Link from "next/link";
import { Suspense } from "react";
import { EstadoVazio } from "@/components/estado-vazio";
import { SeloStatus } from "@/components/selo-status";
import { BotaoNovaTransacao } from "@/components/transacao-drawer";
import { formatar } from "@/lib/competencia";
import { listarCategorias, listarContas, listarParcelamentos } from "@/lib/dados";
import { formatBRL } from "@/lib/dinheiro";
import { lerStatus, type StatusFiltro } from "@/lib/parcelamento";

const ABAS: { rotulo: string; status: StatusFiltro; href: string }[] = [
  { rotulo: "Todos", status: null, href: "/parcelamentos" },
  { rotulo: "Ativos", status: "ativo", href: "/parcelamentos?status=ativo" },
  { rotulo: "Cancelados", status: "cancelado", href: "/parcelamentos?status=cancelado" },
];

async function Conteudo({
  searchParams,
}: {
  searchParams: PageProps<"/parcelamentos">["searchParams"];
}) {
  const status = lerStatus((await searchParams).status);
  const [parcelamentos, contas, categorias] = await Promise.all([
    listarParcelamentos(status),
    listarContas(),
    listarCategorias(),
  ]);
  const nomeConta = new Map(contas.map((c) => [c.id, c.nome]));
  const nomeCategoria = new Map(categorias.map((c) => [c.id, c.nome]));

  return (
    <>
      <nav aria-label="Filtro de status" className="mb-4 flex gap-2">
        {ABAS.map((a) => (
          <Link
            key={a.rotulo}
            href={a.href}
            aria-current={a.status === status ? "page" : undefined}
            className={`rounded-full border px-3 py-1 text-sm ${
              a.status === status
                ? "border-foreground bg-foreground text-background"
                : "border-foreground/30 hover:bg-foreground/5"
            }`}
          >
            {a.rotulo}
          </Link>
        ))}
      </nav>
      {parcelamentos.length === 0 ? (
        <div className="flex flex-col items-center gap-4">
          <EstadoVazio>Nenhum parcelamento.</EstadoVazio>
          <BotaoNovaTransacao />
        </div>
      ) : (
        <ul className="divide-y divide-foreground/10 rounded-lg border border-foreground/15">
          {parcelamentos.map((p) => (
            <li key={p.id}>
              <Link
                href={`/parcelamentos/${p.id}`}
                className="flex flex-wrap items-center justify-between gap-x-4 gap-y-1 px-4 py-3 hover:bg-foreground/5"
              >
                <div className="min-w-0">
                  <p className="truncate font-medium">
                    {p.descricao} <SeloStatus status={p.status} />
                  </p>
                  <p className="text-sm text-foreground/70">
                    {nomeCategoria.get(p.categoria_id) ?? "—"} · {nomeConta.get(p.conta_id) ?? "—"} ·
                    primeira parcela em {formatar(p.primeira_parcela)}
                  </p>
                </div>
                <p className="font-medium tabular-nums">
                  {formatBRL(p.valor_total)} · {p.num_parcelas}×
                </p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

export default function Parcelamentos(props: PageProps<"/parcelamentos">) {
  return (
    <>
      <h1 className="mb-4 text-2xl font-semibold">Parcelamentos</h1>
      <Suspense fallback={<p className="text-foreground/70">Carregando…</p>}>
        <Conteudo searchParams={props.searchParams} />
      </Suspense>
    </>
  );
}
