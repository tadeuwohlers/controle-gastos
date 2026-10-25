import 'package:flutter/material.dart';

class ParcelamentoDetalheTela extends StatelessWidget {
  const ParcelamentoDetalheTela({super.key, required this.id});

  /// `null` quando o `:id` da rota não é um inteiro.
  final int? id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parcelamento')),
      body: const Center(child: Text('Detalhe: em construção')),
    );
  }
}
