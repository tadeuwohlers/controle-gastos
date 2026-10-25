import 'package:controle_gastos/lib/resumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fracaoBarra', () {
    test('o maior ocupa a barra inteira', () {
      expect(fracaoBarra('1200.00', '1200.00'), 1);
    });
    test('proporção em relação ao maior', () {
      expect(fracaoBarra('300.00', '1200.00'), 0.25);
    });
    test('maior zero ou inválido dá barra vazia', () {
      expect(fracaoBarra('10.00', '0.00'), 0);
      expect(fracaoBarra('10.00', 'x'), 0);
    });
    test('limita entre 0 e 1', () {
      expect(fracaoBarra('2000.00', '1000.00'), 1);
      expect(fracaoBarra('-5.00', '1000.00'), 0);
    });
  });

  group('agruparPorCompetencia', () {
    test('ordena os meses e preserva a ordem dentro do grupo', () {
      final grupos = agruparPorCompetencia<(String, String)>([
        ('2026-12', 'c'),
        ('2026-10', 'a'),
        ('2026-12', 'd'),
        ('2026-11', 'b'),
      ], (e) => e.$1);
      expect(grupos.map((g) => g.competencia), [
        '2026-10',
        '2026-11',
        '2026-12',
      ]);
      expect(grupos.last.itens.map((e) => e.$2), ['c', 'd']);
    });
    test('lista vazia não gera grupos', () {
      expect(agruparPorCompetencia<String>([], (e) => e), isEmpty);
    });
    test('vira o ano na ordem cronológica', () {
      final grupos = agruparPorCompetencia<String>([
        '2027-01',
        '2026-12',
      ], (e) => e);
      expect(grupos.map((g) => g.competencia), ['2026-12', '2027-01']);
    });
  });
}
