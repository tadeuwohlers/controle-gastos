import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../suporte/app_teste.dart';
import '../suporte/dados_teste.dart';
import '../suporte/fake_repositorio.dart';

Future<void> abrirSheet(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> escolher(WidgetTester tester, String campo, String opcao) async {
  await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, campo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcao).last);
  await tester.pumpAndSettle();
}

Future<void> digitar(WidgetTester tester, String campo, String texto) async {
  await tester.enterText(find.widgetWithText(TextField, campo), texto);
  await tester.pump();
}

Future<void> tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> preencherGasto(WidgetTester tester) async {
  await escolher(tester, 'Conta', 'Nubank');
  await escolher(tester, 'Categoria', 'Alimentação');
  await digitar(tester, 'Valor', '49,9');
  await digitar(tester, 'Descrição', 'Supermercado');
}

void main() {
  prepararTestes();

  testWidgets('o tipo filtra as Categorias', (tester) async {
    await abrirApp(tester, repoComDados());
    await abrirSheet(tester);

    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<int>, 'Categoria'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Salário'), findsNothing);
    await tester.tap(find.text('Transporte'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<int>, 'Categoria'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Salário'), findsOneWidget);
    expect(find.text('Alimentação'), findsNothing);
    expect(find.text('Transporte'), findsNothing);
  });

  testWidgets('valida no cliente antes de enviar', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await abrirSheet(tester);

    await tocar(tester, find.text('Salvar'));

    expect(
      find.text('Informe um valor maior que zero, com até 2 casas decimais.'),
      findsOneWidget,
    );
    expect(find.text('Informe a descrição.'), findsOneWidget);
    expect(find.text('Escolha a Conta.'), findsOneWidget);
    expect(find.text('Escolha a Categoria.'), findsOneWidget);
    expect(repo.chamadas, isEmpty);
  });

  testWidgets('Salvar envia o valor em string e fecha o sheet', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await abrirSheet(tester);
    await preencherGasto(tester);

    await tocar(tester, find.text('Salvar'));

    expect(repo.chamadas, [
      'criarTransacao(gasto, 49.90, Supermercado, $mesAtual, 1, 10)',
    ]);
    expect(find.text('Salvar e nova'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('ultima_conta_id'), 1);
  });

  testWidgets('a lista de Transações já mostra o lançamento novo', (
    tester,
  ) async {
    await abrirApp(tester, repoComDados());
    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();
    await abrirSheet(tester);
    await preencherGasto(tester);
    await tocar(tester, find.text('Salvar'));

    expect(find.text('Supermercado'), findsNWidgets(2));
  });

  testWidgets('Salvar e nova mantém tipo, Conta e Competência', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await abrirSheet(tester);

    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Competência seguinte'));
    await tester.pump();
    await escolher(tester, 'Conta', 'Itaú');
    await escolher(tester, 'Categoria', 'Salário');
    await digitar(tester, 'Valor', '5000');
    await digitar(tester, 'Descrição', 'Salário');

    await tocar(tester, find.text('Salvar e nova'));

    final proxima = comp.deslocar(mesAtual, 1);
    expect(repo.chamadas, [
      'criarTransacao(receita, 5000.00, Salário, $proxima, 2, 20)',
    ]);
    // O formulário continua aberto, com valor e descrição limpos.
    expect(find.text('Salvar e nova'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Valor'))
          .controller!
          .text,
      '',
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Descrição'))
          .controller!
          .text,
      '',
    );
    expect(
      tester
          .widget<SegmentedButton<TipoTransacao>>(
            find.byType(SegmentedButton<TipoTransacao>),
          )
          .selected,
      {TipoTransacao.receita},
    );
    expect(find.text(comp.formatar(proxima)), findsWidgets);
    expect(
      find.descendant(
        of: find.widgetWithText(DropdownButtonFormField<int>, 'Conta'),
        matching: find.text('Itaú'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('erro 422 da API aparece inline e mantém o digitado', (
    tester,
  ) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await abrirSheet(tester);
    await preencherGasto(tester);
    repo.falharProxima = FakeRepositorio.erro(
      422,
      'valor deve ser maior que zero.',
    );

    await tocar(tester, find.text('Salvar'));

    expect(find.text('valor deve ser maior que zero.'), findsOneWidget);
    expect(find.widgetWithText(TextField, '49,9'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Supermercado'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
  });

  testWidgets(
    'falha de rede mostra "Tentar de novo" e reenvia o mesmo payload',
    (tester) async {
      final repo = repoComDados();
      await abrirApp(tester, repo);
      await abrirSheet(tester);
      await preencherGasto(tester);
      repo.falharProxima = FakeRepositorio.semRede();

      await tocar(tester, find.text('Salvar'));
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(repo.chamadas, isEmpty);

      await tocar(tester, find.text('Tentar de novo'));
      expect(repo.chamadas, [
        'criarTransacao(gasto, 49.90, Supermercado, $mesAtual, 1, 10)',
      ]);
      expect(find.text('Salvar e nova'), findsNothing);
    },
  );

  testWidgets('banco vazio: cria Conta e Categoria sem sair do formulário', (
    tester,
  ) async {
    final repo = FakeRepositorio();
    await abrirApp(tester, repo);
    await abrirSheet(tester);

    expect(find.text('Criar conta'), findsOneWidget);
    expect(find.text('Criar categoria'), findsOneWidget);

    await digitar(tester, 'Nova Conta', 'Nubank');
    await tocar(tester, find.text('Criar conta'));
    expect(
      find.widgetWithText(DropdownButtonFormField<int>, 'Conta'),
      findsOneWidget,
    );
    expect(find.text('Criar conta'), findsNothing);

    await digitar(tester, 'Nova Categoria', 'Mercado');
    await tocar(tester, find.text('Criar categoria'));
    expect(
      find.widgetWithText(DropdownButtonFormField<int>, 'Categoria'),
      findsOneWidget,
    );

    await digitar(tester, 'Valor', '10');
    await digitar(tester, 'Descrição', 'Pão');
    await tocar(tester, find.text('Salvar'));

    expect(repo.chamadas, [
      'criarConta(Nubank)',
      'criarCategoria(Mercado, gasto)',
      'criarTransacao(gasto, 10.00, Pão, $mesAtual, 1000, 1001)',
    ]);
  });

  testWidgets('criação inline mostra o erro 409 da API', (tester) async {
    final repo = FakeRepositorio(contas: const [nubank]);
    await abrirApp(tester, repo);
    await abrirSheet(tester);

    await digitar(tester, 'Nova Categoria', 'Mercado');
    repo.falharProxima = FakeRepositorio.erro(409, 'Categoria já existe.');
    await tocar(tester, find.text('Criar categoria'));

    expect(find.text('Categoria já existe.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Mercado'), findsOneWidget);
  });

  testWidgets('a última Conta usada vem pré-selecionada', (tester) async {
    SharedPreferences.setMockInitialValues({'ultima_conta_id': 2});
    await abrirApp(tester, repoComDados());
    await abrirSheet(tester);

    expect(
      find.descendant(
        of: find.widgetWithText(DropdownButtonFormField<int>, 'Conta'),
        matching: find.text('Itaú'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('última Conta que não existe mais é ignorada', (tester) async {
    SharedPreferences.setMockInitialValues({'ultima_conta_id': 99});
    await abrirApp(tester, repoComDados());
    await abrirSheet(tester);

    expect(
      find.descendant(
        of: find.widgetWithText(DropdownButtonFormField<int>, 'Conta'),
        matching: find.text('Itaú'),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'Competência do sheet segue a selecionada nas telas com seletor',
    (tester) async {
      await abrirApp(tester, repoComDados());
      await tester.tap(find.byTooltip('Competência anterior'));
      await tester.pumpAndSettle();
      await abrirSheet(tester);

      final anterior = comp.deslocar(mesAtual, -1);
      expect(find.text(comp.formatar(anterior)), findsWidgets);

      await tester.tap(find.byType(FloatingActionButton), warnIfMissed: false);
    },
  );

  testWidgets('em Cadastros a Competência do sheet é a corrente', (
    tester,
  ) async {
    await abrirApp(tester, repoComDados());
    await tester.tap(find.byTooltip('Competência anterior'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastros'));
    await tester.pumpAndSettle();
    await abrirSheet(tester);

    expect(
      find.descendant(
        of: find.byType(InputDecorator).first,
        matching: find.text(comp.formatar(mesAtual)),
      ),
      findsNothing,
    );
    expect(find.text(comp.formatar(mesAtual)), findsOneWidget);
  });

  testWidgets('editar: tipo fixo, sem "Salvar e nova", envia PUT', (
    tester,
  ) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supermercado'));
    await tester.pumpAndSettle();

    expect(find.text('Editar transação'), findsOneWidget);
    expect(find.text('Tipo: Gasto'), findsOneWidget);
    expect(find.text('Salvar e nova'), findsNothing);
    expect(find.widgetWithText(TextField, '49,90'), findsOneWidget);

    await digitar(tester, 'Descrição', 'Mercado do bairro');
    await tocar(tester, find.text('Salvar'));

    expect(repo.chamadas, [
      'atualizarTransacao(1, 49.90, Mercado do bairro, $mesAtual, 1, 10)',
    ]);
    expect(find.text('Mercado do bairro'), findsOneWidget);
  });
}
