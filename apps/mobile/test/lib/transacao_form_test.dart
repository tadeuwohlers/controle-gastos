import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/lib/transacao_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const valido = EstadoForm(
    tipo: TipoTransacao.gasto,
    valor: '49,9',
    descricao: '  Supermercado ',
    competencia: '2026-10',
    contaId: 1,
    categoriaId: 2,
  );

  EstadoForm com({
    String? valor,
    String? descricao,
    String? competencia,
    Object? contaId = #sem,
    Object? categoriaId = #sem,
  }) => EstadoForm(
    tipo: valido.tipo,
    valor: valor ?? valido.valor,
    descricao: descricao ?? valido.descricao,
    competencia: competencia ?? valido.competencia,
    contaId: contaId == #sem ? valido.contaId : contaId as int?,
    categoriaId: categoriaId == #sem ? valido.categoriaId : categoriaId as int?,
  );

  group('validar', () {
    test('formulário completo vira payload com valor em string', () {
      final r = validar(valido);
      expect(r.ok, isTrue);
      expect(r.payload!.valor, '49.90');
      expect(r.payload!.descricao, 'Supermercado');
      expect(r.payload!.competencia, '2026-10');
      expect(r.payload!.contaId, 1);
      expect(r.payload!.categoriaId, 2);
      expect(r.payload!.tipo, TipoTransacao.gasto);
    });

    test('aponta cada campo inválido', () {
      final r = validar(
        com(
          valor: '0',
          descricao: '   ',
          competencia: '2026-13',
          contaId: null,
          categoriaId: null,
        ),
      );
      expect(r.ok, isFalse);
      expect(r.erros.keys, containsAll(CampoForm.values));
    });

    test('valor com mais de 2 casas é erro só no valor', () {
      final r = validar(com(valor: '1,234'));
      expect(r.erros.keys, [CampoForm.valor]);
    });
  });

  group('paraEntradaBR', () {
    test('devolve o valor da API ao formato do campo', () {
      expect(paraEntradaBR('49.90'), '49,90');
      expect(paraEntradaBR('1234.50'), '1234,50');
    });
    test('o resultado passa de volta por parseValorBR', () {
      expect(parseValorBR(paraEntradaBR('1234.50')), '1234.50');
    });
  });
}
