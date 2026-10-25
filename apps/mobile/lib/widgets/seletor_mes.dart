import 'package:flutter/material.dart';

import 'package:controle_gastos/lib/competencia.dart' as comp;

/// Escolha de Competência por setas, para campos de formulário.
class SeletorMes extends StatelessWidget {
  const SeletorMes({
    super.key,
    required this.rotulo,
    required this.competencia,
    required this.onChanged,
    this.erro,
  });

  final String rotulo;
  final String competencia;
  final ValueChanged<String> onChanged;
  final String? erro;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: rotulo, errorText: erro),
      child: Row(
        children: [
          IconButton(
            tooltip: '$rotulo anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(comp.deslocar(competencia, -1)),
          ),
          Expanded(
            child: Text(
              comp.formatar(competencia),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: '$rotulo seguinte',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onChanged(comp.deslocar(competencia, 1)),
          ),
        ],
      ),
    );
  }
}
