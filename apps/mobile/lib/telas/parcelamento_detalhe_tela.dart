import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/dados_provider.dart';
import 'package:controle_gastos/estado/invalidacao.dart';
import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/lib/parcelamento.dart';
import 'package:controle_gastos/widgets/async_vista.dart';
import 'package:controle_gastos/widgets/aviso_com_retry.dart';
import 'package:controle_gastos/widgets/confirmar_dialog.dart';
import 'package:controle_gastos/widgets/erro_inline.dart';
import 'package:controle_gastos/widgets/selo_status.dart';

class ParcelamentoDetalheTela extends ConsumerStatefulWidget {
  const ParcelamentoDetalheTela({super.key, required this.id});

  /// `null` quando o `:id` da rota não é um inteiro.
  final int? id;

  @override
  ConsumerState<ParcelamentoDetalheTela> createState() =>
      _ParcelamentoDetalheTelaState();
}

class _ParcelamentoDetalheTelaState
    extends ConsumerState<ParcelamentoDetalheTela> {
  String? _aviso;
  String? _avisoErro;
  bool _falhaRede = false;
  bool _cancelando = false;

  Future<void> _pedirCancelamento(Parcelamento p) async {
    // A prévia é calculada na hora (o mês pode ter virado desde que a tela abriu).
    final previa = previaCancelamento([
      for (final x in p.parcelas) x.competencia,
    ]);
    final mensagem = previa.removidas == 0
        ? 'Não há parcelas futuras: apenas o status muda para cancelado.'
        : 'Remove ${plural(previa.removidas, 'parcela futura', 'parcelas futuras')}; '
              '${previa.preservadas} (a do mês atual e as passadas) permanecem.';
    final ok = await confirmar(
      context,
      titulo: 'Cancelar parcelamento?',
      mensagem: mensagem,
      rotuloConfirmar: 'Cancelar parcelamento',
    );
    if (!ok || !mounted) return;
    await _cancelar(p.id);
  }

  Future<void> _cancelar(int id) async {
    setState(() {
      _cancelando = true;
      _falhaRede = false;
      _avisoErro = null;
    });
    try {
      final r = await ref.read(repositorioProvider).cancelarParcelamento(id);
      if (!mounted) return;
      invalidarAposParcelamento(ref);
      // Os números exibidos são os da API; prevalecem sobre a prévia.
      setState(() {
        _cancelando = false;
        _aviso =
            'Parcelamento cancelado. '
            '${plural(r.parcelasRemovidas, 'parcela futura removida', 'parcelas futuras removidas')}; '
            '${plural(r.parcelasPreservadas, 'preservada', 'preservadas')}.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.ehRedeOu5xx) {
        setState(() {
          _cancelando = false;
          _falhaRede = true;
        });
        return;
      }
      // Ex.: 422 "Parcelamento já cancelado." (outra aba cancelou antes).
      // Recarrega, e a tela passa a mostrar o status real.
      invalidarAposParcelamento(ref);
      setState(() {
        _cancelando = false;
        _avisoErro = e.mensagem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Parcelamento')),
      body: id == null ? const _NaoEncontrado() : _corpo(id),
    );
  }

  Widget _corpo(int id) {
    final detalhe = ref.watch(parcelamentoProvider(id));
    final contas = ref.watch(contasProvider).asData?.value ?? const <Conta>[];
    final categorias =
        ref.watch(categoriasProvider).asData?.value ?? const <Categoria>[];

    final erro = detalhe.error;
    if (!detalhe.hasValue && erro is ApiException && erro.status == 404) {
      return const _NaoEncontrado();
    }

    return AsyncVista<Parcelamento>(
      valor: detalhe,
      onTentar: () => ref.invalidate(parcelamentoProvider(id)),
      construir: (context, p) {
        final nomeConta = {for (final c in contas) c.id: c.nome}[p.contaId];
        final nomeCategoria = {
          for (final c in categorias) c.id: c.nome,
        }[p.categoriaId];
        final atual = comp.competenciaAtual();
        final parcelas = [...p.parcelas]
          ..sort((a, b) => a.numeroParcela.compareTo(b.numeroParcela));
        final texto = Theme.of(context).textTheme;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(parcelamentoProvider(id));
            await ref.read(parcelamentoProvider(id).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (_aviso != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_aviso!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_avisoErro != null) ...[
                ErroInline(_avisoErro!),
                const SizedBox(height: 12),
              ],
              if (_falhaRede) ...[
                AvisoComRetry(onTentar: () => _cancelar(p.id)),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(child: Text(p.descricao, style: texto.titleLarge)),
                  SeloStatus(p.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatBRL(p.valorTotal)} em ${p.numParcelas}×',
                style: texto.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${nomeCategoria ?? '—'} • ${nomeConta ?? '—'}\n'
                '1ª parcela em ${comp.formatar(p.primeiraParcela)}',
                style: texto.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('Parcelas', style: texto.titleMedium),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final x in parcelas)
                      _LinhaParcela(
                        parcela: x,
                        total: p.numParcelas,
                        situacao: comp.comparar(x.competencia, atual),
                      ),
                  ],
                ),
              ),
              if (p.status == StatusParcelamento.ativo) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _cancelando ? null : () => _pedirCancelamento(p),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Cancelar parcelamento'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LinhaParcela extends StatelessWidget {
  const _LinhaParcela({
    required this.parcela,
    required this.total,
    required this.situacao,
  });

  final Parcela parcela;
  final int total;

  /// -1 passada, 0 do mês corrente, 1 futura.
  final int situacao;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final atual = situacao == 0;
    final linha = ListTile(
      tileColor: atual ? cores.primaryContainer : null,
      title: Text('${parcela.numeroParcela}/$total'),
      subtitle: Text(
        atual
            ? '${comp.formatar(parcela.competencia)} · mês atual'
            : comp.formatar(parcela.competencia),
      ),
      trailing: Text(formatBRL(parcela.valor)),
    );
    // Passadas esmaecidas; o texto continua lendo normalmente.
    return situacao < 0 ? Opacity(opacity: 0.55, child: linha) : linha;
  }
}

class _NaoEncontrado extends StatelessWidget {
  const _NaoEncontrado();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Parcelamento não encontrado.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/parcelamentos'),
              child: const Text('Voltar aos Parcelamentos'),
            ),
          ],
        ),
      ),
    );
  }
}
