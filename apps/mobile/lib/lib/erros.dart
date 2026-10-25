const _padrao = 'Algo deu errado. Tente de novo.';
const _prefixoPydantic = 'Value error, ';

/// Transforma o corpo de erro da API (já decodificado) em texto para a UI.
/// `detail` pode ser string ou lista de objetos com `msg`.
String extrairMensagem(Object? corpo) {
  if (corpo is! Map || !corpo.containsKey('detail')) return _padrao;
  final detail = corpo['detail'];
  if (detail is String) return detail;
  if (detail is List) {
    final msgs = [
      for (final d in detail)
        if (d is Map && d['msg'] is String)
          (d['msg'] as String).replaceFirst(_prefixoPydantic, ''),
    ];
    if (msgs.isNotEmpty) return msgs.join('\n');
  }
  return _padrao;
}
