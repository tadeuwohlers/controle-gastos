import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:controle_gastos/telas/cadastros_tela.dart';
import 'package:controle_gastos/telas/casca.dart';
import 'package:controle_gastos/telas/parcelamento_detalhe_tela.dart';
import 'package:controle_gastos/telas/parcelamentos_tela.dart';
import 'package:controle_gastos/telas/resumo_tela.dart';
import 'package:controle_gastos/telas/transacoes_tela.dart';

final roteadorProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Casca(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const ResumoTela())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transacoes',
                builder: (_, _) => const TransacoesTela(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/parcelamentos',
                builder: (_, _) => const ParcelamentosTela(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => ParcelamentoDetalheTela(
                      id: int.tryParse(state.pathParameters['id'] ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cadastros',
                builder: (_, _) => const CadastrosTela(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
