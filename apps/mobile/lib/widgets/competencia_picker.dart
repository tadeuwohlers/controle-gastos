import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/estado/competencia_provider.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;

/// Setas anterior/próximo, o mês por extenso e "Hoje" fora do mês corrente.
class CompetenciaPicker extends ConsumerWidget {
  const CompetenciaPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competencia = ref.watch(competenciaProvider);
    final notifier = ref.read(competenciaProvider.notifier);
    final noMesCorrente = competencia == comp.competenciaAtual();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Competência anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => notifier.deslocar(-1),
        ),
        Flexible(
          child: Text(
            comp.formatar(competencia),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Próxima competência',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => notifier.deslocar(1),
        ),
        if (!noMesCorrente)
          TextButton(onPressed: notifier.hoje, child: const Text('Hoje')),
      ],
    );
  }
}
