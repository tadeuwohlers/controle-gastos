import 'package:flutter/material.dart';

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.mensagem,
    this.detalhe,
    this.rotuloAcao,
    this.onAcao,
  });

  final String mensagem;
  final String? detalhe;
  final String? rotuloAcao;
  final VoidCallback? onAcao;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagem,
              style: texto.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (detalhe != null) ...[
              const SizedBox(height: 8),
              Text(detalhe!, textAlign: TextAlign.center),
            ],
            if (rotuloAcao != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAcao, child: Text(rotuloAcao!)),
            ],
          ],
        ),
      ),
    );
  }
}
