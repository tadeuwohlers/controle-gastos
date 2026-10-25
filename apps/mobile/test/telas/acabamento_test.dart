// Acabamento (spec 003): alvos de toque, rótulos, contraste, tema escuro e
// fonte grande em todas as telas, sem overflow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../suporte/acoes.dart';
import '../suporte/app_teste.dart';
import '../suporte/dados_teste.dart';

void usar(WidgetTester tester, {double fonte = 1.0, Brightness? tema}) {
  tester.platformDispatcher.textScaleFactorTestValue = fonte;
  if (tema != null) {
    tester.platformDispatcher.platformBrightnessTestValue = tema;
  }
  addTearDown(() {
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
}

Future<void> irPara(WidgetTester tester, String aba) async {
  await tester.tap(find.text(aba));
  await tester.pumpAndSettle();
}

/// Falha se o último quadro lançou exceção (overflow, por exemplo), dizendo
/// em qual tela e com o texto completo do erro.
void semErro(WidgetTester tester, String tela) {
  final erro = tester.takeException();
  if (erro != null) fail('Exceção em $tela:\n$erro');
}

/// Percorre as quatro abas, o detalhe de um Parcelamento e o sheet, e falha
/// se qualquer quadro lançar exceção (overflow, por exemplo).
Future<void> percorrer(WidgetTester tester) async {
  await abrirApp(tester, repoComDados());
  semErro(tester, 'Resumo');

  await irPara(tester, 'Transações');
  semErro(tester, 'Transações');

  await irPara(tester, 'Parcelamentos');
  semErro(tester, 'Parcelamentos');
  await tester.tap(find.text('Notebook'));
  await tester.pumpAndSettle();
  semErro(tester, 'Detalhe do Parcelamento');
  await tester.tap(find.byTooltip('Voltar'));
  await tester.pumpAndSettle();

  await irPara(tester, 'Cadastros');
  semErro(tester, 'Cadastros');

  await abrirSheet(tester);
  semErro(tester, 'Sheet à vista');
  await tester.tap(find.text('Parcelado'));
  await tester.pumpAndSettle();
  semErro(tester, 'Sheet parcelado');
}

void main() {
  prepararTestes();

  group('tema escuro', () {
    testWidgets('todas as telas renderizam sem erro', (tester) async {
      usar(tester, tema: Brightness.dark);
      await percorrer(tester);
    });

    testWidgets('usa o esquema escuro do sistema', (tester) async {
      usar(tester, tema: Brightness.dark);
      await abrirApp(tester, repoComDados());
      final tema = Theme.of(tester.element(find.byType(Scaffold).first));
      expect(tema.brightness, Brightness.dark);
    });
  });

  group('fonte grande', () {
    for (final fonte in [1.5, 2.0]) {
      testWidgets('todas as telas com fonte ${fonte}x sem overflow', (
        tester,
      ) async {
        usar(tester, fonte: fonte);
        await percorrer(tester);
      });
    }

    testWidgets('fonte 2x no escuro', (tester) async {
      usar(tester, fonte: 2.0, tema: Brightness.dark);
      await percorrer(tester);
    });
  });

  group('acessibilidade', () {
    Future<void> conferir(WidgetTester tester, String onde) async {
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
        reason: 'alvos de toque (>= 48 dp) em $onde',
      );
      await expectLater(
        tester,
        meetsGuideline(labeledTapTargetGuideline),
        reason: 'rótulo em todo alvo de toque em $onde',
      );
      await expectLater(
        tester,
        meetsGuideline(textContrastGuideline),
        reason: 'contraste do texto em $onde',
      );
    }

    for (final tema in [Brightness.light, Brightness.dark]) {
      testWidgets('guias de acessibilidade, tema ${tema.name}', (tester) async {
        final semantica = tester.ensureSemantics();
        usar(tester, tema: tema);
        await abrirApp(tester, repoComDados());
        await conferir(tester, 'Resumo');

        await irPara(tester, 'Transações');
        await conferir(tester, 'Transações');

        await irPara(tester, 'Parcelamentos');
        await conferir(tester, 'Parcelamentos');
        await tester.tap(find.text('Notebook'));
        await tester.pumpAndSettle();
        await conferir(tester, 'Detalhe do Parcelamento');
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();

        await irPara(tester, 'Cadastros');
        await conferir(tester, 'Cadastros');

        await abrirSheet(tester);
        await conferir(tester, 'Sheet de Nova transação');
        semantica.dispose();
      });
    }
  });
}
