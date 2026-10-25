import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Competência selecionada, compartilhada entre Resumo e Transações.
class CompetenciaNotifier extends Notifier<String> {
  @override
  String build() => comp.competenciaAtual();

  void deslocar(int meses) => state = comp.deslocar(state, meses);

  void definir(String competencia) {
    if (comp.valida(competencia)) state = competencia;
  }

  void hoje() => state = comp.competenciaAtual();
}

final competenciaProvider = NotifierProvider<CompetenciaNotifier, String>(
  CompetenciaNotifier.new,
);
