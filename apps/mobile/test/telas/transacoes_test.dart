import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/app_teste.dart';
import '../suporte/dados_teste.dart';
import '../suporte/fake_repositorio.dart';

Future<void> irParaTransacoes(WidgetTester tester) async {
  await tester.tap(find.text('Transações'));
  await tester.pumpAndSettle();
}

void main() {
  prepararTestes();

  testWidgets('lista a Competência com valor, categoria, conta e selo n/N', (
    tester,
  ) async {
    await abrirApp(tester, repoComDados());
    await irParaTransacoes(tester);

    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('Alimentação • Nubank'), findsOneWidget);
    expect(find.text('− ${formatBRL('49.90')}'), findsOneWidget);
    expect(find.text('+ ${formatBRL('5000.00')}'), findsOneWidget);
    expect(find.text('2/12'), findsOneWidget);
  });

  testWidgets('filtro de tipo é aplicado no cliente', (tester) async {
    await abrirApp(tester, repoComDados());
    await irParaTransacoes(tester);

    await tester.tap(find.text('Gastos'));
    await tester.pumpAndSettle();
    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('Salário de outubro'), findsNothing);

    await tester.tap(find.text('Receitas'));
    await tester.pumpAndSettle();
    expect(find.text('Supermercado'), findsNothing);
    expect(find.text('Salário de outubro'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Supermercado'), findsOneWidget);
    expect(find.text('Salário de outubro'), findsOneWidget);
  });

  testWidgets('filtros de conta e categoria vão para a API', (tester) async {
    await abrirApp(tester, repoComDados());
    await irParaTransacoes(tester);

    await tester.tap(
      find.widgetWithText(DropdownButtonFormField<int?>, 'Conta'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Itaú').last);
    await tester.pumpAndSettle();

    expect(find.text('Salário de outubro'), findsOneWidget);
    expect(find.text('Supermercado'), findsNothing);
  });

  testWidgets('Parcela não tem editar nem excluir e leva ao Parcelamento', (
    tester,
  ) async {
    await abrirApp(tester, repoComDados());
    await irParaTransacoes(tester);

    // Só as duas avulsas são deslizáveis.
    expect(find.byType(Dismissible), findsNWidgets(2));

    // Pressão longa não abre menu na Parcela: ela só leva ao Parcelamento.
    await tester.longPress(find.text('Notebook'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Detalhe: em construção'), findsOneWidget);
  });

  testWidgets('excluir pelo menu pede confirmação e remove', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await irParaTransacoes(tester);

    await tester.longPress(find.text('Supermercado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir transação?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(repo.chamadas, ['excluirTransacao(1)']);
    expect(find.text('Supermercado'), findsNothing);
  });

  testWidgets('cancelar a confirmação não exclui', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await irParaTransacoes(tester);

    await tester.longPress(find.text('Supermercado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(repo.chamadas, isEmpty);
    expect(find.text('Supermercado'), findsOneWidget);
  });

  testWidgets('deslizar também pede confirmação', (tester) async {
    final repo = repoComDados();
    await abrirApp(tester, repo);
    await irParaTransacoes(tester);

    await tester.drag(find.text('Supermercado'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Excluir transação?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(repo.chamadas, ['excluirTransacao(1)']);
    expect(find.text('Supermercado'), findsNothing);
  });

  testWidgets('erro da API ao excluir aparece e a linha continua', (
    tester,
  ) async {
    final repo = repoComDados()
      ..falharProxima = FakeRepositorio.erro(404, 'Transação não encontrada.');
    await abrirApp(tester, repo);
    await irParaTransacoes(tester);

    await tester.longPress(find.text('Supermercado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Transação não encontrada.'), findsOneWidget);
    expect(find.text('Supermercado'), findsOneWidget);
  });

  testWidgets('mês sem transações mostra o estado vazio com ação', (
    tester,
  ) async {
    await abrirApp(tester, FakeRepositorio(contas: [nubank]));
    await irParaTransacoes(tester);

    expect(find.text('Nenhuma transação neste mês.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Nova transação'));
    await tester.pumpAndSettle();
    expect(find.text('Salvar e nova'), findsOneWidget);
  });

  testWidgets('falha de rede na leitura mostra aviso e tenta de novo', (
    tester,
  ) async {
    await abrirApp(tester, _RepoQueFalhaUmaVez(repoComDados()));
    await irParaTransacoes(tester);

    expect(find.text('Tentar de novo'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Supermercado'), findsOneWidget);
  });
}

/// Falha a primeira leitura de Transações com erro de rede.
class _RepoQueFalhaUmaVez extends FakeRepositorio {
  _RepoQueFalhaUmaVez(FakeRepositorio base)
    : super(
        contas: [nubank, itau],
        categorias: [alimentacao, transporte, salario],
      ) {
    _base = base;
  }

  late final FakeRepositorio _base;
  bool _falhou = false;

  @override
  Future<List<Transacao>> transacoes({
    required String competencia,
    int? contaId,
    int? categoriaId,
  }) async {
    if (!_falhou) {
      _falhou = true;
      throw FakeRepositorio.semRede();
    }
    return _base.transacoes(
      competencia: competencia,
      contaId: contaId,
      categoriaId: categoriaId,
    );
  }
}
