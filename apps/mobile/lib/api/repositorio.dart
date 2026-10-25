import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/api/modelos.dart';

/// Chamadas tipadas, uma por endpoint da spec 001. `valor` e demais Decimal
/// seguem como String nos dois sentidos.
class Repositorio {
  const Repositorio(this._api);

  final ApiClient _api;

  static const _base = '/api/v1';

  List<Json> _lista(Object? corpo) => (corpo! as List<dynamic>).cast<Json>();

  // Contas e Categorias

  Future<List<Conta>> contas() async => [
    for (final j in _lista(await _api.get('$_base/contas'))) Conta.fromJson(j),
  ];

  Future<Conta> criarConta(String nome) async => Conta.fromJson(
    await _api.post('$_base/contas', body: {'nome': nome}) as Json,
  );

  Future<List<Categoria>> categorias({TipoTransacao? tipo}) async => [
    for (final j in _lista(
      await _api.get(
        '$_base/categorias',
        query: {if (tipo != null) 'tipo': tipo.name},
      ),
    ))
      Categoria.fromJson(j),
  ];

  Future<Categoria> criarCategoria(String nome, TipoTransacao tipo) async =>
      Categoria.fromJson(
        await _api.post(
          '$_base/categorias',
          body: {'nome': nome, 'tipo': tipo.name},
        ) as Json,
      );

  // Transações

  Future<List<Transacao>> transacoes({
    required String competencia,
    int? contaId,
    int? categoriaId,
  }) async => [
    for (final j in _lista(
      await _api.get(
        '$_base/transacoes',
        query: {
          'competencia': competencia,
          if (contaId != null) 'conta_id': '$contaId',
          if (categoriaId != null) 'categoria_id': '$categoriaId',
        },
      ),
    ))
      Transacao.fromJson(j),
  ];

  Future<Transacao> criarTransacao({
    required TipoTransacao tipo,
    required String valor,
    required String descricao,
    required String competencia,
    required int contaId,
    required int categoriaId,
  }) async => Transacao.fromJson(
    await _api.post(
      '$_base/transacoes',
      body: {
        'tipo': tipo.name,
        'valor': valor,
        'descricao': descricao,
        'competencia': competencia,
        'conta_id': contaId,
        'categoria_id': categoriaId,
      },
    ) as Json,
  );

  Future<Transacao> atualizarTransacao(
    int id, {
    required String valor,
    required String descricao,
    required String competencia,
    required int contaId,
    required int categoriaId,
  }) async => Transacao.fromJson(
    await _api.put(
      '$_base/transacoes/$id',
      body: {
        'valor': valor,
        'descricao': descricao,
        'competencia': competencia,
        'conta_id': contaId,
        'categoria_id': categoriaId,
      },
    ) as Json,
  );

  Future<void> excluirTransacao(int id) async {
    await _api.delete('$_base/transacoes/$id');
  }

  // Parcelamentos

  Future<List<Parcelamento>> parcelamentos({
    StatusParcelamento? status,
  }) async => [
    for (final j in _lista(
      await _api.get(
        '$_base/parcelamentos',
        query: {if (status != null) 'status': status.name},
      ),
    ))
      Parcelamento.fromJson(j),
  ];

  Future<Parcelamento> parcelamento(int id) async =>
      Parcelamento.fromJson(await _api.get('$_base/parcelamentos/$id') as Json);

  Future<Parcelamento> criarParcelamento({
    required String descricao,
    required String valorTotal,
    required int numParcelas,
    required String primeiraParcela,
    required int contaId,
    required int categoriaId,
  }) async => Parcelamento.fromJson(
    await _api.post(
      '$_base/parcelamentos',
      body: {
        'descricao': descricao,
        'valor_total': valorTotal,
        'num_parcelas': numParcelas,
        'primeira_parcela': primeiraParcela,
        'conta_id': contaId,
        'categoria_id': categoriaId,
      },
    ) as Json,
  );

  Future<ResultadoCancelamento> cancelarParcelamento(int id) async =>
      ResultadoCancelamento.fromJson(
        await _api.post('$_base/parcelamentos/$id/cancelar') as Json,
      );

  // Relatórios

  Future<BalancoMensal> balancoMensal(String competencia) async =>
      BalancoMensal.fromJson(
        await _api.get(
          '$_base/relatorios/balanco-mensal',
          query: {'competencia': competencia},
        ) as Json,
      );

  Future<GastosPorCategoria> gastosPorCategoria(String competencia) async =>
      GastosPorCategoria.fromJson(
        await _api.get(
          '$_base/relatorios/gastos-por-categoria',
          query: {'competencia': competencia},
        ) as Json,
      );

  Future<List<ParcelaAtiva>> parcelasAtivas() async => [
    for (final j in _lista(await _api.get('$_base/relatorios/parcelas-ativas')))
      ParcelaAtiva.fromJson(j),
  ];
}
