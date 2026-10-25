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

/// Listagem sem parcelas, opcionalmente filtrada por status. Sem filtro,
/// também serve para saber o total `N` do selo "n/N" das Transações.
final parcelamentosProvider =
    FutureProvider.family<List<Parcelamento>, StatusParcelamento?>(
      (ref, status) =>
          ref.watch(repositorioProvider).parcelamentos(status: status),
    );

/// Detalhe, com as Parcelas.
final parcelamentoProvider = FutureProvider.family<Parcelamento, int>(
  (ref, id) => ref.watch(repositorioProvider).parcelamento(id),
);

final balancoProvider = FutureProvider.family<BalancoMensal, String>(
  (ref, competencia) =>
      ref.watch(repositorioProvider).balancoMensal(competencia),
);

final gastosPorCategoriaProvider =
    FutureProvider.family<GastosPorCategoria, String>(
      (ref, competencia) =>
          ref.watch(repositorioProvider).gastosPorCategoria(competencia),
    );

/// Não recebe Competência: a API lista do mês corrente em diante.
final parcelasAtivasProvider = FutureProvider<List<ParcelaAtiva>>(
  (ref) => ref.watch(repositorioProvider).parcelasAtivas(),
);
