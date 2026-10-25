import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/telas/parcelamento_detalhe_tela.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/acoes.dart';
import '../suporte/app_teste.dart';
import '../suporte/dados_teste.dart';
import '../suporte/fake_repositorio.dart';

Future<void> irParaParcelamentos(WidgetTester tester) async {
  await tester.tap(find.text('Parcelamentos'));
  await tester.pumpAndSettle();
}

FakeRepositorio repoCom(List<Parcelamento> parcelamentos) => FakeRepositorio(
  contas: [nubank, itau],
  categorias: [alimentacao, transporte, salario],
  parcelamentos: parcelamentos,
);

/// Abre só a tela de detalhe, sem o app em volta.
Future<void> abrirDetalhe(
  WidgetTester tester,
  FakeRepositorio repo,
  int? id,
) async {
  tester.view
    ..physicalSize = const Size(1200, 3000)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: semRetentativa,
      overrides: [repositorioProvider.overrideWithValue(repo)],
      child: MaterialApp(home: ParcelamentoDetalheTela(id: id)),
    ),
  );
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

  group('lista', () {
    testWidgets('mostra descrição, valor total, N×, 1ª parcela e status', (
      tester,
    ) async {
      await abrirApp(tester, repoCom([parcelamentoDetalhado()]));
      await irParaParcelamentos(tester);

      expect(find.text('Notebook'), findsOneWidget);
      expect(find.text(formatBRL('1200.00')), findsOneWidget);
      expect(find.textContaining('4× · 1ª em'), findsOneWidget);
      expect(find.text('Ativo'), findsWidgets);
    });

    testWidgets('filtra por status', (tester) async {
      final repo = repoCom([
        parcelamentoDetalhado(),
        Parcelamento(
          id: 6,
          descricao: 'Geladeira',
          valorTotal: '3000.00',
          numParcelas: 10,
          primeiraParcela: comp.deslocar(mesAtual, -3),
          contaId: 1,
          categoriaId: 11,
          status: StatusParcelamento.cancelado,
        ),
      ]);
      await abrirApp(tester, repo);
      await irParaParcelamentos(tester);
      expect(find.text('Notebook'), findsOneWidget);
      expect(find.text('Geladeira'), findsOneWidget);

      await tester.tap(find.text('Ativos'));
      await tester.pumpAndSettle();
      expect(find.text('Notebook'), findsOneWidget);
      expect(find.text('Geladeira'), findsNothing);

      await tester.tap(find.text('Cancelados'));
      await tester.pumpAndSettle();
      expect(find.text('Notebook'), findsNothing);
      expect(find.text('Geladeira'), findsOneWidget);
      expect(find.text('Cancelado'), findsWidgets);
    });

    testWidgets('sem Parcelamentos mostra o vazio com ação', (tester) async {
      await abrirApp(tester, repoCom([]));
      await irParaParcelamentos(tester);

      expect(find.text('Nenhum parcelamento.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Nova transação'));
      await tester.pumpAndSettle();
      expect(find.text('Parcelado'), findsOneWidget);
    });

    testWidgets('toque abre o detalhe', (tester) async {
      await abrirApp(tester, repoCom([parcelamentoDetalhado()]));
      await irParaParcelamentos(tester);
      await tester.tap(find.text('Notebook'));
      await tester.pumpAndSettle();

      expect(find.text('Parcelas'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
    });
  });

  group('detalhe', () {
    testWidgets('cabeçalho e Parcelas, com a do mês atual destacada', (
      tester,
    ) async {
      await abrirApp(tester, repoCom([parcelamentoDetalhado()]));
      await irParaParcelamentos(tester);
      await tester.tap(find.text('Notebook'));
      await tester.pumpAndSettle();

      expect(find.text('${formatBRL('1200.00')} em 4×'), findsOneWidget);
      expect(find.textContaining('Transporte • Nubank'), findsOneWidget);
      for (final n in ['1/4', '2/4', '3/4', '4/4']) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.text(formatBRL('300.00')), findsNWidgets(4));
      // Só a do mês corrente é marcada; só a passada fica esmaecida.
      expect(find.textContaining('mês atual'), findsOneWidget);
      final esmaecidas = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((o) => o.opacity == 0.55);
      expect(esmaecidas, hasLength(1));
    });

    testWidgets('não mostra prévia de valor da parcela nem divide o total', (
      tester,
    ) async {
      await abrirApp(tester, repoCom([parcelamentoDetalhado()]));
      await irParaParcelamentos(tester);
      await tester.tap(find.text('Notebook'));
      await tester.pumpAndSettle();

      // Só aparecem os valores que vieram da API.
      expect(find.text(formatBRL('400.00')), findsNothing);
    });

    testWidgets('Parcelamento inexistente: não encontrado', (tester) async {
      await abrirDetalhe(tester, repoCom([]), 999);

      expect(find.text('Parcelamento não encontrado.'), findsOneWidget);
      expect(find.text('Voltar aos Parcelamentos'), findsOneWidget);
    });

    testWidgets('id inválido na rota: não encontrado', (tester) async {
      await abrirDetalhe(tester, repoCom([]), null);

      expect(find.text('Parcelamento não encontrado.'), findsOneWidget);
    });

    testWidgets('cancelado não oferece cancelar', (tester) async {
      final repo = repoCom([
        parcelamentoDetalhado(status: StatusParcelamento.cancelado),
      ]);
      await abrirDetalhe(tester, repo, 5);

      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.text('Cancelar parcelamento'), findsNothing);
    });

    testWidgets('falha de rede na leitura mostra "Tentar de novo"', (
      tester,
    ) async {
      final repo = _RepoQueFalhaUmaVez(repoCom([parcelamentoDetalhado()]));
      await abrirDetalhe(tester, repo, 5);

      expect(find.text('Tentar de novo'), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();
      expect(find.text('Parcelas'), findsOneWidget);
    });
  });

  group('cancelamento', () {
    testWidgets('prévia calculada no cliente e resultado da API', (
      tester,
    ) async {
      final repo = repoCom([parcelamentoDetalhado()])
        // A API devolve números diferentes da prévia (virada de mês, outra
        // aba...): a mensagem final tem que usar os dela.
        ..resultadoCancelamento = const ResultadoCancelamento(
          id: 5,
          parcelasRemovidas: 1,
          parcelasPreservadas: 3,
        );
      await abrirDetalhe(tester, repo, 5);

      await tocar(tester, find.text('Cancelar parcelamento'));
      expect(find.text('Cancelar parcelamento?'), findsOneWidget);
      expect(
        find.text(
          'Remove 2 parcelas futuras; 2 (a do mês atual e as passadas) '
          'permanecem.',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'Cancelar parcelamento'),
      );
      await tester.pumpAndSettle();

      expect(repo.chamadas, ['cancelarParcelamento(5)']);
      expect(
        find.text(
          'Parcelamento cancelado. 1 parcela futura removida; 3 preservadas.',
        ),
        findsOneWidget,
      );
      // A página recarregou: status cancelado e sem o botão.
      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.text('Cancelar parcelamento'), findsNothing);
    });

    testWidgets('sem Parcelas futuras: só o status muda', (tester) async {
      final passado = Parcelamento(
        id: 7,
        descricao: 'Celular',
        valorTotal: '600.00',
        numParcelas: 2,
        primeiraParcela: comp.deslocar(mesAtual, -2),
        contaId: 1,
        categoriaId: 11,
        status: StatusParcelamento.ativo,
        parcelas: [
          Parcela(
            id: 71,
            numeroParcela: 1,
            competencia: comp.deslocar(mesAtual, -2),
            valor: '300.00',
          ),
          Parcela(
            id: 72,
            numeroParcela: 2,
            competencia: mesAtual,
            valor: '300.00',
          ),
        ],
      );
      await abrirDetalhe(tester, repoCom([passado]), 7);

      await tocar(tester, find.text('Cancelar parcelamento'));
      expect(
        find.text(
          'Não há parcelas futuras: apenas o status muda para cancelado.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('1 Parcela futura usa o singular', (tester) async {
      final um = Parcelamento(
        id: 8,
        descricao: 'Fone',
        valorTotal: '200.00',
        numParcelas: 2,
        primeiraParcela: mesAtual,
        contaId: 1,
        categoriaId: 11,
        status: StatusParcelamento.ativo,
        parcelas: [
          Parcela(
            id: 81,
            numeroParcela: 1,
            competencia: mesAtual,
            valor: '100.00',
          ),
          Parcela(
            id: 82,
            numeroParcela: 2,
            competencia: comp.deslocar(mesAtual, 1),
            valor: '100.00',
          ),
        ],
      );
      await abrirDetalhe(tester, repoCom([um]), 8);

      await tocar(tester, find.text('Cancelar parcelamento'));
      expect(
        find.text(
          'Remove 1 parcela futura; 1 (a do mês atual e as passadas) permanecem.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('desistir no diálogo não cancela', (tester) async {
      final repo = repoCom([parcelamentoDetalhado()]);
      await abrirDetalhe(tester, repo, 5);

      await tocar(tester, find.text('Cancelar parcelamento'));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.chamadas, isEmpty);
      expect(find.text('Cancelar parcelamento'), findsOneWidget);
    });

    testWidgets('422 "já cancelado" mostra a mensagem e recarrega', (
      tester,
    ) async {
      final repo = repoCom([parcelamentoDetalhado()]);
      await abrirDetalhe(tester, repo, 5);
      // Outra aba cancelou antes.
      repo.falharProxima = FakeRepositorio.erro(
        422,
        'Parcelamento já cancelado.',
      );

      await tocar(tester, find.text('Cancelar parcelamento'));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Cancelar parcelamento'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parcelamento já cancelado.'), findsOneWidget);
    });

    testWidgets('falha de rede mostra "Tentar de novo" e reenvia', (
      tester,
    ) async {
      final repo = repoCom([parcelamentoDetalhado()]);
      await abrirDetalhe(tester, repo, 5);
      repo.falharProxima = FakeRepositorio.semRede();

      await tocar(tester, find.text('Cancelar parcelamento'));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Cancelar parcelamento'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(repo.chamadas, isEmpty);

      await tocar(tester, find.text('Tentar de novo'));
      expect(repo.chamadas, ['cancelarParcelamento(5)']);
      expect(find.text('Cancelado'), findsOneWidget);
    });

    testWidgets('cancelar faz o Resumo reler ao voltar para ele', (
      tester,
    ) async {
      final repo = repoComDados();
      await abrirApp(tester, repo);
      final antes = repo.leituras.where((l) => l == 'parcelasAtivas').length;
      await irParaParcelamentos(tester);
      await tester.tap(find.text('Notebook'));
      await tester.pumpAndSettle();

      await tocar(tester, find.text('Cancelar parcelamento'));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Cancelar parcelamento'),
      );
      await tester.pumpAndSettle();

      // As abas fora de vista só releem quando voltam.
      await tester.tap(find.text('Resumo'));
      await tester.pumpAndSettle();
      expect(
        repo.leituras.where((l) => l == 'parcelasAtivas').length,
        greaterThan(antes),
      );
    });
  });

  group('criação pelo sheet', () {
    testWidgets('Parcelado fica desabilitado para Receita', (tester) async {
      await abrirApp(tester, repoComDados());
      await abrirSheet(tester);

      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parcelado'));
      await tester.pumpAndSettle();

      expect(find.text('Valor total'), findsNothing);
      expect(find.text('Número de parcelas'), findsNothing);
    });

    testWidgets('trocar para Receita desliga o modo Parcelado', (tester) async {
      await abrirApp(tester, repoComDados());
      await abrirSheet(tester);
      await tester.tap(find.text('Parcelado'));
      await tester.pumpAndSettle();
      expect(find.text('Valor total'), findsOneWidget);

      await tester.tap(find.text('Receita'));
      await tester.pumpAndSettle();
      expect(find.text('Valor total'), findsNothing);
      expect(find.text('Valor'), findsOneWidget);
    });

    testWidgets('Parcelado troca os campos e esconde "Salvar e nova"', (
      tester,
    ) async {
      await abrirApp(tester, repoComDados());
      await abrirSheet(tester);
      expect(find.text('Salvar e nova'), findsOneWidget);

      await tester.tap(find.text('Parcelado'));
      await tester.pumpAndSettle();

      expect(find.text('Valor total'), findsOneWidget);
      expect(find.text('Número de parcelas'), findsOneWidget);
      expect(find.text('Primeira parcela'), findsOneWidget);
      expect(find.text('Competência'), findsNothing);
      expect(find.text('Salvar e nova'), findsNothing);
    });

    testWidgets('valida o número de parcelas no cliente', (tester) async {
      final repo = repoComDados();
      await abrirApp(tester, repo);
      await abrirSheet(tester);
      await tester.tap(find.text('Parcelado'));
      await tester.pumpAndSettle();
      await escolher(tester, 'Conta', 'Nubank');
      await escolher(tester, 'Categoria', 'Transporte');
      await digitar(tester, 'Valor total', '3600');
      await digitar(tester, 'Descrição', 'Notebook');
      await digitar(tester, 'Número de parcelas', '1');

      await tocar(tester, find.text('Salvar'));

      expect(
        find.text('Informe um número inteiro de parcelas, no mínimo 2.'),
        findsOneWidget,
      );
      expect(repo.chamadas, isEmpty);
    });

    testWidgets('Salvar cria o Parcelamento e abre o detalhe', (tester) async {
      final repo = repoComDados();
      await abrirApp(tester, repo);
      await abrirSheet(tester);
      await tester.tap(find.text('Parcelado'));
      await tester.pumpAndSettle();
      await escolher(tester, 'Conta', 'Nubank');
      await escolher(tester, 'Categoria', 'Transporte');
      await digitar(tester, 'Valor total', '3.600,00');
      await digitar(tester, 'Descrição', 'Notebook novo');
      await digitar(tester, 'Número de parcelas', '12');

      await tocar(tester, find.text('Salvar'));

      expect(repo.chamadas, [
        'criarParcelamento(Notebook novo, 3600.00, 12, $mesAtual, 1, 11)',
      ]);
      // Detalhe do Parcelamento criado (a API devolve as Parcelas).
      expect(find.text('Notebook novo'), findsOneWidget);
      expect(find.text('Parcelas'), findsOneWidget);
      expect(find.text('1/12'), findsOneWidget);
    });

    testWidgets('erro 422 da API aparece inline e mantém o digitado', (
      tester,
    ) async {
      final repo = repoComDados();
      await abrirApp(tester, repo);
      await abrirSheet(tester);
      await tester.tap(find.text('Parcelado'));
      await tester.pumpAndSettle();
      await escolher(tester, 'Conta', 'Nubank');
      await escolher(tester, 'Categoria', 'Transporte');
      await digitar(tester, 'Valor total', '3600');
      await digitar(tester, 'Descrição', 'Notebook');
      await digitar(tester, 'Número de parcelas', '12');
      repo.falharProxima = FakeRepositorio.erro(
        422,
        "Parcelamentos só aceitam categorias do tipo 'gasto'.",
      );

      await tocar(tester, find.text('Salvar'));

      expect(
        find.text("Parcelamentos só aceitam categorias do tipo 'gasto'."),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, '3600'), findsOneWidget);
      expect(find.widgetWithText(TextField, '12'), findsOneWidget);
    });

    testWidgets('criar Parcelamento atualiza o Resumo', (tester) async {
      final repo = repoComDados();
      await abrirApp(tester, repo);
      final antes = repo.leituras.where((l) => l == 'parcelasAtivas').length;
      await abrirSheet(tester);
      await tester.tap(find.text('Parcelado'));
      await tester.pumpAndSettle();
      await escolher(tester, 'Conta', 'Nubank');
      await escolher(tester, 'Categoria', 'Transporte');
      await digitar(tester, 'Valor total', '3600');
      await digitar(tester, 'Descrição', 'Notebook');
      await digitar(tester, 'Número de parcelas', '3');
      await tocar(tester, find.text('Salvar'));

      expect(
        repo.leituras.where((l) => l == 'parcelasAtivas').length,
        greaterThan(antes),
      );
    });
  });
}

/// Falha a primeira leitura de um Parcelamento com erro de rede.
class _RepoQueFalhaUmaVez extends FakeRepositorio {
  _RepoQueFalhaUmaVez(this._base)
    : super(
        contas: [nubank, itau],
        categorias: [alimentacao, transporte, salario],
      );

  final FakeRepositorio _base;
  bool _falhou = false;

  @override
  Future<Parcelamento> parcelamento(int id) async {
    if (!_falhou) {
      _falhou = true;
      throw FakeRepositorio.semRede();
    }
    return _base.parcelamento(id);
  }
}
