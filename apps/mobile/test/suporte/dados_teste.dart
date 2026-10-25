import 'package:controle_gastos/api/modelos.dart';

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
    parcelamentos: [
      Parcelamento(
        id: 5,
        descricao: 'Notebook',
        valorTotal: '3600.00',
        numParcelas: 12,
        primeiraParcela: mesAtual,
        contaId: 1,
        categoriaId: 11,
        status: StatusParcelamento.ativo,
      ),
    ],
  );
}
