import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/roteador.dart';
import 'package:controle_gastos/telas/config_erro_tela.dart';

const _semente = Color(0xFF1B7F5C);

ThemeData _tema(Brightness brilho) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _semente, brightness: brilho),
);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const localizacao = [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    const locale = Locale('pt', 'BR');
    final tema = _tema(Brightness.light);
    final temaEscuro = _tema(Brightness.dark);

    if (ref.watch(apiUrlProvider).isEmpty) {
      return MaterialApp(
        title: 'Controle de Gastos',
        theme: tema,
        darkTheme: temaEscuro,
        locale: locale,
        supportedLocales: const [locale],
        localizationsDelegates: localizacao,
        home: const ConfigErroTela(),
      );
    }

    return MaterialApp.router(
      title: 'Controle de Gastos',
      theme: tema,
      darkTheme: temaEscuro,
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: const [locale],
      localizationsDelegates: localizacao,
      routerConfig: ref.watch(roteadorProvider),
    );
  }
}
