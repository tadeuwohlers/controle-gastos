import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'contrato.dart';

Json _carregar() {
  final arquivo = File('../api/openapi.json');
  if (!arquivo.existsSync()) {
    fail(
      'apps/api/openapi.json não existe. Rode `make test-mobile` na raiz '
      '(ele gera o arquivo antes dos testes e o apaga depois).',
    );
  }
  return jsonDecode(arquivo.readAsStringSync()) as Json;
}

void main() {
  group('detector de divergência (sem depender da API)', () {
    Json minimo() => jsonDecode(
      jsonEncode({
        'paths': {
          for (final path in usos.map((u) => u.path).toSet())
            path: {
              for (final u in usos.where((u) => u.path == path))
                u.metodo: {
                  'parameters': [
                    for (final q in u.query) {'name': q},
                  ],
                },
            },
        },
        'components': {
          'schemas': {
            for (final e in enums.entries) e.key: {'enum': e.value},
            for (final e in camposLidos.entries)
              e.key: {
                'properties': {for (final c in e.value) c: {}},
                'required': e.value,
              },
            for (final e in camposEnviados.entries)
              e.key: {
                'properties': {for (final c in e.value) c: {}},
                'required': e.value,
              },
          },
        },
      }),
    ) as Json;

    test('contrato respeitado não gera problemas', () {
      // Os schemas de resposta sem campos lidos (ex.: ParcelamentoReadComParcelas
      // já tem `parcelas`) existem no mínimo; os de corpo também.
      expect(verificar(minimo()), isEmpty);
    });

    test('campo lido que some é apontado', () {
      final api = minimo();
      final props =
          ((api['components'] as Json)['schemas']
                  as Json)['BalancoMensal']['properties']
              as Json;
      props.remove('saldo');
      expect(
        verificar(api),
        contains('BalancoMensal: campo lido "saldo" não existe'),
      );
    });

    test('endpoint removido é apontado', () {
      final api = minimo();
      (api['paths'] as Json).remove('/api/v1/relatorios/parcelas-ativas');
      expect(
        verificar(api),
        contains('GET /api/v1/relatorios/parcelas-ativas: endpoint não existe'),
      );
    });

    test('novo campo obrigatório no corpo é apontado', () {
      final api = minimo();
      ((api['components'] as Json)['schemas']
              as Json)['ContaCreate']['required']
          .add('cor');
      expect(
        verificar(api),
        contains('ContaCreate: campo obrigatório "cor" não é enviado'),
      );
    });

    test('valor novo de enum é apontado', () {
      final api = minimo();
      ((api['components'] as Json)['schemas'] as Json)['StatusEnum']['enum']
          .add('pausado');
      expect(
        verificar(api),
        contains('StatusEnum: valor novo "pausado" não tratado'),
      );
    });
  });

  test('o app respeita o openapi.json atual da API', () {
    expect(verificar(_carregar()), isEmpty);
  });
}
