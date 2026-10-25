import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/competencia_provider.dart';
import 'package:controle_gastos/estado/dados_provider.dart';
import 'package:controle_gastos/estado/invalidacao.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/lib/resumo.dart';
import 'package:controle_gastos/widgets/async_vista.dart';

class ResumoTela extends ConsumerWidget {
  const ResumoTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competencia = ref.watch(competenciaProvider);
    final balanco = ref.watch(balancoProvider(competencia));
    final gastos = ref.watch(gastosPorCategoriaProvider(competencia));
    final parcelas = ref.watch(parcelasAtivasProvider);

    return RefreshIndicator(
      onRefresh: () async {
        invalidarRelatorios(ref);
        await Future.wait([
          ref
              .read(balancoProvider(competencia).future)
              .then((_) {}, onError: (_) {}),
          ref
              .read(gastosPorCategoriaProvider(competencia).future)
              .then((_) {}, onError: (_) {}),
          ref.read(parcelasAtivasProvider.future).then((_) {}, onError: (_) {}),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _Titulo('Balanço Mensal', balanco.isLoading && balanco.hasValue),
          AsyncSecao<BalancoMensal>(
            valor: balanco,
            onTentar: () => ref.invalidate(balancoProvider(competencia)),
            construir: (_, b) => _Balanco(b),
          ),
          const SizedBox(height: 24),
          _Titulo('Gastos por Categoria', gastos.isLoading && gastos.hasValue),
          AsyncSecao<GastosPorCategoria>(
            valor: gastos,
            onTentar: () =>
                ref.invalidate(gastosPorCategoriaProvider(competencia)),
            construir: (_, g) => _GastosPorCategoria(g.itens),
          ),
          const SizedBox(height: 24),
          _Titulo('Parcelas Ativas', parcelas.isLoading && parcelas.hasValue),
          Text(
            'A partir do mês corrente',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          AsyncSecao<List<ParcelaAtiva>>(
            valor: parcelas,
            onTentar: () => ref.invalidate(parcelasAtivasProvider),
            construir: (_, p) => _ParcelasAtivas(p),
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, this.atualizando);

  final String texto;
  final bool atualizando;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                texto,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (atualizando)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _Balanco extends StatelessWidget {
  const _Balanco(this.balanco);

  final BalancoMensal balanco;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final s = sinal(balanco.saldo);
    final (cor, icone, texto) = switch (s) {
      Sinal.positivo => (cores.primary, '▲', 'Superávit'),
      Sinal.negativo => (cores.error, '▼', 'Déficit'),
      Sinal.zero => (cores.onSurface, '•', 'Zerado'),
    };
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Cartao('Receitas', formatBRL(balanco.totalReceitas)),
            ),
            const SizedBox(width: 12),
            Expanded(child: _Cartao('Gastos', formatBRL(balanco.totalGastos))),
          ],
        ),
        const SizedBox(height: 12),
        _Cartao(
          'Saldo',
          '$icone ${formatBRL(balanco.saldo)}',
          cor: cor,
          complemento: texto,
        ),
      ],
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao(this.rotulo, this.valor, {this.cor, this.complemento});

  final String rotulo;
  final String valor;
  final Color? cor;
  final String? complemento;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: texto.bodySmall),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  style: texto.titleLarge?.copyWith(
                    color: cor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (complemento != null)
                Text(complemento!, style: texto.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _GastosPorCategoria extends StatelessWidget {
  const _GastosPorCategoria(this.itens);

  final List<GastoCategoria> itens;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const Text('Nenhum gasto neste mês.');
    // A API ordena do maior para o menor; o maior é o primeiro.
    final maior = itens.first.total;
    return Column(
      children: [
        for (final i in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(i.categoriaNome)),
                    const SizedBox(width: 12),
                    Text(formatBRL(i.total)),
                  ],
                ),
                const SizedBox(height: 4),
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fracaoBarra(i.total, maior),
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ParcelasAtivas extends StatelessWidget {
  const _ParcelasAtivas(this.parcelas);

  final List<ParcelaAtiva> parcelas;

  @override
  Widget build(BuildContext context) {
    final grupos = agruparPorCompetencia(parcelas, (p) => p.competencia);
    if (grupos.isEmpty) return const Text('Nenhuma parcela a vencer.');
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in grupos) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _capitalizar(comp.formatar(g.competencia)),
              style: texto.labelLarge,
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final p in g.itens)
                  ListTile(
                    title: Text(
                      '${p.parcelamentoDescricao}  ${p.numeroParcela}/${p.numParcelasTotal}',
                    ),
                    subtitle: Text('${p.contaNome} · ${p.categoriaNome}'),
                    trailing: Text(formatBRL(p.valor)),
                    onTap: () =>
                        context.go('/parcelamentos/${p.parcelamentoId}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _capitalizar(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
