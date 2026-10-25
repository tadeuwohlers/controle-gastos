import 'package:flutter/material.dart';

/// Diálogo de confirmação; devolve `true` só se o usuário confirmar.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required String rotuloConfirmar,
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(rotuloConfirmar),
        ),
      ],
    ),
  );
  return resposta ?? false;
}
