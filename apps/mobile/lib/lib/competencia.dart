/// Competência trafega como "YYYY-MM"; o mês corrente é o de São Paulo.
library;

import 'package:timezone/timezone.dart' as tz;

final _formato = RegExp(r'^(\d{4})-(0[1-9]|1[0-2])$');

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

bool valida(String c) => _formato.hasMatch(c);

/// Mês corrente em `America/Sao_Paulo`, nunca pelo fuso do aparelho.
/// Exige `tz.initializeTimeZones()` antes (feito na `main`). `agora` existe
/// para os testes.
String competenciaAtual({DateTime Function()? agora}) {
  final instante = (agora ?? DateTime.now)().toUtc();
  final local = tz.TZDateTime.from(
    instante,
    tz.getLocation('America/Sao_Paulo'),
  );
  return _montar(local.year, local.month);
}

String deslocar(String c, int n) {
  final partes = c.split('-');
  final total = int.parse(partes[0]) * 12 + (int.parse(partes[1]) - 1) + n;
  return _montar(total ~/ 12, total % 12 + 1);
}

/// "2026-10" -> "outubro de 2026".
String formatar(String c) {
  final partes = c.split('-');
  return '${_meses[int.parse(partes[1]) - 1]} de ${int.parse(partes[0])}';
}

int comparar(String a, String b) => a.compareTo(b).sign;

String _montar(int ano, int mes) =>
    '${ano.toString().padLeft(4, '0')}-${mes.toString().padLeft(2, '0')}';
