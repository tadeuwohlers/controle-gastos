import 'package:flutter/material.dart';

/// Bottom sheet de "Nova transação". O formulário entra na fatia 2.
Future<void> abrirTransacaoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const SizedBox(
      height: 240,
      child: Center(child: Text('Nova transação: em construção')),
    ),
  );
}
