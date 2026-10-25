import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:flutter_test/flutter_test.dart';

import '../suporte/app_teste.dart';
import '../suporte/fake_repositorio.dart';

void main() {
  prepararTestes();

  testWidgets('sem API_URL mostra o erro de configuração', (tester) async {
    await abrirApp(tester, FakeRepositorio(), apiUrl: '');
    expect(find.text('API não configurada'), findsOneWidget);
  });

  testWidgets('mostra as 4 abas e o botão Nova transação', (tester) async {
    await abrirApp(tester, FakeRepositorio());
    for (final rotulo in [
      'Resumo',
      'Transações',
      'Parcelamentos',
      'Cadastros',
    ]) {
      expect(find.text(rotulo), findsOneWidget);
    }
    expect(find.text('Nova transação'), findsOneWidget);
    expect(find.text('Balanço Mensal'), findsOneWidget);
  });

  testWidgets('navega entre abas; Cadastros e Parcelamentos sem seletor', (
    tester,
  ) async {
    await abrirApp(tester, FakeRepositorio());
    expect(find.byTooltip('Competência anterior'), findsOneWidget);

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma transação neste mês.'), findsOneWidget);
    expect(find.byTooltip('Competência anterior'), findsOneWidget);

    await tester.tap(find.text('Parcelamentos'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Competência anterior'), findsNothing);

    await tester.tap(find.text('Cadastros'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Competência anterior'), findsNothing);
  });

  testWidgets('seletor desloca a Competência e "Hoje" volta ao mês corrente', (
    tester,
  ) async {
    await abrirApp(tester, FakeRepositorio());
    final atual = comp.competenciaAtual();
    expect(find.text(comp.formatar(atual)), findsOneWidget);
    expect(find.text('Hoje'), findsNothing);

    await tester.tap(find.byTooltip('Competência anterior'));
    await tester.pumpAndSettle();
    expect(find.text(comp.formatar(comp.deslocar(atual, -1))), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();
    expect(find.text(comp.formatar(atual)), findsOneWidget);
    expect(find.text('Hoje'), findsNothing);
  });

  testWidgets('a Competência é compartilhada entre Resumo e Transações', (
    tester,
  ) async {
    await abrirApp(tester, FakeRepositorio());
    await tester.tap(find.byTooltip('Próxima competência'));
    await tester.pumpAndSettle();
    final proximo = comp.formatar(comp.deslocar(comp.competenciaAtual(), 1));

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();
    expect(find.text(proximo), findsOneWidget);
  });

  testWidgets('o botão abre o sheet de Nova transação', (tester) async {
    await abrirApp(tester, FakeRepositorio());
    await tester.tap(find.text('Nova transação'));
    await tester.pumpAndSettle();
    expect(find.text('Salvar'), findsOneWidget);
    expect(find.text('Salvar e nova'), findsOneWidget);
  });
}
