import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chave = 'ultima_conta_id';

/// Última Conta usada no lançamento. Falha de leitura ou escrita é ignorada:
/// é só uma conveniência.
class UltimaConta {
  const UltimaConta();

  /// O id salvo, se ainda existir em [contasExistentes].
  Future<int?> ler(Iterable<int> contasExistentes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_chave);
      return (id != null && contasExistentes.contains(id)) ? id : null;
    } on Object {
      return null;
    }
  }

  Future<void> salvar(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_chave, id);
    } on Object {
      // ignora
    }
  }
}

final ultimaContaProvider = Provider<UltimaConta>((ref) => const UltimaConta());
