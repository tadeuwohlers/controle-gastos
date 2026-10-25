/// Modelos da API. `Decimal` chega como String e continua String.
library;

enum TipoTransacao {
  gasto,
  receita;

  static TipoTransacao fromJson(String v) =>
      TipoTransacao.values.firstWhere((t) => t.name == v);
}

enum StatusParcelamento {
  ativo,
  cancelado;

  static StatusParcelamento fromJson(String v) =>
      StatusParcelamento.values.firstWhere((s) => s.name == v);
}

typedef Json = Map<String, dynamic>;

class Conta {
  const Conta({required this.id, required this.nome});
  factory Conta.fromJson(Json j) =>
      Conta(id: j['id'] as int, nome: j['nome'] as String);

  final int id;
  final String nome;
}

class Categoria {
  const Categoria({required this.id, required this.nome, required this.tipo});
  factory Categoria.fromJson(Json j) => Categoria(
    id: j['id'] as int,
    nome: j['nome'] as String,
    tipo: TipoTransacao.fromJson(j['tipo'] as String),
  );

  final int id;
  final String nome;
  final TipoTransacao tipo;
}

class Transacao {
  const Transacao({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.competencia,
    required this.contaId,
    required this.categoriaId,
    this.parcelamentoId,
    this.numeroParcela,
  });
  factory Transacao.fromJson(Json j) => Transacao(
    id: j['id'] as int,
    tipo: TipoTransacao.fromJson(j['tipo'] as String),
    valor: j['valor'] as String,
    descricao: j['descricao'] as String,
    competencia: j['competencia'] as String,
    contaId: j['conta_id'] as int,
    categoriaId: j['categoria_id'] as int,
    parcelamentoId: j['parcelamento_id'] as int?,
    numeroParcela: j['numero_parcela'] as int?,
  );

  final int id;
  final TipoTransacao tipo;
  final String valor;
  final String descricao;
  final String competencia;
  final int contaId;
  final int categoriaId;
  final int? parcelamentoId;
  final int? numeroParcela;

  /// Parcela de um Parcelamento: só leitura. Transação Avulsa é a que não é.
  bool get ehParcela => parcelamentoId != null;
}

class Parcela {
  const Parcela({
    required this.id,
    required this.numeroParcela,
    required this.competencia,
    required this.valor,
  });
  factory Parcela.fromJson(Json j) => Parcela(
    id: j['id'] as int,
    numeroParcela: j['numero_parcela'] as int,
    competencia: j['competencia'] as String,
    valor: j['valor'] as String,
  );

  final int id;
  final int numeroParcela;
  final String competencia;
  final String valor;
}

class Parcelamento {
  const Parcelamento({
    required this.id,
    required this.descricao,
    required this.valorTotal,
    required this.numParcelas,
    required this.primeiraParcela,
    required this.contaId,
    required this.categoriaId,
    required this.status,
    this.parcelas = const [],
  });
  factory Parcelamento.fromJson(Json j) => Parcelamento(
    id: j['id'] as int,
    descricao: j['descricao'] as String,
    valorTotal: j['valor_total'] as String,
    numParcelas: j['num_parcelas'] as int,
    primeiraParcela: j['primeira_parcela'] as String,
    contaId: j['conta_id'] as int,
    categoriaId: j['categoria_id'] as int,
    status: StatusParcelamento.fromJson(j['status'] as String),
    parcelas: [
      for (final p in (j['parcelas'] as List<dynamic>? ?? const []))
        Parcela.fromJson(p as Json),
    ],
  );

  final int id;
  final String descricao;
  final String valorTotal;
  final int numParcelas;
  final String primeiraParcela;
  final int contaId;
  final int categoriaId;
  final StatusParcelamento status;

  /// Vazio nas listagens; preenchido no detalhe e na criação.
  final List<Parcela> parcelas;
}

class ResultadoCancelamento {
  const ResultadoCancelamento({
    required this.id,
    required this.parcelasRemovidas,
    required this.parcelasPreservadas,
  });
  factory ResultadoCancelamento.fromJson(Json j) => ResultadoCancelamento(
    id: j['id'] as int,
    parcelasRemovidas: j['parcelas_removidas'] as int,
    parcelasPreservadas: j['parcelas_preservadas'] as int,
  );

  final int id;
  final int parcelasRemovidas;
  final int parcelasPreservadas;
}

class BalancoMensal {
  const BalancoMensal({
    required this.competencia,
    required this.totalReceitas,
    required this.totalGastos,
    required this.saldo,
  });
  factory BalancoMensal.fromJson(Json j) => BalancoMensal(
    competencia: j['competencia'] as String,
    totalReceitas: j['total_receitas'] as String,
    totalGastos: j['total_gastos'] as String,
    saldo: j['saldo'] as String,
  );

  final String competencia;
  final String totalReceitas;
  final String totalGastos;
  final String saldo;
}

class GastoCategoria {
  const GastoCategoria({
    required this.categoriaId,
    required this.categoriaNome,
    required this.total,
  });
  factory GastoCategoria.fromJson(Json j) => GastoCategoria(
    categoriaId: j['categoria_id'] as int,
    categoriaNome: j['categoria_nome'] as String,
    total: j['total'] as String,
  );

  final int categoriaId;
  final String categoriaNome;
  final String total;
}

class GastosPorCategoria {
  const GastosPorCategoria({required this.competencia, required this.itens});
  factory GastosPorCategoria.fromJson(Json j) => GastosPorCategoria(
    competencia: j['competencia'] as String,
    itens: [
      for (final i in j['itens'] as List<dynamic>)
        GastoCategoria.fromJson(i as Json),
    ],
  );

  final String competencia;
  final List<GastoCategoria> itens;
}

class ParcelaAtiva {
  const ParcelaAtiva({
    required this.transacaoId,
    required this.parcelamentoId,
    required this.parcelamentoDescricao,
    required this.numeroParcela,
    required this.numParcelasTotal,
    required this.competencia,
    required this.valor,
    required this.contaId,
    required this.contaNome,
    required this.categoriaId,
    required this.categoriaNome,
  });
  factory ParcelaAtiva.fromJson(Json j) => ParcelaAtiva(
    transacaoId: j['transacao_id'] as int,
    parcelamentoId: j['parcelamento_id'] as int,
    parcelamentoDescricao: j['parcelamento_descricao'] as String,
    numeroParcela: j['numero_parcela'] as int,
    numParcelasTotal: j['num_parcelas_total'] as int,
    competencia: j['competencia'] as String,
    valor: j['valor'] as String,
    contaId: j['conta_id'] as int,
    contaNome: j['conta_nome'] as String,
    categoriaId: j['categoria_id'] as int,
    categoriaNome: j['categoria_nome'] as String,
  );

  final int transacaoId;
  final int parcelamentoId;
  final String parcelamentoDescricao;
  final int numeroParcela;
  final int numParcelasTotal;
  final String competencia;
  final String valor;
  final int contaId;
  final String contaNome;
  final int categoriaId;
  final String categoriaNome;
}
