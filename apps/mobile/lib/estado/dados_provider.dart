import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/providers.dart';

final contasProvider = FutureProvider<List<Conta>>(
  (ref) => ref.watch(repositorioProvider).contas(),
);

final categoriasProvider = FutureProvider<List<Categoria>>(
  (ref) => ref.watch(repositorioProvider).categorias(),
);

/// Filtros que vão para a API; o de tipo é aplicado no cliente.
typedef ParamsTransacoes = ({
  String competencia,
  int? contaId,
  int? categoriaId,
});

final transacoesProvider =
    FutureProvider.family<List<Transacao>, ParamsTransacoes>(
      (ref, p) => ref
          .watch(repositorioProvider)
          .transacoes(
            competencia: p.competencia,
            contaId: p.contaId,
            categoriaId: p.categoriaId,
          ),
    );

/// Sem parcelas; serve para saber o total `N` do selo "n/N".
final parcelamentosProvider = FutureProvider<List<Parcelamento>>(
  (ref) => ref.watch(repositorioProvider).parcelamentos(),
);
