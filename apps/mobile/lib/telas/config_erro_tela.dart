import 'package:flutter/material.dart';

/// Mostrada quando o build não recebeu `--dart-define=API_URL=...`.
class ConfigErroTela extends StatelessWidget {
  const ConfigErroTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API não configurada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Este build não sabe onde está a API. Rode o app com '
                '--dart-define=API_URL=http://<host>:8000 '
                '(veja apps/mobile/CLAUDE.md).',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
