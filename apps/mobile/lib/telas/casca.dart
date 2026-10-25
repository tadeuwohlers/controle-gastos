import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/widgets/competencia_picker.dart';
import 'package:controle_gastos/widgets/transacao_sheet.dart';

/// Moldura do app: barra inferior com os 4 destinos, seletor de Competência
/// (Resumo e Transações) e o botão "Nova transação" em todas as abas.
class Casca extends StatelessWidget {
  const Casca({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinos = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Resumo'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Transações'),
    (Icons.credit_card_outlined, Icons.credit_card, 'Parcelamentos'),
    (
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      'Cadastros',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final comSeletor = shell.currentIndex <= 1;
    return Scaffold(
      appBar: comSeletor
          ? AppBar(title: const CompetenciaPicker(), centerTitle: true)
          : null,
      body: SafeArea(top: !comSeletor, child: shell),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirTransacaoSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova transação'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          for (final (icone, selecionado, rotulo) in _destinos)
            NavigationDestination(
              icon: Icon(icone),
              selectedIcon: Icon(selecionado),
              label: rotulo,
            ),
        ],
      ),
    );
  }
}
