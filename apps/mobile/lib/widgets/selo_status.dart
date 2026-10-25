import 'package:flutter/material.dart';

import 'package:controle_gastos/api/modelos.dart';

/// Selo "Ativo" / "Cancelado" do Parcelamento.
class SeloStatus extends StatelessWidget {
  const SeloStatus(this.status, {super.key});

  final StatusParcelamento status;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final cancelado = status == StatusParcelamento.cancelado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cancelado ? cores.errorContainer : cores.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cancelado ? 'Cancelado' : 'Ativo',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cancelado ? cores.onErrorContainer : cores.onPrimaryContainer,
        ),
      ),
    );
  }
}
