import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/api/repositorio.dart';

/// Repositório em memória para os testes de widget. Registra as mutações em
/// [chamadas] e pode falhar a próxima mutação via [falharProxima].
class FakeRepositorio implements Repositorio {
  FakeRepositorio({
    List<Conta>? contas,
    List<Categoria>? categorias,
    List<Transacao>? transacoes,
    List<Parcelamento>? parcelamentos,
    Map<String, BalancoMensal>? balancos,
    Map<String, GastosPorCategoria>? gastos,
    List<ParcelaAtiva>? parcelasAtivasLista,
  }) : balancos = {...?balancos},
       gastos = {...?gastos},
       parcelasAtivasLista = [...?parcelasAtivasLista],
       _contas = [...?contas],
       _categorias = [...?categorias],
       _transacoes = [...?transacoes],
       _parcelamentos = [...?parcelamentos];

  final List<Conta> _contas;
  final List<Categoria> _categorias;
  final List<Transacao> _transacoes;
  final List<Parcelamento> _parcelamentos;
  int _proximoId = 1000;

  final List<String> chamadas = [];

  /// Relatórios por Competência; mês sem entrada devolve tudo zerado.
  final Map<String, BalancoMensal> balancos;
  final Map<String, GastosPorCategoria> gastos;
  final List<ParcelaAtiva> parcelasAtivasLista;

  /// Cada leitura de relatório: `balanco(2026-10)`, `gastos(2026-10)`,
  /// `parcelasAtivas`.
  final List<String> leituras = [];

  /// Relatórios (`balanco`, `gastos`, `parcelasAtivas`) cuja próxima leitura
  /// falha com erro de rede.
  final Set<String> falhasDeLeitura = {};

  /// Roda depois de cada mutação bem-sucedida (para mudar os relatórios).
  void Function()? aoMutar;

  /// Falha a próxima mutação (e só ela) com esta exceção.
  ApiException? falharProxima;

  void _mutar(String chamada) {
    final falha = falharProxima;
    if (falha != null) {
      falharProxima = null;
      throw falha;
    }
    chamadas.add(chamada);
    aoMutar?.call();
  }

  void _ler(String relatorio, String leitura) {
    leituras.add(leitura);
    if (falhasDeLeitura.remove(relatorio)) throw semRede();
  }

  static ApiException erro(int status, String detail) =>
      ApiException(status: status, corpo: {'detail': detail});

  static ApiException semRede() => ApiException(causa: 'sem rede');

  @override
  Future<List<Conta>> contas() async => [..._contas];

  @override
  Future<Conta> criarConta(String nome) async {
    _mutar('criarConta($nome)');
    if (_contas.any((c) => c.nome == nome)) throw erro(409, 'Conta já existe.');
    final c = Conta(id: _proximoId++, nome: nome);
    _contas.add(c);
    return c;
  }

  @override
  Future<List<Categoria>> categorias({TipoTransacao? tipo}) async => [
    for (final c in _categorias)
      if (tipo == null || c.tipo == tipo) c,
  ];

  @override
  Future<Categoria> criarCategoria(String nome, TipoTransacao tipo) async {
    _mutar('criarCategoria($nome, ${tipo.name})');
    if (_categorias.any((c) => c.nome == nome)) {
      throw erro(409, 'Categoria já existe.');
    }
    final c = Categoria(id: _proximoId++, nome: nome, tipo: tipo);
    _categorias.add(c);
    return c;
  }

  @override
  Future<List<Transacao>> transacoes({
    required String competencia,
    int? contaId,
    int? categoriaId,
  }) async => [
    for (final t in _transacoes)
      if (t.competencia == competencia &&
          (contaId == null || t.contaId == contaId) &&
          (categoriaId == null || t.categoriaId == categoriaId))
        t,
  ];

  @override
  Future<Transacao> criarTransacao({
    required TipoTransacao tipo,
    required String valor,
    required String descricao,
    required String competencia,
    required int contaId,
    required int categoriaId,
  }) async {
    _mutar(
      'criarTransacao(${tipo.name}, $valor, $descricao, $competencia, '
      '$contaId, $categoriaId)',
    );
    final t = Transacao(
      id: _proximoId++,
      tipo: tipo,
      valor: valor,
      descricao: descricao,
      competencia: competencia,
      contaId: contaId,
      categoriaId: categoriaId,
    );
    _transacoes.add(t);
    return t;
  }

  @override
  Future<Transacao> atualizarTransacao(
    int id, {
    required String valor,
    required String descricao,
    required String competencia,
    required int contaId,
    required int categoriaId,
  }) async {
    _mutar(
      'atualizarTransacao($id, $valor, $descricao, $competencia, '
      '$contaId, $categoriaId)',
    );
    final i = _transacoes.indexWhere((t) => t.id == id);
    final antiga = _transacoes[i];
    final nova = Transacao(
      id: id,
      tipo: antiga.tipo,
      valor: valor,
      descricao: descricao,
      competencia: competencia,
      contaId: contaId,
      categoriaId: categoriaId,
    );
    _transacoes[i] = nova;
    return nova;
  }

  @override
  Future<void> excluirTransacao(int id) async {
    _mutar('excluirTransacao($id)');
    _transacoes.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<Parcelamento>> parcelamentos({
    StatusParcelamento? status,
  }) async => [
    for (final p in _parcelamentos)
      if (status == null || p.status == status) p,
  ];

  @override
  Future<BalancoMensal> balancoMensal(String competencia) async {
    _ler('balanco', 'balanco($competencia)');
    return balancos[competencia] ??
        BalancoMensal(
          competencia: competencia,
          totalReceitas: '0.00',
          totalGastos: '0.00',
          saldo: '0.00',
        );
  }

  @override
  Future<GastosPorCategoria> gastosPorCategoria(String competencia) async {
    _ler('gastos', 'gastos($competencia)');
    return gastos[competencia] ??
        GastosPorCategoria(competencia: competencia, itens: const []);
  }

  @override
  Future<List<ParcelaAtiva>> parcelasAtivas() async {
    _ler('parcelasAtivas', 'parcelasAtivas');
    return [...parcelasAtivasLista];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} não usado nesta fatia',
  );
}
