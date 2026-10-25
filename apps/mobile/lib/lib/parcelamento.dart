import 'package:controle_gastos/lib/competencia.dart';
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/lib/transacao_form.dart';

/// Campos prontos para `POST /parcelamentos`: `valorTotal` já em "1234.56".
class PayloadParcelamento {
  const PayloadParcelamento({
    required this.descricao,
    required this.valorTotal,
    required this.numParcelas,
    required this.primeiraParcela,
    required this.contaId,
    required this.categoriaId,
  });

  final String descricao;
  final String valorTotal;
  final int numParcelas;
  final String primeiraParcela;
  final int contaId;
  final int categoriaId;
}

class ResultadoParcelado {
  const ResultadoParcelado.ok(PayloadParcelamento this.payload)
    : erros = const {};
  const ResultadoParcelado.erros(this.erros) : payload = null;

  final PayloadParcelamento? payload;
  final Map<CampoForm, String> erros;

  bool get ok => payload != null;
}

/// No modo Parcelado, `valor` do [EstadoForm] é o valor total e `competencia`
/// é a primeira parcela. O tipo não entra: Parcelamento só existe para Gasto.
ResultadoParcelado validarParcelado(EstadoForm e, String numParcelas) {
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
    erros[CampoForm.competencia] = 'Informe a primeira parcela.';
  }
  if (e.contaId == null) {
    erros[CampoForm.conta] = 'Escolha a Conta.';
  }
  if (e.categoriaId == null) {
    erros[CampoForm.categoria] = 'Escolha a Categoria.';
  }
  final texto = numParcelas.trim();
  final n = RegExp(r'^\d{1,4}$').hasMatch(texto) ? int.parse(texto) : 0;
  if (n < 2) {
    erros[CampoForm.numParcelas] =
        'Informe um número inteiro de parcelas, no mínimo 2.';
  }
  if (erros.isNotEmpty || valor == null) return ResultadoParcelado.erros(erros);
  return ResultadoParcelado.ok(
    PayloadParcelamento(
      descricao: e.descricao.trim(),
      valorTotal: valor,
      numParcelas: n,
      primeiraParcela: e.competencia,
      contaId: e.contaId!,
      categoriaId: e.categoriaId!,
    ),
  );
}

/// Prévia do cancelamento: as Parcelas com Competência depois do mês corrente
/// serão removidas; a do mês atual e as passadas ficam.
({int removidas, int preservadas}) previaCancelamento(
  List<String> competencias, {
  String? atual,
}) {
  final mes = atual ?? competenciaAtual();
  final removidas = competencias.where((c) => comparar(c, mes) > 0).length;
  return (removidas: removidas, preservadas: competencias.length - removidas);
}

String plural(int n, String singular, String plural) =>
    '$n ${n == 1 ? singular : plural}';
