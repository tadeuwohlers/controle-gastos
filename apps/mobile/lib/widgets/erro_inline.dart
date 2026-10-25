import 'package:flutter/material.dart';

/// Mensagem de erro de formulário (`409`/`422`), com o `detail` da API.
class ErroInline extends StatelessWidget {
  const ErroInline(this.mensagem, {super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cores.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: cores.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: TextStyle(color: cores.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
