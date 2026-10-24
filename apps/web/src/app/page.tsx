import Link from "next/link";
import { connection } from "next/server";
import { Suspense } from "react";
import { EstadoVazio } from "@/components/estado-vazio";
import { api } from "@/lib/api/client";
import { competenciaAtual, formatar, valida } from "@/lib/competencia";
import { formatBRL, sinal } from "@/lib/dinheiro";
import { agruparPorCompetencia, larguraBarra } from "@/lib/resumo";

export default function Resumo({ searchParams }: PageProps<"/">) {
  return (
    <>
      <h1 className="mb-4 text-2xl font-semibold">Resumo</h1>
      <Suspense fallback={<p className="text-foreground/70">Carregando…</p>}>
        <ResumoConteudo searchParams={searchParams} />
      </Suspense>
    </>
  );
}

async function ResumoConteudo({
  searchParams,
}: {
  searchParams: PageProps<"/">["searchParams"];
}) {
  await connection(); // o mês corrente depende da hora do pedido
  const { mes } = await searchParams;
  const competencia =
    typeof mes === "string" && valida(mes) ? mes : competenciaAtual();

  const query = { params: { query: { competencia } } };
  const [balanco, gastos, parcelas] = await Promise.all([
    api.GET("/api/v1/relatorios/balanco-mensal", query),
    api.GET("/api/v1/relatorios/gastos-por-categoria", query),
    api.GET("/api/v1/relatorios/parcelas-ativas"),
  ]);
  if (!balanco.data || !gastos.data || !parcelas.data) {
    throw new Error("Falha ao ler os relatórios.");
  }

  return (
    <div className="space-y-8">
      <BalancoMensal
        receitas={balanco.data.total_receitas}
        gastos={balanco.data.total_gastos}
        saldo={balanco.data.saldo}
      />
      <GastosPorCategoria itens={gastos.data.itens} />
      <ParcelasAtivas parcelas={parcelas.data} />
    </div>
  );
}

const COR_SALDO = {
  positivo: "text-green-700 dark:text-green-400",
  negativo: "text-red-700 dark:text-red-400",
  zero: "text-foreground",
} as const;

const ICONE_SALDO = { positivo: "▲", negativo: "▼", zero: "•" } as const;
const TEXTO_SALDO = { positivo: "Superávit", negativo: "Déficit", zero: "Zerado" } as const;

function BalancoMensal(props: { receitas: string; gastos: string; saldo: string }) {
  const s = sinal(props.saldo);
  const cartao = "rounded-lg border border-foreground/15 p-4";
  return (
    <section aria-labelledby="balanco">
      <h2 id="balanco" className="mb-3 text-lg font-semibold">
        Balanço Mensal
      </h2>
      <dl className="grid gap-3 sm:grid-cols-3">
        <div className={cartao}>
          <dt className="text-sm text-foreground/70">Receitas</dt>
          <dd className="text-xl font-semibold tabular-nums">{formatBRL(props.receitas)}</dd>
        </div>
        <div className={cartao}>
          <dt className="text-sm text-foreground/70">Gastos</dt>
          <dd className="text-xl font-semibold tabular-nums">{formatBRL(props.gastos)}</dd>
        </div>
        <div className={cartao}>
          <dt className="text-sm text-foreground/70">Saldo</dt>
          <dd className={`text-xl font-semibold tabular-nums ${COR_SALDO[s]}`}>
            <span aria-hidden="true">{ICONE_SALDO[s]} </span>
            {formatBRL(props.saldo)}
            <span className="ml-2 text-sm font-normal">{TEXTO_SALDO[s]}</span>
          </dd>
        </div>
      </dl>
    </section>
  );
}

type Item = { categoria_id: number; categoria_nome: string; total: string };

function GastosPorCategoria({ itens }: { itens: Item[] }) {
  // A API ordena do maior para o menor; o maior é o primeiro.
  const maior = itens[0]?.total ?? "0";
  return (
    <section aria-labelledby="gastos-categoria">
      <h2 id="gastos-categoria" className="mb-3 text-lg font-semibold">
        Gastos por Categoria
      </h2>
      {itens.length === 0 ? (
        <EstadoVazio>Nenhum gasto neste mês.</EstadoVazio>
      ) : (
        <ul className="space-y-3">
          {itens.map((i) => (
            <li key={i.categoria_id}>
              <div className="mb-1 flex justify-between gap-4">
                <span>{i.categoria_nome}</span>
                <span className="tabular-nums">{formatBRL(i.total)}</span>
              </div>
              <div className="h-2 rounded-full bg-foreground/10" aria-hidden="true">
                <div
                  className="h-2 rounded-full bg-foreground/60"
                  style={{ width: `${larguraBarra(i.total, maior)}%` }}
                />
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

type Parcela = {
  transacao_id: number;
  parcelamento_id: number;
  parcelamento_descricao: string;
  numero_parcela: number;
  num_parcelas_total: number;
  competencia: string;
  valor: string;
  conta_nome: string;
  categoria_nome: string;
};

function ParcelasAtivas({ parcelas }: { parcelas: Parcela[] }) {
  const grupos = agruparPorCompetencia(parcelas);
  return (
    <section aria-labelledby="parcelas-ativas">
      <h2 id="parcelas-ativas" className="text-lg font-semibold">
        Parcelas Ativas
      </h2>
      <p className="mb-3 text-sm text-foreground/70">A partir do mês corrente</p>
      {grupos.length === 0 ? (
        <EstadoVazio>Nenhuma parcela a vencer.</EstadoVazio>
      ) : (
        <div className="space-y-5">
          {grupos.map((g) => (
            <div key={g.competencia}>
              <h3 className="mb-2 text-sm font-medium text-foreground/70 first-letter:uppercase">
                {formatar(g.competencia)}
              </h3>
              <ul className="divide-y divide-foreground/10 rounded-lg border border-foreground/15">
                {g.itens.map((p) => (
                  <li key={p.transacao_id}>
                    <Link
                      href={`/parcelamentos/${p.parcelamento_id}`}
                      className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 p-3 hover:bg-foreground/5"
                    >
                      <span>
                        {p.parcelamento_descricao}{" "}
                        <span className="text-sm text-foreground/70">
                          {p.numero_parcela}/{p.num_parcelas_total}
                        </span>
                        <span className="block text-sm text-foreground/70">
                          {p.conta_nome} · {p.categoria_nome}
                        </span>
                      </span>
                      <span className="tabular-nums">{formatBRL(p.valor)}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
