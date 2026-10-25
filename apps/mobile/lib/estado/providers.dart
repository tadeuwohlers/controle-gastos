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
