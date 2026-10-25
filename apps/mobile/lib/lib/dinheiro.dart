/// Dinheiro trafega como string ponta a ponta; nada aqui faz aritmética.
library;

final _entradaBr = RegExp(r'^(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{0,2}))?$');

/// "1.234,56" -> "1234.56". Puramente textual; null se inválido.
String? parseValorBR(String entrada) {
  final m = _entradaBr.firstMatch(entrada.trim());
  if (m == null) return null;
  final inteiro = m
      .group(1)!
      .replaceAll('.', '')
      .replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (inteiro.length > 10) return null;
  final centavos = (m.group(2) ?? '').padRight(2, '0');
  if (RegExp(r'^0*$').hasMatch(inteiro + centavos)) return null;
  return '$inteiro.$centavos';
}

/// "1234.56" -> "R$ 1.234,56" (com espaço não separável após o "R$").
/// Agrupa os dígitos como texto, sem passar por `double`.
String formatBRL(String valor) {
  final negativo = valor.startsWith('-');
  final corpo = negativo ? valor.substring(1) : valor;
  final partes = corpo.split('.');
  final inteiro = partes[0].isEmpty ? '0' : partes[0];
  final decimais = partes.length > 1 ? partes[1] : '';
  final centavos = '${decimais}00'.substring(0, 2);

  final grupos = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) grupos.write('.');
    grupos.write(inteiro[i]);
  }
  return '${negativo ? '-' : ''}R\$ $grupos,$centavos';
}

enum Sinal { positivo, negativo, zero }

/// Decide pela forma textual (prefixo `-` ou só zeros).
Sinal sinal(String valor) {
  if (RegExp(r'^-?[0.]*$').hasMatch(valor)) return Sinal.zero;
  return valor.startsWith('-') ? Sinal.negativo : Sinal.positivo;
}
