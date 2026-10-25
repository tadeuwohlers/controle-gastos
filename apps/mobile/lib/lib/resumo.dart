import 'package:controle_gastos/lib/competencia.dart';

/// Largura da barra entre 0 e 1, só visual. Único uso de `double` sobre
/// valores: nunca é exibido, somado nem comparado como dinheiro.
double fracaoBarra(String total, String maior) {
  final max = double.tryParse(maior) ?? 0;
  if (!(max > 0)) return 0;
  final fracao = (double.tryParse(total) ?? 0) / max;
  return fracao.clamp(0.0, 1.0);
}

/// Agrupa por `competencia` em ordem cronológica, preservando a ordem de
/// entrada dentro de cada grupo.
List<({String competencia, List<T> itens})> agruparPorCompetencia<T>(
  List<T> itens,
  String Function(T) competenciaDe,
) {
  final grupos = <String, List<T>>{};
  for (final item in itens) {
    grupos.putIfAbsent(competenciaDe(item), () => []).add(item);
  }
  final chaves = grupos.keys.toList()..sort(comparar);
  return [for (final c in chaves) (competencia: c, itens: grupos[c]!)];
}
