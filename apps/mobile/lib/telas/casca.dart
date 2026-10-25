import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/estado/competencia_provider.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:controle_gastos/widgets/competencia_picker.dart';
import 'package:controle_gastos/widgets/transacao_sheet.dart';

/// Moldura do app: barra inferior com os 4 destinos, seletor de Competência
/// (Resumo e Transações) e o botão "Nova transação" em todas as abas.
class Casca extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final comSeletor = shell.currentIndex <= 1;
    return Scaffold(
      appBar: comSeletor
          ? AppBar(title: const CompetenciaPicker(), centerTitle: true)
          : null,
      body: SafeArea(top: !comSeletor, child: shell),
      floatingActionButton: _LimiteDeFonte(
        child: FloatingActionButton.extended(
          onPressed: () => abrirTransacaoSheet(
            context,
            // Competência selecionada nas telas com seletor; o mês corrente
            // fora delas.
            competencia: comSeletor
                ? ref.read(competenciaProvider)
                : comp.competenciaAtual(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova transação'),
        ),
      ),
      bottomNavigationBar: _LimiteDeFonte(
        // Cada aba tem um quarto da largura: acima da escala normal,
        // "Parcelamentos" quebra no meio da palavra.
        maximo: 1.0,
        child: NavigationBar(
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
      ),
    );
  }
}

/// Barra inferior e botão flutuante ficam fixos na tela: com a fonte do sistema
/// no máximo, os rótulos quebram no meio e o botão cobre o conteúdo. O resto
/// do app segue a fonte do sistema sem limite.
class _LimiteDeFonte extends StatelessWidget {
  const _LimiteDeFonte({required this.child, this.maximo = 1.3});

  final Widget child;
  final double maximo;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.withClampedTextScaling(maxScaleFactor: maximo, child: child);
}
