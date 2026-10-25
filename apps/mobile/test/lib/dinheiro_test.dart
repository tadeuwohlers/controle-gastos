import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseValorBR', () {
    const validos = {
      '1.234,56': '1234.56',
      '49,9': '49.90',
      '49': '49.00',
      '0,50': '0.50',
      ' 10,00 ': '10.00',
      '9999999999,99': '9999999999.99',
    };
    validos.forEach((entrada, esperado) {
      test('converte "$entrada" em "$esperado"', () {
        expect(parseValorBR(entrada), esperado);
      });
    });

    const invalidos = [
      '0,00',
      '0',
      '-5',
      '1,234',
      '12345678901',
      '',
      '   ',
      'abc',
      '1,2,3',
      '12a',
      ',',
    ];
    for (final entrada in invalidos) {
      test('rejeita "$entrada"', () {
        expect(parseValorBR(entrada), isNull);
      });
    }
  });

  group('formatBRL', () {
    String norm(String s) => s.replaceAll(' ', ' ');

    test('formata positivo com milhar', () {
      expect(norm(formatBRL('1234.56')), 'R\$ 1.234,56');
    });
    test('formata milhões', () {
      expect(norm(formatBRL('1234567.80')), 'R\$ 1.234.567,80');
    });
    test('formata negativo com sinal na frente', () {
      expect(norm(formatBRL('-100.00')), '-R\$ 100,00');
    });
    test('formata zero', () {
      expect(norm(formatBRL('0.00')), 'R\$ 0,00');
    });
    test('formata sem parte inteira', () {
      expect(norm(formatBRL('0.05')), 'R\$ 0,05');
    });
    test('completa casas decimais ausentes', () {
      expect(norm(formatBRL('12')), 'R\$ 12,00');
      expect(norm(formatBRL('12.5')), 'R\$ 12,50');
    });
  });

  group('sinal', () {
    test('positivo', () => expect(sinal('10.00'), Sinal.positivo));
    test('negativo', () => expect(sinal('-0.01'), Sinal.negativo));
    test('zero', () {
      expect(sinal('0.00'), Sinal.zero);
      expect(sinal('0'), Sinal.zero);
      expect(sinal('-0.00'), Sinal.zero);
    });
  });
}
