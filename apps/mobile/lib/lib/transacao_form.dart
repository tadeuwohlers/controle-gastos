import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/lib/competencia.dart';
import 'package:controle_gastos/lib/dinheiro.dart';

enum CampoForm { valor, descricao, competencia, conta, categoria, numParcelas }

class EstadoForm {
  const EstadoForm({
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.competencia,
    this.contaId,
    this.categoriaId,
  });

  final TipoTransacao tipo;
  final String valor;
  final String descricao;
  final String competencia;
  final int? contaId;
  final int? categoriaId;
}

/// Campos prontos para a API: `valor` já em "1234.56".
class PayloadTransacao {
  const PayloadTransacao({
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.competencia,
    required this.contaId,
    required this.categoriaId,
  });

  final TipoTransacao tipo;
  final String valor;
  final String descricao;
  final String competencia;
  final int contaId;
  final int categoriaId;
}

class ResultadoValidacao {
  const ResultadoValidacao.ok(PayloadTransacao this.payload) : erros = const {};
  const ResultadoValidacao.erros(this.erros) : payload = null;

  final PayloadTransacao? payload;
  final Map<CampoForm, String> erros;

  bool get ok => payload != null;
}

/// Valida no cliente antes de enviar; a API continua sendo a fonte da verdade.
ResultadoValidacao validar(EstadoForm e) {
  final erros = <CampoForm, String>{};
  final valor = parseValorBR(e.valor);
  if (valor == null) {
    erros[CampoForm.valor] =
        'Informe um valor maior que zero, com até 2 casas decimais.';
  }
  if (e.descricao.trim().isEmpty) {
    erros[CampoForm.descricao] = 'Informe a descrição.';
  }
  if (!valida(e.competencia)) {
    erros[CampoForm.competencia] = 'Informe a Competência.';
  }
  if (e.contaId == null) erros[CampoForm.conta] = 'Escolha a Conta.';
  if (e.categoriaId == null) {
    erros[CampoForm.categoria] = 'Escolha a Categoria.';
  }
  if (erros.isNotEmpty || valor == null) return ResultadoValidacao.erros(erros);
  return ResultadoValidacao.ok(
    PayloadTransacao(
      tipo: e.tipo,
      valor: valor,
      descricao: e.descricao.trim(),
      competencia: e.competencia,
      contaId: e.contaId!,
      categoriaId: e.categoriaId!,
    ),
  );
}
