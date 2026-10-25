import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/estado/dados_provider.dart';

/// Tabela de invalidação da spec 003: o que reler após cada mutação.
/// Os relatórios entram aqui quando suas telas existirem.
void invalidarAposTransacao(WidgetRef ref) {
  ref.invalidate(transacoesProvider);
}

void invalidarAposConta(WidgetRef ref) => ref.invalidate(contasProvider);

void invalidarAposCategoria(WidgetRef ref) =>
    ref.invalidate(categoriasProvider);
