import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/lib/erros.dart';
import 'package:controle_gastos/widgets/aviso_com_retry.dart';

/// Mostra o estado de uma leitura: carregando, erro com "Tentar de novo" ou
/// os dados. Em releitura, os dados anteriores continuam na tela com uma
/// barra de progresso.
class AsyncVista<T> extends StatelessWidget {
  const AsyncVista({
    super.key,
    required this.valor,
    required this.onTentar,
    required this.construir,
  });

  final AsyncValue<T> valor;
  final VoidCallback onTentar;
  final Widget Function(BuildContext context, T dados) construir;

  @override
  Widget build(BuildContext context) {
    if (valor.hasValue) {
      return Column(
        children: [
          if (valor.isLoading) const LinearProgressIndicator(),
          Expanded(child: construir(context, valor.requireValue)),
        ],
      );
    }
    final erro = valor.error;
    if (erro != null) {
      final mensagem = erro is ApiException
          ? (erro.ehRedeOu5xx
                ? 'Não foi possível falar com o servidor.'
                : extrairMensagem(erro.corpo))
          : 'Algo deu errado. Tente de novo.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AvisoComRetry(mensagem: mensagem, onTentar: onTentar),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}
