import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/api/repositorio.dart';
import 'package:controle_gastos/config.dart' as config;

/// URL da API do build; os testes a substituem.
final apiUrlProvider = Provider<String>((ref) => config.apiUrl);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(apiUrlProvider)),
);

final repositorioProvider = Provider<Repositorio>(
  (ref) => Repositorio(ref.watch(apiClientProvider)),
);

/// O Riverpod 3 repete leituras que falham, em silêncio e por vários minutos.
/// Aqui a falha precisa aparecer na hora, com "Tentar de novo" (spec 003).
Duration? semRetentativa(int tentativa, Object erro) => null;
