import Link from "next/link";
import { connection } from "next/server";
import { Suspense } from "react";
import { CancelarParcelamento } from "@/components/cancelar-parcelamento";
import { EstadoVazio } from "@/components/estado-vazio";
import { SeloStatus } from "@/components/selo-status";
import { competenciaAtual, comparar, formatar } from "@/lib/competencia";
import { lerParcelamento, listarCategorias, listarContas } from "@/lib/dados";
import { formatBRL } from "@/lib/dinheiro";

function NaoEncontrado() {
  return (
    <div className="flex flex-col items-center gap-4">
      <EstadoVazio>Parcelamento não encontrado.</EstadoVazio>
      <Link href="/parcelamentos" className="text-sm underline">
        Voltar para Parcelamentos
      </Link>
    </div>
  );
}

async function Conteudo({ params }: { params: PageProps<"/parcelamentos/[id]">["params"] }) {
  await connection(); // o mês corrente depende da hora do pedido
  const { id } = await params;
  if (!/^[1-9]\d{0,9}$/.test(id)) return <NaoEncontrado />;
  const [p, contas, categorias] = await Promise.all([
    lerParcelamento(Number(id)),
    listarContas(),
    listarCategorias(),
  ]);
  if (p === null) return <NaoEncontrado />;
  const atual = competenciaAtual();
  const conta = contas.find((c) => c.id === p.conta_id)?.nome ?? "—";
  const categoria = categorias.find((c) => c.id === p.categoria_id)?.nome ?? "—";

  return (
    <div className="space-y-6">
      <Link href="/parcelamentos" className="text-sm underline">
        ← Parcelamentos
      </Link>
      <header className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 className="text-xl font-semibold">
            {p.descricao} <SeloStatus status={p.status} />
          </h2>
          <p className="mt-1 text-sm text-foreground/70">
            {formatBRL(p.valor_total)} em {p.num_parcelas}× · {categoria} · {conta}
          </p>
        </div>
      </header>
      <CancelarParcelamento
        id={p.id}
        ativo={p.status === "ativo"}
        parcelas={p.parcelas.map((x) => ({ competencia: x.competencia }))}
      />
      <table className="w-full text-sm">
        <caption className="sr-only">Parcelas</caption>
        <thead>
          <tr className="border-b border-foreground/15 text-left">
            <th className="py-2 font-medium">Parcela</th>
            <th className="py-2 font-medium">Competência</th>
            <th className="py-2 text-right font-medium">Valor</th>
          </tr>
        </thead>
        <tbody>
          {p.parcelas.map((x) => {
            const c = comparar(x.competencia, atual);
            return (
              <tr
                key={x.id}
                aria-current={c === 0 ? "date" : undefined}
                className={`border-b border-foreground/10 ${
                  c === 0 ? "bg-foreground/10 font-medium" : c < 0 ? "opacity-60" : ""
                }`}
              >
                <td className="py-2">
                  {x.numero_parcela}/{p.num_parcelas}
                </td>
                <td className="py-2">
                  {formatar(x.competencia)}
                  {c === 0 && " (mês atual)"}
                </td>
                <td className="py-2 text-right tabular-nums">{formatBRL(x.valor)}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}

export default function Parcelamento(props: PageProps<"/parcelamentos/[id]">) {
  return (
    <>
      <h1 className="mb-4 text-2xl font-semibold">Parcelamento</h1>
      <Suspense fallback={<p className="text-foreground/70">Carregando…</p>}>
        <Conteudo params={props.params} />
      </Suspense>
    </>
  );
}
