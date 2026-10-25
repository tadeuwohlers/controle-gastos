import 'package:controle_gastos/app.dart';
import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'fake_repositorio.dart';

/// Competência corrente, usada nos dados de teste (o app abre nela).
String get mesAtual => comp.competenciaAtual();

void prepararTestes() {
  setUpAll(tzdata.initializeTimeZones);
  setUp(() => SharedPreferences.setMockInitialValues({}));
}

/// Abre o app inteiro com o [repo] falso, numa tela de celular.
Future<void> abrirApp(
  WidgetTester tester,
  FakeRepositorio repo, {
  String apiUrl = 'http://api.test',
}) async {
  tester.view
    ..physicalSize = const Size(1200, 3000)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: semRetentativa,
      overrides: [
        apiUrlProvider.overrideWithValue(apiUrl),
        repositorioProvider.overrideWithValue(repo),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}
