import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/acoes.dart';
import '../suporte/app_teste.dart';
import '../suporte/dados_teste.dart';
import '../suporte/fake_repositorio.dart';

BalancoMensal balanco(String receitas, String gastos, String saldo) =>
    BalancoMensal(
      competencia: mesAtual,
      totalReceitas: receitas,
      totalGastos: gastos,
      saldo: saldo,
    );

ParcelaAtiva parcela(int n, String competencia, String valor) => ParcelaAtiva(
  transacaoId: 100 + n,
  parcelamentoId: 5,
  parcelamentoDescricao: 'Notebook',
  numeroParcela: n,
  numParcelasTotal: 12,
  competencia: competencia,
  valor: valor,
  contaId: 1,
  contaNome: 'Nubank',
  categoriaId: 11,
  categoriaNome: 'Transporte',
);

FakeRepositorio repoComResumo({String saldo = '1800.00'}) => FakeRepositorio(
  contas: [nubank, itau],
  categorias: [alimentacao, transporte, salario],
  parcelamentos: [parcelamentoDetalhado()],
  balancos: {mesAtual: balanco('5000.00', '3200.00', saldo)},
  gastos: {
    mesAtual: GastosPorCategoria(
      competencia: mesAtual,
      itens: const [
        GastoCategoria(
          categoriaId: 10,
          categoriaNome: 'Alimentação',
          total: '1200.00',
        ),
        GastoCategoria(
          categoriaId: 11,
          categoriaNome: 'Transporte',
          total: '300.00',
        ),
      ],
    ),
  },
  parcelasAtivasLista: [
    parcela(1, mesAtual, '300.00'),
    parcela(2, comp.deslocar(mesAtual, 1), '300.00'),
  ],
);

void main() {
  prepararTestes();

  testWidgets('mostra o Balanço Mensal com Saldo em superávit', (tester) async {
    await abrirApp(tester, repoComResumo());

    expect(find.text('Balanço Mensal'), findsOneWidget);
    expect(find.text(formatBRL('5000.00')), findsOneWidget);
    expect(find.text(formatBRL('3200.00')), findsOneWidget);
    expect(find.text('▲ ${formatBRL('1800.00')}'), findsOneWidget);
    expect(find.text('Superávit'), findsOneWidget);
  });

  testWidgets('Saldo negativo é déficit, com ícone e texto além da cor', (
    tester,
  ) async {
    await abrirApp(tester, repoComResumo(saldo: '-100.00'));

    expect(find.text('▼ ${formatBRL('-100.00')}'), findsOneWidget);
    expect(find.text('Déficit'), findsOneWidget);
  });

  testWidgets('Gastos por Categoria com barra proporcional ao maior', (
    tester,
  ) async {
    await abrirApp(tester, repoComResumo());

    expect(find.text('Gastos por Categoria'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    expect(find.text(formatBRL('1200.00')), findsOneWidget);
    expect(find.text('Transporte'), findsOneWidget);
    final barras = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((b) => b.value)
        .toList();
    expect(barras, [1.0, 0.25]);
  });

  testWidgets('Parcelas Ativas agrupadas por Competência, com link', (
    tester,
  ) async {
    await abrirApp(tester, repoComResumo());

    expect(find.text('Parcelas Ativas'), findsOneWidget);
    expect(find.text('A partir do mês corrente'), findsOneWidget);
    final atual = comp.formatar(mesAtual);
    final proximo = comp.formatar(comp.deslocar(mesAtual, 1));
    expect(
      find.text('${atual[0].toUpperCase()}${atual.substring(1)}'),
      findsOneWidget,
    );
    expect(
      find.text('${proximo[0].toUpperCase()}${proximo.substring(1)}'),
      findsOneWidget,
    );
    expect(find.textContaining('1/12'), findsOneWidget);
    expect(find.textContaining('2/12'), findsOneWidget);
    expect(find.text('Nubank · Transporte'), findsNWidgets(2));

    await tester.ensureVisible(find.textContaining('1/12'));
    await tester.tap(find.textContaining('1/12'));
    await tester.pumpAndSettle();
    expect(find.text('Parcelas'), findsOneWidget);
    expect(find.text('Cancelar parcelamento'), findsOneWidget);
  });

  testWidgets('mês sem lançamentos: balanço zerado e estados vazios', (
    tester,
  ) async {
    await abrirApp(tester, FakeRepositorio());

    expect(find.text('• ${formatBRL('0.00')}'), findsOneWidget);
    expect(find.text('Zerado'), findsOneWidget);
    expect(find.text('Nenhum gasto neste mês.'), findsOneWidget);
    expect(find.text('Nenhuma parcela a vencer.'), findsOneWidget);
  });

  testWidgets('trocar a Competência relê balanço e gastos, não as Parcelas', (
    tester,
  ) async {
    final repo = repoComResumo();
    await abrirApp(tester, repo);
    expect(repo.leituras.where((l) => l == 'parcelasAtivas'), hasLength(1));

    await tester.tap(find.byTooltip('Próxima competência'));
    await tester.pumpAndSettle();

    final proximo = comp.deslocar(mesAtual, 1);
    expect(repo.leituras, contains('balanco($proximo)'));
    expect(repo.leituras, contains('gastos($proximo)'));
    expect(repo.leituras.where((l) => l == 'parcelasAtivas'), hasLength(1));
    expect(find.text('Nenhum gasto neste mês.'), findsOneWidget);
    // As Parcelas Ativas continuam as mesmas, do mês corrente em diante.
    expect(find.textContaining('1/12'), findsOneWidget);
  });

  testWidgets('lançar uma Transação atualiza o Resumo sem recarregar', (
    tester,
  ) async {
    final repo = repoComResumo();
    repo.aoMutar = () =>
        repo.balancos[mesAtual] = balanco('5000.00', '3249.90', '1750.10');
    await abrirApp(tester, repo);
    expect(find.text('▲ ${formatBRL('1800.00')}'), findsOneWidget);

    await abrirSheet(tester);
    await escolher(tester, 'Conta', 'Nubank');
    await escolher(tester, 'Categoria', 'Alimentação');
    await digitar(tester, 'Valor', '49,90');
    await digitar(tester, 'Descrição', 'Supermercado');
    await tocar(tester, find.text('Salvar'));

    expect(find.text('▲ ${formatBRL('1750.10')}'), findsOneWidget);
    expect(find.text('▲ ${formatBRL('1800.00')}'), findsNothing);
  });

  testWidgets('puxar para atualizar relê os três relatórios', (tester) async {
    final repo = repoComResumo();
    await abrirApp(tester, repo);
    expect(repo.leituras, hasLength(3));

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.leituras, hasLength(6));
  });

  testWidgets('falha em um relatório não derruba os outros', (tester) async {
    final repo = repoComResumo()..falhasDeLeitura.add('gastos');
    await abrirApp(tester, repo);

    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.text(formatBRL('5000.00')), findsOneWidget);
    expect(find.textContaining('1/12'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar de novo'), findsNothing);
    expect(find.text('Alimentação'), findsOneWidget);
  });
}
