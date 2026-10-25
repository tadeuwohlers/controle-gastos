import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/app_teste.dart';
import '../suporte/dados_teste.dart';
import '../suporte/fake_repositorio.dart';

Future<void> irParaCadastros(WidgetTester tester) async {
  await tester.tap(find.text('Cadastros'));
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  prepararTestes();

  testWidgets('lista Contas e Categorias agrupadas por tipo', (tester) async {
    await abrirApp(tester, repoComDados());
    await irParaCadastros(tester);

    expect(find.text('Contas'), findsOneWidget);
    expect(find.text('Nubank'), findsOneWidget);
    expect(find.text('Itaú'), findsOneWidget);
    expect(find.text('Categorias de Gasto'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    expect(find.text('Categorias de Receita'), findsOneWidget);
    expect(find.text('Salário'), findsOneWidget);
  });

  testWidgets('banco vazio explica para que servem', (tester) async {
    await abrirApp(tester, FakeRepositorio());
    await irParaCadastros(tester);

    expect(find.textContaining('Nenhuma Conta ainda'), findsOneWidget);
    expect(find.text('Nenhuma Categoria de Gasto ainda.'), findsOneWidget);
    expect(find.text('Nenhuma Categoria de Receita ainda.'), findsOneWidget);
  });

  testWidgets('cria uma Conta e ela aparece na lista', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await irParaCadastros(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nova Conta'),
      'Inter',
    );
    await tocar(tester, find.text('Adicionar Conta'));

    expect(repo.chamadas, ['criarConta(Inter)']);
    expect(find.text('Inter'), findsOneWidget);
  });

  testWidgets('409 da API aparece inline', (tester) async {
    await abrirApp(tester, repoComDados());
    await irParaCadastros(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nova Conta'),
      'Nubank',
    );
    await tocar(tester, find.text('Adicionar Conta'));

    expect(find.text('Conta já existe.'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Nubank'), findsOneWidget);
  });

  testWidgets('cria Categoria de Receita', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await irParaCadastros(tester);

    await tocar(tester, find.text('Receita'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Nova Categoria'),
      'Freela',
    );
    await tocar(tester, find.text('Adicionar Categoria'));

    expect(repo.chamadas, ['criarCategoria(Freela, receita)']);
    expect(find.text('Freela'), findsOneWidget);
  });

  testWidgets('nome vazio não chama a API', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await irParaCadastros(tester);

    await tocar(tester, find.text('Adicionar Conta'));

    expect(find.text('Informe o nome.'), findsOneWidget);
    expect(repo.chamadas, isEmpty);
  });

  testWidgets('falha de rede ao criar mostra "Tentar de novo"', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await irParaCadastros(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nova Conta'),
      'Inter',
    );
    repo.falharProxima = FakeRepositorio.semRede();
    await tocar(tester, find.text('Adicionar Conta'));
    expect(find.text('Tentar de novo'), findsOneWidget);

    await tocar(tester, find.text('Tentar de novo'));
    expect(repo.chamadas, ['criarConta(Inter)']);
    expect(find.text('Inter'), findsOneWidget);
  });
}
