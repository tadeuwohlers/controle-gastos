import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/estado/dados_provider.dart';

/// Tabela de invalidação da spec 003: o que reler após cada mutação.
void invalidarAposTransacao(WidgetRef ref) {
  ref.invalidate(transacoesProvider);
  invalidarRelatorios(ref);
}

void invalidarRelatorios(WidgetRef ref) {
  ref.invalidate(balancoProvider);
  ref.invalidate(gastosPorCategoriaProvider);
  ref.invalidate(parcelasAtivasProvider);
}

void invalidarAposConta(WidgetRef ref) => ref.invalidate(contasProvider);

void invalidarAposCategoria(WidgetRef ref) =>
    ref.invalidate(categoriasProvider);
