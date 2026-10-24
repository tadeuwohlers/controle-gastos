import { connection } from "next/server";
import { Suspense } from "react";
import { EstadoVazio } from "@/components/estado-vazio";
import { FiltrosTransacoes } from "@/components/filtros-transacoes";
import { TransacoesList, type Linha } from "@/components/transacoes-list";
import { BotaoNovaTransacao } from "@/components/transacao-drawer";
import {
  listarCategorias,
  listarContas,
  listarParcelamentos,
  listarTransacoes,
} from "@/lib/dados";
import { lerFiltros } from "@/lib/filtros";

async function Conteudo({ searchParams }: { searchParams: PageProps<"/transacoes">["searchParams"] }) {
  // O "mês corrente" padrão depende do relógio: só pode ser lido em tempo de requisição.
  await connection();
  const f = lerFiltros(await searchParams);
  const [contas, categorias, transacoes] = await Promise.all([
    listarContas(),
    listarCategorias(),
    listarTransacoes({
      competencia: f.mes,
      ...(f.contaId !== null && { conta_id: f.contaId }),
      ...(f.categoriaId !== null && { categoria_id: f.categoriaId }),
    }),
  ]);
  const visiveis = f.tipo ? transacoes.filter((t) => t.tipo === f.tipo) : transacoes;

  const temParcela = visiveis.some((t) => t.parcelamento_id !== null);
  const totais = new Map(
    temParcela ? (await listarParcelamentos()).map((p) => [p.id, p.num_parcelas]) : [],
  );
  const nomeConta = new Map(contas.map((c) => [c.id, c.nome]));
  const nomeCategoria = new Map(categorias.map((c) => [c.id, c.nome]));
  const linhas: Linha[] = visiveis.map((t) => ({
    ...t,
    contaNome: nomeConta.get(t.conta_id) ?? "—",
    categoriaNome: nomeCategoria.get(t.categoria_id) ?? "—",
    totalParcelas: t.parcelamento_id !== null ? (totais.get(t.parcelamento_id) ?? null) : null,
  }));

  return (
    <>
      <FiltrosTransacoes
        contas={contas}
        categorias={categorias}
        tipo={f.tipo}
        contaId={f.contaId}
        categoriaId={f.categoriaId}
      />
      {linhas.length === 0 ? (
        <div className="flex flex-col items-center gap-4">
          <EstadoVazio>Nenhuma transação neste mês.</EstadoVazio>
          <BotaoNovaTransacao />
        </div>
      ) : (
        <TransacoesList linhas={linhas} />
      )}
    </>
  );
}

export default function Transacoes(props: PageProps<"/transacoes">) {
  return (
    <>
      <h1 className="mb-4 text-2xl font-semibold">Transações</h1>
      <Suspense fallback={<p className="text-foreground/70">Carregando…</p>}>
        <Conteudo searchParams={props.searchParams} />
      </Suspense>
    </>
  );
}
