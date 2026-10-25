import 'package:controle_gastos/lib/competencia.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('valida', () {
    for (final c in ['2026-01', '2026-12', '1999-06']) {
      test('aceita $c', () => expect(valida(c), isTrue));
    }
    for (final c in [
      '2026-00',
      '2026-13',
      '26-10',
      '2026-1',
      '2026/10',
      '',
      'abc',
      '2026-10-01',
    ]) {
      test('rejeita "$c"', () => expect(valida(c), isFalse));
    }
  });

  group('deslocar', () {
    test(
      'vira o ano para frente',
      () => expect(deslocar('2026-12', 1), '2027-01'),
    );
    test(
      'vira o ano para trás',
      () => expect(deslocar('2026-01', -1), '2025-12'),
    );
    test(
      'desloca vários meses',
      () => expect(deslocar('2026-10', 14), '2027-12'),
    );
    test('zero mantém', () => expect(deslocar('2026-10', 0), '2026-10'));
  });

  group('formatar', () {
    test('escreve por extenso', () {
      expect(formatar('2026-10'), 'outubro de 2026');
      expect(formatar('2027-03'), 'março de 2027');
    });
  });

  group('comparar', () {
    test('ordena cronologicamente', () {
      expect(comparar('2026-09', '2026-10'), -1);
      expect(comparar('2027-01', '2026-12'), 1);
      expect(comparar('2026-10', '2026-10'), 0);
    });
  });

  group('competenciaAtual', () {
    String em(String iso) => competenciaAtual(agora: () => DateTime.parse(iso));

    test('usa o mês de São Paulo quando UTC já virou o mês', () {
      // 01/nov 01:00 UTC = 31/out 22:00 em São Paulo (UTC-3)
      expect(em('2026-11-01T01:00:00Z'), '2026-10');
    });
    test('usa o mês de São Paulo quando UTC já virou o ano', () {
      expect(em('2027-01-01T02:59:59Z'), '2026-12');
    });
    test('vira o mês exatamente à meia-noite de São Paulo', () {
      expect(em('2026-11-01T03:00:00Z'), '2026-11');
    });
    test('meio do mês', () {
      expect(em('2026-10-15T12:00:00Z'), '2026-10');
    });
  });
}
