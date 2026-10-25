import 'dart:async';
import 'dart:convert';

import 'package:controle_gastos/lib/erros.dart';
import 'package:http/http.dart' as http;

/// Falha de uma chamada à API: resposta de erro (com [status]) ou falha de
/// rede/timeout (sem [status]).
class ApiException implements Exception {
  ApiException({this.status, this.corpo, this.causa});

  final int? status;

  /// Corpo JSON já decodificado, quando houve resposta.
  final Object? corpo;
  final Object? causa;

  /// Sem resposta do servidor (rede, timeout) ou erro 5xx: vale "Tentar de novo".
  bool get ehRedeOu5xx => status == null || status! >= 500;

  String get mensagem => extrairMensagem(corpo);

  @override
  String toString() => 'ApiException($status, $corpo, $causa)';
}

class ApiClient {
  ApiClient(
    this.baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      _enviar('GET', path, query: query);

  Future<Object?> post(String path, {Object? body}) =>
      _enviar('POST', path, body: body);

  Future<Object?> put(String path, {Object? body}) =>
      _enviar('PUT', path, body: body);

  Future<Object?> delete(String path) => _enviar('DELETE', path);

  Future<Object?> _enviar(
    String metodo,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final base = Uri.parse(baseUrl);
    final uri = base.replace(
      path: path,
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final request = http.Request(metodo, uri)
      ..headers['accept'] = 'application/json';
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response resposta;
    try {
      resposta = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
    } on Exception catch (e) {
      throw ApiException(causa: e);
    }

    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);
    Object? corpo;
    if (texto.isNotEmpty) {
      try {
        corpo = jsonDecode(texto);
      } on FormatException {
        corpo = null;
      }
    }
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return corpo;
    throw ApiException(status: resposta.statusCode, corpo: corpo);
  }
}
