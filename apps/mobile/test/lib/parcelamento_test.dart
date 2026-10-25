import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/lib/parcelamento.dart';
import 'package:controle_gastos/lib/transacao_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = EstadoForm(
    tipo: TipoTransacao.gasto,
    valor: '3.600,00',
    descricao: '  Notebook ',
    competencia: '2026-10',
    contaId: 1,
    categoriaId: 2,
  );

  group('validarParcelado', () {
    test('formulário completo vira payload com valor total em string', () {
      final r = validarParcelado(base, '12');
      expect(r.ok, isTrue);
      final p = r.payload!;
      expect(p.valorTotal, '3600.00');
      expect(p.numParcelas, 12);
      expect(p.primeiraParcela, '2026-10');
      expect(p.descricao, 'Notebook');
      expect(p.contaId, 1);
      expect(p.categoriaId, 2);
    });

    for (final n in ['', '1', '0', 'abc', '2,5', '-3', '12345']) {
      test('número de parcelas "$n" é erro', () {
        final r = validarParcelado(base, n);
        expect(r.erros.keys, [CampoForm.numParcelas]);
      });
    }

    test('2 parcelas é o mínimo aceito', () {
      expect(validarParcelado(base, '2').ok, isTrue);
    });

    test('espaços em volta do número são ignorados', () {
      expect(validarParcelado(base, ' 6 ').payload!.numParcelas, 6);
    });

    test('aponta cada campo inválido', () {
      final r = validarParcelado(
        const EstadoForm(
          tipo: TipoTransacao.gasto,
          valor: '0',
          descricao: ' ',
          competencia: '2026-13',
        ),
        '1',
      );
      expect(r.erros.keys, containsAll(CampoForm.values));
    });
  });

  group('previaCancelamento', () {
    const competencias = ['2026-09', '2026-10', '2026-11', '2026-12'];

    test('remove as futuras e preserva a do mês atual e as passadas', () {
      final p = previaCancelamento(competencias, atual: '2026-10');
      expect(p.removidas, 2);
      expect(p.preservadas, 2);
    });

    test('sem parcelas futuras nada é removido', () {
      final p = previaCancelamento(competencias, atual: '2026-12');
      expect(p.removidas, 0);
      expect(p.preservadas, 4);
    });

    test('todas futuras: remove tudo', () {
      final p = previaCancelamento(competencias, atual: '2026-08');
      expect(p.removidas, 4);
      expect(p.preservadas, 0);
    });

    test('vira o ano', () {
      final p = previaCancelamento(['2026-12', '2027-01'], atual: '2026-12');
      expect(p.removidas, 1);
      expect(p.preservadas, 1);
    });
  });

  group('plural', () {
    test('singular e plural', () {
      expect(plural(1, 'parcela', 'parcelas'), '1 parcela');
      expect(plural(2, 'parcela', 'parcelas'), '2 parcelas');
      expect(plural(0, 'parcela', 'parcelas'), '0 parcelas');
    });
  });
}
