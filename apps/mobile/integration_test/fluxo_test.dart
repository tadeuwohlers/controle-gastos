// Fluxo único da spec 003, do banco vazio ao cancelamento de um Parcelamento,
// contra a API real e o banco `controle_gastos_test` (recriado pelo
// `make e2e-mobile`). Exige banco vazio e `--dart-define=API_URL=...`.
import 'package:controle_gastos/app.dart';
import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;

/// Com rede de verdade, `pumpAndSettle` volta antes da resposta chegar; este
/// espera o widget aparecer, bombeando quadros.
Future<void> aguardar(
  WidgetTester tester,
  Finder f, {
  Duration limite = const Duration(seconds: 15),
}) async {
  final fim = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fim)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (f.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  expect(f, findsWidgets, reason: 'não apareceu em ${limite.inSeconds}s');
}

/// Fecha o teclado (no iOS e no Android ele muda o layout do sheet) antes de
/// tocar, como o usuário faria.
Future<void> fecharTeclado(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, Finder f) async {
  await fecharTeclado(tester);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> digitar(WidgetTester tester, String campo, String texto) async {
  final f = find.widgetWithText(TextField, campo);
  await tester.ensureVisible(f);
  await tester.enterText(f, texto);
  await tester.pump();
}

Future<void> escolher(WidgetTester tester, String campo, String opcao) async {
  final dropdown = find.widgetWithText(DropdownButtonFormField<int>, campo);
  await fecharTeclado(tester);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcao).last);
  await tester.pumpAndSettle();
}

Future<void> abrirSheet(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  expect(find.text('Nova transação'), findsWidgets);
}

Future<void> irPara(WidgetTester tester, String aba) async {
  await tester.tap(find.text(aba));
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  final mes = comp.competenciaAtual();

  testWidgets('do banco vazio ao cancelamento de um Parcelamento', (
    tester,
  ) async {
    const url = String.fromEnvironment('API_URL');
    expect(url, isNotEmpty, reason: 'rode com --dart-define=API_URL=...');
    await binding.setSurfaceSize(null);

    await tester.pumpWidget(
      const ProviderScope(retry: semRetentativa, child: App()),
    );
    await aguardar(tester, find.text('Balanço Mensal'));
    await aguardar(tester, find.text('Nenhum gasto neste mês.'));
    await irPara(tester, 'Transações');
    await aguardar(tester, find.text('Nenhuma transação neste mês.'));

    // 1. Conta e Categoria de Gasto criadas no formulário + um Gasto.
    await abrirSheet(tester);
    await digitar(tester, 'Nova Conta', 'Nubank');
    await tocar(tester, find.text('Criar conta'));
    await aguardar(
      tester,
      find.widgetWithText(DropdownButtonFormField<int>, 'Conta'),
    );
    await digitar(tester, 'Nova Categoria', 'Alimentação');
    await tocar(tester, find.text('Criar categoria'));
    await aguardar(
      tester,
      find.widgetWithText(DropdownButtonFormField<int>, 'Categoria'),
    );
    await digitar(tester, 'Valor', '50,00');
    await digitar(tester, 'Descrição', 'Mercado');
    await tocar(tester, find.text('Salvar'));
    await aguardar(tester, find.text('Mercado'));
    expect(find.text('− ${formatBRL('50.00')}'), findsOneWidget);

    // 2. Categoria de Receita criada no formulário + uma Receita.
    await abrirSheet(tester);
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await digitar(tester, 'Nova Categoria', 'Salário');
    await tocar(tester, find.text('Criar categoria'));
    await aguardar(
      tester,
      find.widgetWithText(DropdownButtonFormField<int>, 'Categoria'),
    );
    await digitar(tester, 'Valor', '1.000,00');
    await digitar(tester, 'Descrição', 'Salário do mês');
    await tocar(tester, find.text('Salvar'));
    await aguardar(tester, find.text('Salário do mês'));
    expect(find.text('+ ${formatBRL('1000.00')}'), findsOneWidget);

    // 3. Parcelamento de R$ 100,00 em 3×, primeira parcela no mês corrente.
    await abrirSheet(tester);
    await tester.tap(find.text('Parcelado'));
    await tester.pumpAndSettle();
    await escolher(tester, 'Categoria', 'Alimentação');
    await digitar(tester, 'Valor total', '100,00');
    await digitar(tester, 'Descrição', 'Fone de ouvido');
    await digitar(tester, 'Número de parcelas', '3');
    expect(find.text(comp.formatar(mes)), findsWidgets);
    await tocar(tester, find.text('Salvar'));

    // O app abre o detalhe; a última Parcela absorve o centavo.
    await aguardar(tester, find.text('Parcelas'));
    expect(find.text('Fone de ouvido'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text(formatBRL('33.33')), findsNWidgets(2));
    expect(find.text(formatBRL('33.34')), findsOneWidget);

    // 4. Resumo do mês corrente.
    await irPara(tester, 'Resumo');
    await aguardar(tester, find.text('Gastos por Categoria'));
    await aguardar(tester, find.text(formatBRL('83.33')));
    expect(find.text(formatBRL('1000.00')), findsOneWidget); // Receitas
    expect(find.text('▲ ${formatBRL('916.67')}'), findsOneWidget); // Saldo
    expect(find.text('Superávit'), findsOneWidget);
    // Gastos = R$ 83,33 (50,00 + a 1ª Parcela de 33,33), tudo em Alimentação:
    // aparece no cartão de Gastos e na linha da Categoria.
    expect(find.text(formatBRL('83.33')), findsNWidgets(2));
    expect(find.text('Alimentação'), findsOneWidget);

    // 5. Cancelamento: a 1ª Parcela fica, as demais somem.
    await irPara(tester, 'Parcelamentos');
    await aguardar(tester, find.text('Fone de ouvido'));
    await tester.tap(find.text('Fone de ouvido'));
    await tester.pumpAndSettle();
    await aguardar(tester, find.text('Cancelar parcelamento'));
    await tocar(tester, find.text('Cancelar parcelamento'));
    expect(
      find.text(
        'Remove 2 parcelas futuras; 1 (a do mês atual e as passadas) '
        'permanecem.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(FilledButton, 'Cancelar parcelamento'),
    );
    await tester.pumpAndSettle();
    await aguardar(
      tester,
      find.text(
        'Parcelamento cancelado. 2 parcelas futuras removidas; 1 preservada.',
      ),
    );
    expect(find.text('Cancelado'), findsOneWidget);
    expect(find.text('Cancelar parcelamento'), findsNothing);

    // O mês corrente mantém a 1ª Parcela; os seguintes ficam vazios.
    await irPara(tester, 'Transações');
    // A API nomeia cada Parcela como "<descrição> n/N".
    await aguardar(tester, find.textContaining('Fone de ouvido'));
    expect(find.text('Fone de ouvido 1/3'), findsOneWidget);
    expect(find.text('Fone de ouvido 2/3'), findsNothing);
    expect(find.text('− ${formatBRL('33.33')}'), findsOneWidget);
    await tester.tap(find.byTooltip('Próxima competência'));
    await tester.pumpAndSettle();
    await aguardar(tester, find.text('Nenhuma transação neste mês.'));
    await tester.tap(find.byTooltip('Próxima competência'));
    await tester.pumpAndSettle();
    await aguardar(tester, find.text('Nenhuma transação neste mês.'));
  });
}
