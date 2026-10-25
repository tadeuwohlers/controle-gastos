import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/widgets/transacao_form.dart';

/// Bottom sheet de criar (ou editar, com [editar]) uma Transação Avulsa, ou de
/// criar um Parcelamento. [competencia] é a inicial ao criar: a selecionada,
/// ou a corrente fora das telas com seletor. Ao criar um Parcelamento o sheet
/// fecha e o app abre o detalhe dele.
Future<void> abrirTransacaoSheet(
  BuildContext context, {
  required String competencia,
  Transacao? editar,
}) {
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    // Raiz: o sheet cobre a barra inferior e o botão, não só a aba.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: TransacaoForm(
        competencia: competencia,
        editar: editar,
        aoFechar: () => Navigator.of(ctx).pop(),
        aoCriarParcelamento: (id) {
          Navigator.of(ctx).pop();
          router.go('/parcelamentos/$id');
        },
      ),
    ),
  );
}
