import 'package:controle_gastos/lib/erros.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const padrao = 'Algo deu errado. Tente de novo.';

  group('extrairMensagem', () {
    test('devolve detail string', () {
      expect(
        extrairMensagem({'detail': 'Parcelamento já cancelado.'}),
        'Parcelamento já cancelado.',
      );
    });

    test('junta msgs de lista e remove prefixo Value error', () {
      expect(
        extrairMensagem({
          'detail': [
            {
              'loc': ['body', 'valor'],
              'msg': 'Value error, valor deve ser positivo',
            },
            {
              'loc': ['body', 'descricao'],
              'msg': 'Field required',
            },
          ],
        }),
        'valor deve ser positivo\nField required',
      );
    });

    final inesperados = <Object?>[
      null,
      'x',
      42,
      <String, Object?>{},
      {'detail': 1},
      {'detail': <Object?>[]},
      {
        'detail': [<String, Object?>{}],
      },
    ];
    for (final corpo in inesperados) {
      test('cai no padrão para $corpo', () {
        expect(extrairMensagem(corpo), padrao);
      });
    }
  });
}
