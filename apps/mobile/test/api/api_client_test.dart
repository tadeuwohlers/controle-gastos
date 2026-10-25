import 'dart:async';
import 'dart:convert';

import 'package:controle_gastos/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  ApiClient clienteCom(MockClientHandler h, {Duration? timeout}) => ApiClient(
    'http://api.test:8000',
    client: MockClient(h),
    timeout: timeout ?? const Duration(seconds: 1),
  );

  test('monta a URL com query e decodifica o JSON em UTF-8', () async {
    late Uri chamada;
    final api = clienteCom((req) async {
      chamada = req.url;
      return http.Response.bytes(
        utf8.encode('[{"nome":"Alimentação"}]'),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final corpo = await api.get(
      '/api/v1/transacoes',
      query: {'competencia': '2026-10'},
    );
    expect(
      chamada.toString(),
      'http://api.test:8000/api/v1/transacoes?competencia=2026-10',
    );
    expect(corpo, [
      {'nome': 'Alimentação'},
    ]);
  });

  test('envia o corpo como JSON, com valor como string', () async {
    late http.Request enviada;
    final api = clienteCom((req) async {
      enviada = req;
      return http.Response('{"id":1}', 201);
    });
    await api.post('/api/v1/transacoes', body: {'valor': '49.90'});
    expect(enviada.method, 'POST');
    expect(enviada.headers['content-type'], contains('application/json'));
    expect(enviada.body, '{"valor":"49.90"}');
  });

  test('204 sem corpo devolve null', () async {
    final api = clienteCom((_) async => http.Response('', 204));
    expect(await api.delete('/api/v1/transacoes/1'), isNull);
  });

  test('erro de negócio vira ApiException com status e mensagem', () async {
    final api = clienteCom(
      (_) async => http.Response.bytes(
        utf8.encode('{"detail":"Conta não encontrada."}'),
        404,
      ),
    );
    await expectLater(
      api.get('/api/v1/contas'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 404)
            .having((e) => e.mensagem, 'mensagem', 'Conta não encontrada.')
            .having((e) => e.ehRedeOu5xx, 'ehRedeOu5xx', isFalse),
      ),
    );
  });

  test(
    '5xx com corpo inválido é erro de servidor, não quebra o parse',
    () async {
      final api = clienteCom((_) async => http.Response('<html>', 502));
      await expectLater(
        api.get('/api/v1/contas'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.ehRedeOu5xx, 'ehRedeOu5xx', isTrue)
              .having(
                (e) => e.mensagem,
                'mensagem',
                'Algo deu errado. Tente de novo.',
              ),
        ),
      );
    },
  );

  test('falha de rede vira ApiException sem status', () async {
    final api = clienteCom((_) async => throw http.ClientException('sem rede'));
    await expectLater(
      api.get('/api/v1/contas'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', isNull)
            .having((e) => e.ehRedeOu5xx, 'ehRedeOu5xx', isTrue),
      ),
    );
  });

  test('timeout vira falha de rede', () async {
    final api = clienteCom(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 50),
    );
    await expectLater(
      api.get('/api/v1/contas'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', isNull)),
    );
  });
}
