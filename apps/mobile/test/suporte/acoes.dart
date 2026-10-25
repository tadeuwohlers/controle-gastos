import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
