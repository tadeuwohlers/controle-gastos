import 'package:flutter/material.dart';

/// Falha de rede ou `5xx`: aviso com "Tentar de novo", sem perder o que
/// estava na tela.
class AvisoComRetry extends StatelessWidget {
  const AvisoComRetry({
    super.key,
    this.mensagem = 'Não foi possível falar com o servidor.',
    required this.onTentar,
  });

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32),
          const SizedBox(height: 8),
          Text(mensagem, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: onTentar,
            child: const Text('Tentar de novo'),
          ),
        ],
      ),
    );
  }
}
