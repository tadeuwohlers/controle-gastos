import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/competencia_provider.dart';
import 'package:controle_gastos/estado/dados_provider.dart';
import 'package:controle_gastos/estado/invalidacao.dart';
import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/widgets/async_vista.dart';
import 'package:controle_gastos/widgets/confirmar_dialog.dart';
import 'package:controle_gastos/widgets/estado_vazio.dart';
import 'package:controle_gastos/widgets/linha_adaptativa.dart';
import 'package:controle_gastos/widgets/transacao_sheet.dart';

class TransacoesTela extends ConsumerStatefulWidget {
  const TransacoesTela({super.key});

  @override
  ConsumerState<TransacoesTela> createState() => _TransacoesTelaState();
}

class _TransacoesTelaState extends ConsumerState<TransacoesTela> {
  // Filtros em estado local da tela; resetam ao sair dela (spec 003).
  TipoTransacao? _tipo;
  int? _contaId;
  int? _categoriaId;

  Future<void> _excluir(Transacao t) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir transação?',
      mensagem: '"${t.descricao}" (${formatBRL(t.valor)}) será removida.',
      rotuloConfirmar: 'Excluir',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(repositorioProvider).excluirTransacao(t.id);
      if (!mounted) return;
      invalidarAposTransacao(ref);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.ehRedeOu5xx
                ? 'Não foi possível excluir. Tente de novo.'
                : e.mensagem,
          ),
        ),
      );
    }
  }

  void _editar(Transacao t) =>
      abrirTransacaoSheet(context, competencia: t.competencia, editar: t);

  Future<void> _menu(Transacao t) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar'),
              onTap: () => Navigator.of(ctx).pop('editar'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Excluir'),
              onTap: () => Navigator.of(ctx).pop('excluir'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (acao == 'editar') _editar(t);
    if (acao == 'excluir') await _excluir(t);
  }

  @override
  Widget build(BuildContext context) {
    final competencia = ref.watch(competenciaProvider);
    final params = (
      competencia: competencia,
      contaId: _contaId,
      categoriaId: _categoriaId,
    );
    final transacoes = ref.watch(transacoesProvider(params));
    final contas = ref.watch(contasProvider).asData?.value ?? const <Conta>[];
    final categorias =
        ref.watch(categoriasProvider).asData?.value ?? const <Categoria>[];
    final parcelamentos =
        ref.watch(parcelamentosProvider(null)).asData?.value ??
        const <Parcelamento>[];

    final categoriasDoFiltro = [
      for (final c in categorias)
        if (_tipo == null || c.tipo == _tipo) c,
    ];
    final nomeConta = {for (final c in contas) c.id: c.nome};
    final nomeCategoria = {for (final c in categorias) c.id: c.nome};
    final totalParcelas = {for (final p in parcelamentos) p.id: p.numParcelas};

    return Column(
      children: [
        _Filtros(
          tipo: _tipo,
          contaId: _contaId,
          categoriaId: _categoriaId,
          contas: contas,
          categorias: categoriasDoFiltro,
          onTipo: (t) => setState(() {
            _tipo = t;
            final ainda = categoriasDoFiltro.any(
              (c) => c.id == _categoriaId && (t == null || c.tipo == t),
            );
            if (!ainda) _categoriaId = null;
          }),
          onConta: (v) => setState(() => _contaId = v),
          onCategoria: (v) => setState(() => _categoriaId = v),
        ),
        Expanded(
          child: AsyncVista<List<Transacao>>(
            valor: transacoes,
            onTentar: () => ref.invalidate(transacoesProvider(params)),
            construir: (context, todas) {
              final lista = [
                for (final t in todas)
                  if (_tipo == null || t.tipo == _tipo) t,
              ];
              if (lista.isEmpty) {
                return EstadoVazio(
                  mensagem: 'Nenhuma transação neste mês.',
                  rotuloAcao: 'Nova transação',
                  onAcao: () =>
                      abrirTransacaoSheet(context, competencia: competencia),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(transacoesProvider(params));
                  await ref.read(transacoesProvider(params).future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final t = lista[i];
                    return _Linha(
                      transacao: t,
                      conta: nomeConta[t.contaId] ?? '—',
                      categoria: nomeCategoria[t.categoriaId] ?? '—',
                      totalParcelas: totalParcelas[t.parcelamentoId],
                      onEditar: () => _editar(t),
                      onMenu: () => _menu(t),
                      onExcluir: () async {
                        await _excluir(t);
                        return false;
                      },
                      onAbrirParcelamento: () =>
                          context.go('/parcelamentos/${t.parcelamentoId}'),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    required this.tipo,
    required this.contaId,
    required this.categoriaId,
    required this.contas,
    required this.categorias,
    required this.onTipo,
    required this.onConta,
    required this.onCategoria,
  });

  final TipoTransacao? tipo;
  final int? contaId;
  final int? categoriaId;
  final List<Conta> contas;
  final List<Categoria> categorias;
  final ValueChanged<TipoTransacao?> onTipo;
  final ValueChanged<int?> onConta;
  final ValueChanged<int?> onCategoria;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: tipo == null,
                onSelected: (_) => onTipo(null),
              ),
              ChoiceChip(
                label: const Text('Gastos'),
                selected: tipo == TipoTransacao.gasto,
                onSelected: (_) => onTipo(TipoTransacao.gasto),
              ),
              ChoiceChip(
                label: const Text('Receitas'),
                selected: tipo == TipoTransacao.receita,
                onSelected: (_) => onTipo(TipoTransacao.receita),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('filtro-conta-$contaId'),
                  initialValue: contaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Conta',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final c in contas)
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.nome)),
                  ],
                  onChanged: onConta,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  key: ValueKey('filtro-categoria-$categoriaId-$tipo'),
                  initialValue: categoriaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    for (final c in categorias)
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.nome)),
                  ],
                  onChanged: onCategoria,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.transacao,
    required this.conta,
    required this.categoria,
    required this.totalParcelas,
    required this.onEditar,
    required this.onMenu,
    required this.onExcluir,
    required this.onAbrirParcelamento,
  });

  final Transacao transacao;
  final String conta;
  final String categoria;
  final int? totalParcelas;
  final VoidCallback onEditar;
  final VoidCallback onMenu;
  final Future<bool> Function() onExcluir;
  final VoidCallback onAbrirParcelamento;

  @override
  Widget build(BuildContext context) {
    final t = transacao;
    final cores = Theme.of(context).colorScheme;
    final gasto = t.tipo == TipoTransacao.gasto;
    final cor = gasto ? cores.error : cores.primary;
    final selo = t.ehParcela
        ? (totalParcelas == null
              ? '${t.numeroParcela}'
              : '${t.numeroParcela}/$totalParcelas')
        : null;

    final tile = LinhaAdaptativa(
      leading: Icon(
        gasto ? Icons.arrow_downward : Icons.arrow_upward,
        color: cor,
        semanticLabel: gasto ? 'Gasto' : 'Receita',
      ),
      titulo: Text(t.descricao),
      subtitulo: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('$categoria • $conta'),
          if (selo != null)
            ActionChip(
              label: Text(selo),
              tooltip: 'Abrir Parcelamento',
              onPressed: onAbrirParcelamento,
            ),
        ],
      ),
      trailing: Text(
        '${gasto ? '−' : '+'} ${formatBRL(t.valor)}',
        style: TextStyle(color: cor, fontWeight: FontWeight.w600),
      ),
      onTap: t.ehParcela ? onAbrirParcelamento : onEditar,
      onLongPress: t.ehParcela ? null : onMenu,
    );

    if (t.ehParcela) return tile;
    return Dismissible(
      key: ValueKey('transacao-${t.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onExcluir(),
      background: Container(
        color: cores.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: cores.onErrorContainer),
      ),
      child: tile,
    );
  }
}
