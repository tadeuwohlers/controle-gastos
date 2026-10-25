/// Contrato entre o app e a API: o que o app chama, envia e lê, conferido
/// contra o `openapi.json` gerado pela API.
library;

typedef Json = Map<String, dynamic>;

class Uso {
  const Uso(
    this.metodo,
    this.path, {
    this.corpo,
    this.resposta,
    this.query = const [],
  });

  final String metodo;
  final String path;

  /// Schema do corpo enviado; cada campo obrigatório dele deve ser enviado.
  final String? corpo;

  /// Schema da resposta (ou dos itens, se for lista).
  final String? resposta;
  final List<String> query;
}

/// Endpoints usados pelo app (`lib/api/repositorio.dart`).
const usos = [
  Uso('get', '/api/v1/contas', resposta: 'ContaRead'),
  Uso('post', '/api/v1/contas', corpo: 'ContaCreate', resposta: 'ContaRead'),
  Uso('get', '/api/v1/categorias', resposta: 'CategoriaRead', query: ['tipo']),
  Uso(
    'post',
    '/api/v1/categorias',
    corpo: 'CategoriaCreate',
    resposta: 'CategoriaRead',
  ),
  Uso(
    'get',
    '/api/v1/transacoes',
    resposta: 'TransacaoRead',
    query: ['competencia', 'conta_id', 'categoria_id'],
  ),
  Uso(
    'post',
    '/api/v1/transacoes',
    corpo: 'TransacaoCreate',
    resposta: 'TransacaoRead',
  ),
  Uso(
    'put',
    '/api/v1/transacoes/{id}',
    corpo: 'TransacaoPut',
    resposta: 'TransacaoRead',
  ),
  Uso('delete', '/api/v1/transacoes/{id}'),
  Uso(
    'get',
    '/api/v1/parcelamentos',
    resposta: 'ParcelamentoRead',
    query: ['status'],
  ),
  Uso(
    'post',
    '/api/v1/parcelamentos',
    corpo: 'ParcelamentoCreate',
    resposta: 'ParcelamentoReadComParcelas',
  ),
  Uso(
    'get',
    '/api/v1/parcelamentos/{id}',
    resposta: 'ParcelamentoReadComParcelas',
  ),
  Uso(
    'post',
    '/api/v1/parcelamentos/{id}/cancelar',
    resposta: 'CancelamentoResult',
  ),
  Uso(
    'get',
    '/api/v1/relatorios/balanco-mensal',
    resposta: 'BalancoMensal',
    query: ['competencia'],
  ),
  Uso(
    'get',
    '/api/v1/relatorios/gastos-por-categoria',
    resposta: 'GastosPorCategoria',
    query: ['competencia'],
  ),
  Uso('get', '/api/v1/relatorios/parcelas-ativas', resposta: 'ParcelaAtiva'),
];

/// Campos que o app lê de cada schema de resposta (`lib/api/modelos.dart`).
const camposLidos = {
  'ContaRead': ['id', 'nome'],
  'CategoriaRead': ['id', 'nome', 'tipo'],
  'TransacaoRead': [
    'id',
    'tipo',
    'valor',
    'descricao',
    'competencia',
    'conta_id',
    'categoria_id',
    'parcelamento_id',
    'numero_parcela',
  ],
  'ParcelaResumida': ['id', 'numero_parcela', 'competencia', 'valor'],
  'ParcelamentoRead': [
    'id',
    'descricao',
    'valor_total',
    'num_parcelas',
    'primeira_parcela',
    'conta_id',
    'categoria_id',
    'status',
  ],
  'ParcelamentoReadComParcelas': ['parcelas'],
  'CancelamentoResult': ['id', 'parcelas_removidas', 'parcelas_preservadas'],
  'BalancoMensal': ['competencia', 'total_receitas', 'total_gastos', 'saldo'],
  'GastoCategoria': ['categoria_id', 'categoria_nome', 'total'],
  'GastosPorCategoria': ['competencia', 'itens'],
  'ParcelaAtiva': [
    'transacao_id',
    'parcelamento_id',
    'parcelamento_descricao',
    'numero_parcela',
    'num_parcelas_total',
    'competencia',
    'valor',
    'conta_id',
    'conta_nome',
    'categoria_id',
    'categoria_nome',
  ],
};

/// Campos que o app envia em cada schema de corpo.
const camposEnviados = {
  'ContaCreate': ['nome'],
  'CategoriaCreate': ['nome', 'tipo'],
  'TransacaoCreate': [
    'tipo',
    'valor',
    'descricao',
    'competencia',
    'conta_id',
    'categoria_id',
  ],
  'TransacaoPut': [
    'valor',
    'descricao',
    'competencia',
    'conta_id',
    'categoria_id',
  ],
  'ParcelamentoCreate': [
    'descricao',
    'valor_total',
    'num_parcelas',
    'primeira_parcela',
    'conta_id',
    'categoria_id',
  ],
};

/// Valores de enum que o app conhece (`lib/api/modelos.dart`).
const enums = {
  'TipoEnum': ['gasto', 'receita'],
  'StatusEnum': ['ativo', 'cancelado'],
};

/// Devolve os problemas encontrados; lista vazia = contrato respeitado.
List<String> verificar(Json openapi) {
  final problemas = <String>[];
  final paths = openapi['paths'] as Json;
  final schemas = (openapi['components'] as Json)['schemas'] as Json;

  Json? schema(String nome) => schemas[nome] as Json?;

  for (final u in usos) {
    final rotulo = '${u.metodo.toUpperCase()} ${u.path}';
    final op = (paths[u.path] as Json?)?[u.metodo] as Json?;
    if (op == null) {
      problemas.add('$rotulo: endpoint não existe');
      continue;
    }
    final params = {
      for (final p in (op['parameters'] as List<dynamic>? ?? const []))
        (p as Json)['name'] as String,
    };
    for (final q in u.query) {
      if (!params.contains(q)) problemas.add('$rotulo: query "$q" não existe');
    }
    for (final nome in [u.corpo, u.resposta].whereType<String>()) {
      if (schema(nome) == null) {
        problemas.add('$rotulo: schema $nome não existe');
      }
    }
  }

  camposLidos.forEach((nome, campos) {
    final props = (schema(nome)?['properties'] as Json?) ?? const {};
    final obrigatorios =
        ((schema(nome)?['required'] as List<dynamic>?) ?? const []);
    for (final c in campos) {
      if (!props.containsKey(c)) {
        problemas.add('$nome: campo lido "$c" não existe');
      } else if (!obrigatorios.contains(c)) {
        problemas.add('$nome: campo lido "$c" deixou de ser obrigatório');
      }
    }
  });

  camposEnviados.forEach((nome, campos) {
    final s = schema(nome);
    final props = (s?['properties'] as Json?) ?? const {};
    for (final c in campos) {
      if (!props.containsKey(c)) {
        problemas.add('$nome: campo enviado "$c" não existe');
      }
    }
    for (final obrigatorio
        in ((s?['required'] as List<dynamic>?) ?? const [])) {
      if (!campos.contains(obrigatorio)) {
        problemas.add('$nome: campo obrigatório "$obrigatorio" não é enviado');
      }
    }
  });

  enums.forEach((nome, valores) {
    final atuais = (schema(nome)?['enum'] as List<dynamic>?) ?? const [];
    for (final v in valores) {
      if (!atuais.contains(v)) problemas.add('$nome: valor "$v" não existe');
    }
    for (final v in atuais) {
      if (!valores.contains(v)) {
        problemas.add('$nome: valor novo "$v" não tratado');
      }
    }
  });

  return problemas;
}
