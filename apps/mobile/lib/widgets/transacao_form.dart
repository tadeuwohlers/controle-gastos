import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/dados_provider.dart';
import 'package:controle_gastos/estado/invalidacao.dart';
import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/estado/ultima_conta.dart';
import 'package:controle_gastos/lib/dinheiro.dart';
import 'package:controle_gastos/lib/transacao_form.dart';
import 'package:controle_gastos/widgets/aviso_com_retry.dart';
import 'package:controle_gastos/widgets/erro_inline.dart';
import 'package:controle_gastos/widgets/seletor_mes.dart';

/// Formulário de criar (ou editar, se [editar] vier) uma Transação Avulsa.
/// [aoFechar] é chamado depois de "Salvar"; "Salvar e nova" mantém o
/// formulário aberto.
class TransacaoForm extends ConsumerStatefulWidget {
  const TransacaoForm({
    super.key,
    required this.competencia,
    this.editar,
    required this.aoFechar,
  });

  /// Competência inicial ao criar.
  final String competencia;
  final Transacao? editar;
  final VoidCallback aoFechar;

  @override
  ConsumerState<TransacaoForm> createState() => _TransacaoFormState();
}

class _TransacaoFormState extends ConsumerState<TransacaoForm> {
  late TipoTransacao _tipo;
  late String _competencia;
  late final TextEditingController _valor;
  late final TextEditingController _descricao;
  final _foco = FocusNode();
  int? _contaId;
  int? _categoriaId;
  Map<CampoForm, String> _erros = const {};
  String? _erroApi;
  bool _falhaRede = false;
  bool _enviando = false;
  bool _contaPadraoResolvida = false;

  bool get _editando => widget.editar != null;

  @override
  void initState() {
    super.initState();
    final t = widget.editar;
    _tipo = t?.tipo ?? TipoTransacao.gasto;
    _competencia = t?.competencia ?? widget.competencia;
    _valor = TextEditingController(
      text: t == null ? '' : paraEntradaBR(t.valor),
    );
    _descricao = TextEditingController(text: t?.descricao ?? '');
    _contaId = t?.contaId;
    _categoriaId = t?.categoriaId;
  }

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    _foco.dispose();
    super.dispose();
  }

  /// Última Conta usada, só ao criar e só se o usuário ainda não escolheu.
  Future<void> _resolverContaPadrao(List<Conta> contas) async {
    _contaPadraoResolvida = true;
    if (_editando || _contaId != null || contas.isEmpty) return;
    final id = await ref.read(ultimaContaProvider).ler(contas.map((c) => c.id));
    if (mounted && _contaId == null && id != null) {
      setState(() => _contaId = id);
    }
  }

  Future<void> _salvar({required bool eNova}) async {
    final r = validar(
      EstadoForm(
        tipo: _tipo,
        valor: _valor.text,
        descricao: _descricao.text,
        competencia: _competencia,
        contaId: _contaId,
        categoriaId: _categoriaId,
      ),
    );
    if (!r.ok) {
      setState(() {
        _erros = r.erros;
        _erroApi = null;
        _falhaRede = false;
      });
      return;
    }
    final p = r.payload!;
    setState(() {
      _erros = const {};
      _erroApi = null;
      _falhaRede = false;
      _enviando = true;
    });
    final repo = ref.read(repositorioProvider);
    try {
      if (_editando) {
        await repo.atualizarTransacao(
          widget.editar!.id,
          valor: p.valor,
          descricao: p.descricao,
          competencia: p.competencia,
          contaId: p.contaId,
          categoriaId: p.categoriaId,
        );
      } else {
        await repo.criarTransacao(
          tipo: p.tipo,
          valor: p.valor,
          descricao: p.descricao,
          competencia: p.competencia,
          contaId: p.contaId,
          categoriaId: p.categoriaId,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _falhaRede = e.ehRedeOu5xx;
        _erroApi = e.ehRedeOu5xx ? null : e.mensagem;
      });
      return;
    }
    if (!mounted) return;
    invalidarAposTransacao(ref);
    await ref.read(ultimaContaProvider).salvar(p.contaId);
    if (!mounted) return;
    if (eNova) {
      // Mantém tipo, Conta e Competência; limpa valor e descrição.
      setState(() {
        _enviando = false;
        _valor.clear();
        _descricao.clear();
      });
      _foco.requestFocus();
    } else {
      widget.aoFechar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contas = ref.watch(contasProvider);
    final categorias = ref.watch(categoriasProvider);

    if (contas.hasError || categorias.hasError) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AvisoComRetry(
          onTentar: () {
            ref.invalidate(contasProvider);
            ref.invalidate(categoriasProvider);
          },
        ),
      );
    }
    if (!contas.hasValue || !categorias.hasValue) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final listaContas = contas.requireValue;
    if (!_contaPadraoResolvida) _resolverContaPadrao(listaContas);
    final listaCategorias = [
      for (final c in categorias.requireValue)
        if (c.tipo == _tipo) c,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _editando ? 'Editar transação' : 'Nova transação',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (_erroApi != null) ...[
            ErroInline(_erroApi!),
            const SizedBox(height: 12),
          ],
          if (_falhaRede) ...[
            AvisoComRetry(onTentar: () => _salvar(eNova: false)),
            const SizedBox(height: 12),
          ],
          if (_editando)
            Text(
              'Tipo: ${_tipo == TipoTransacao.gasto ? 'Gasto' : 'Receita'}',
              style: Theme.of(context).textTheme.bodyLarge,
            )
          else
            SegmentedButton<TipoTransacao>(
              segments: const [
                ButtonSegment(value: TipoTransacao.gasto, label: Text('Gasto')),
                ButtonSegment(
                  value: TipoTransacao.receita,
                  label: Text('Receita'),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() {
                _tipo = s.first;
                _categoriaId = null;
              }),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _valor,
            focusNode: _foco,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              errorText: _erros[CampoForm.valor],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descricao,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Descrição',
              errorText: _erros[CampoForm.descricao],
            ),
          ),
          const SizedBox(height: 12),
          SeletorMes(
            rotulo: 'Competência',
            competencia: _competencia,
            erro: _erros[CampoForm.competencia],
            onChanged: (c) => setState(() => _competencia = c),
          ),
          const SizedBox(height: 12),
          if (listaContas.isEmpty)
            _CriarInline(
              rotulo: 'Nova Conta',
              acao: 'Criar conta',
              erro: _erros[CampoForm.conta],
              criar: (nome) async {
                final c = await ref.read(repositorioProvider).criarConta(nome);
                invalidarAposConta(ref);
                setState(() => _contaId = c.id);
              },
            )
          else
            DropdownButtonFormField<int>(
              key: ValueKey('conta-$_contaId'),
              initialValue: _contaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Conta',
                errorText: _erros[CampoForm.conta],
              ),
              items: [
                for (final c in listaContas)
                  DropdownMenuItem(value: c.id, child: Text(c.nome)),
              ],
              onChanged: (v) => setState(() => _contaId = v),
            ),
          const SizedBox(height: 12),
          if (listaCategorias.isEmpty)
            _CriarInline(
              rotulo: 'Nova Categoria',
              acao: 'Criar categoria',
              erro: _erros[CampoForm.categoria],
              criar: (nome) async {
                final c = await ref
                    .read(repositorioProvider)
                    .criarCategoria(nome, _tipo);
                invalidarAposCategoria(ref);
                setState(() => _categoriaId = c.id);
              },
            )
          else
            DropdownButtonFormField<int>(
              key: ValueKey('categoria-$_tipo-$_categoriaId'),
              initialValue: _categoriaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Categoria',
                errorText: _erros[CampoForm.categoria],
              ),
              items: [
                for (final c in listaCategorias)
                  DropdownMenuItem(value: c.id, child: Text(c.nome)),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _enviando ? null : () => _salvar(eNova: false),
            child: const Text('Salvar'),
          ),
          if (!_editando) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _enviando ? null : () => _salvar(eNova: true),
              child: const Text('Salvar e nova'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Criação de Conta ou Categoria sem sair do formulário.
class _CriarInline extends StatefulWidget {
  const _CriarInline({
    required this.rotulo,
    required this.acao,
    required this.criar,
    this.erro,
  });

  final String rotulo;
  final String acao;
  final String? erro;
  final Future<void> Function(String nome) criar;

  @override
  State<_CriarInline> createState() => _CriarInlineState();
}

class _CriarInlineState extends State<_CriarInline> {
  final _nome = TextEditingController();
  String? _erro;
  bool _falhaRede = false;
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() {
        _erro = 'Informe o nome.';
        _falhaRede = false;
      });
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
      _falhaRede = false;
    });
    try {
      await widget.criar(nome);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _falhaRede = e.ehRedeOu5xx;
        _erro = e.ehRedeOu5xx ? null : e.mensagem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final erro = _erro ?? widget.erro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_falhaRede) AvisoComRetry(onTentar: _criar),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _nome,
                decoration: InputDecoration(
                  labelText: widget.rotulo,
                  errorText: erro,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.tonal(
                onPressed: _enviando ? null : _criar,
                child: Text(widget.acao),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
