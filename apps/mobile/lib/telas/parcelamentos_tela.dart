import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/dados_provider.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/widgets/async_vista.dart';
import 'package:controle_gastos/widgets/estado_vazio.dart';
import 'package:controle_gastos/widgets/selo_status.dart';
import 'package:controle_gastos/widgets/transacao_sheet.dart';

class ParcelamentosTela extends ConsumerStatefulWidget {
  const ParcelamentosTela({super.key});

  @override
  ConsumerState<ParcelamentosTela> createState() => _ParcelamentosTelaState();
}

class _ParcelamentosTelaState extends ConsumerState<ParcelamentosTela> {
  StatusParcelamento? _status;

  @override
  Widget build(BuildContext context) {
    final parcelamentos = ref.watch(parcelamentosProvider(_status));
    final contas = ref.watch(contasProvider).asData?.value ?? const <Conta>[];
    final categorias =
        ref.watch(categoriasProvider).asData?.value ?? const <Categoria>[];
    final nomeConta = {for (final c in contas) c.id: c.nome};
    final nomeCategoria = {for (final c in categorias) c.id: c.nome};

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  ChoiceChip(
                    label: const Text('Ativos'),
                    selected: _status == StatusParcelamento.ativo,
                    onSelected: (_) =>
                        setState(() => _status = StatusParcelamento.ativo),
                  ),
                  ChoiceChip(
                    label: const Text('Cancelados'),
                    selected: _status == StatusParcelamento.cancelado,
                    onSelected: (_) =>
                        setState(() => _status = StatusParcelamento.cancelado),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AsyncVista<List<Parcelamento>>(
              valor: parcelamentos,
              onTentar: () => ref.invalidate(parcelamentosProvider(_status)),
              construir: (context, lista) {
                if (lista.isEmpty) {
                  return EstadoVazio(
                    mensagem: 'Nenhum parcelamento.',
                    detalhe:
                        'Um Parcelamento nasce na "Nova transação", '
                        'em "Parcelado".',
                    rotuloAcao: 'Nova transação',
                    onAcao: () => abrirTransacaoSheet(
                      context,
                      competencia: comp.competenciaAtual(),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(parcelamentosProvider(_status));
                    await ref.read(parcelamentosProvider(_status).future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 96),
                    itemCount: lista.length,
                    itemBuilder: (context, i) {
                      final p = lista[i];
                      return ListTile(
                        title: Text(p.descricao),
                        subtitle: Text(
                          '${p.numParcelas}× · 1ª em '
                          '${comp.formatar(p.primeiraParcela)}\n'
                          '${nomeCategoria[p.categoriaId] ?? '—'} • '
                          '${nomeConta[p.contaId] ?? '—'}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatBRL(p.valorTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SeloStatus(p.status),
                          ],
                        ),
                        onTap: () => context.go('/parcelamentos/${p.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
