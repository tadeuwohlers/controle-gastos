import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/lib/competencia.dart' as comp;

import 'app_teste.dart';
import 'fake_repositorio.dart';

const nubank = Conta(id: 1, nome: 'Nubank');
const itau = Conta(id: 2, nome: 'Itaú');

const alimentacao = Categoria(
  id: 10,
  nome: 'Alimentação',
  tipo: TipoTransacao.gasto,
);
const transporte = Categoria(
  id: 11,
  nome: 'Transporte',
  tipo: TipoTransacao.gasto,
);
const salario = Categoria(id: 20, nome: 'Salário', tipo: TipoTransacao.receita);

/// Duas Transações Avulsas e uma Parcela (2/12 do Parcelamento 5), todas na
/// Competência corrente.
FakeRepositorio repoComDados() {
  return FakeRepositorio(
    contas: [nubank, itau],
    categorias: [alimentacao, transporte, salario],
    transacoes: [
      Transacao(
        id: 1,
        tipo: TipoTransacao.gasto,
        valor: '49.90',
        descricao: 'Supermercado',
        competencia: mesAtual,
        contaId: 1,
        categoriaId: 10,
      ),
      Transacao(
        id: 2,
        tipo: TipoTransacao.receita,
        valor: '5000.00',
        descricao: 'Salário de outubro',
        competencia: mesAtual,
        contaId: 2,
        categoriaId: 20,
      ),
      Transacao(
        id: 3,
        tipo: TipoTransacao.gasto,
        valor: '300.00',
        descricao: 'Notebook',
        competencia: mesAtual,
        contaId: 1,
        categoriaId: 11,
        parcelamentoId: 5,
        numeroParcela: 2,
      ),
    ],
    parcelamentos: [parcelamentoDetalhado()],
  );
}

/// Parcelamento 5 (4× de R$ 300,00, Notebook): uma Parcela passada, a do mês
/// corrente e duas futuras. Cancelado agora: removeria 2 e preservaria 2.
Parcelamento parcelamentoDetalhado({
  int id = 5,
  StatusParcelamento status = StatusParcelamento.ativo,
}) {
  return Parcelamento(
    id: id,
    descricao: 'Notebook',
    valorTotal: '1200.00',
    numParcelas: 4,
    primeiraParcela: comp.deslocar(mesAtual, -1),
    contaId: 1,
    categoriaId: 11,
    status: status,
    parcelas: [
      for (var n = 1; n <= 4; n++)
        Parcela(
          id: 40 + n,
          numeroParcela: n,
          competencia: comp.deslocar(mesAtual, n - 2),
          valor: '300.00',
        ),
    ],
  );
}
