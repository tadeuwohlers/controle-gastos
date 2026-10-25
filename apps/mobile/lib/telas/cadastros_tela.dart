import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:controle_gastos/api/api_client.dart';
import 'package:controle_gastos/api/modelos.dart';
import 'package:controle_gastos/estado/dados_provider.dart';
import 'package:controle_gastos/estado/invalidacao.dart';
import 'package:controle_gastos/estado/providers.dart';
import 'package:controle_gastos/widgets/async_vista.dart';
import 'package:controle_gastos/widgets/aviso_com_retry.dart';
import 'package:controle_gastos/widgets/erro_inline.dart';

class CadastrosTela extends ConsumerWidget {
  const CadastrosTela({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contas = ref.watch(contasProvider);
    final categorias = ref.watch(categoriasProvider);
    final combinado = contas.hasValue && categorias.hasValue
        ? AsyncData((contas.requireValue, categorias.requireValue))
        : (contas.hasError
              ? AsyncError<(List<Conta>, List<Categoria>)>(
                  contas.error!,
                  contas.stackTrace!,
                )
              : (categorias.hasError
                    ? AsyncError<(List<Conta>, List<Categoria>)>(
                        categorias.error!,
                        categorias.stackTrace!,
                      )
                    : const AsyncLoading<(List<Conta>, List<Categoria>)>()));

    return AsyncVista<(List<Conta>, List<Categoria>)>(
      valor: combinado,
      onTentar: () {
        ref.invalidate(contasProvider);
        ref.invalidate(categoriasProvider);
      },
      construir: (context, dados) {
        final (listaContas, listaCategorias) = dados;
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(contasProvider);
            ref.invalidate(categoriasProvider);
            await ref.read(contasProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _Secao(
                titulo: 'Contas',
                vazio:
                    'Nenhuma Conta ainda. Uma Conta é onde o dinheiro '
                    'entra ou sai, como um banco ou um cartão.',
                itens: [for (final c in listaContas) c.nome],
              ),
              const _NovaConta(),
              const SizedBox(height: 24),
              _Secao(
                titulo: 'Categorias de Gasto',
                vazio: 'Nenhuma Categoria de Gasto ainda.',
                itens: [
                  for (final c in listaCategorias)
                    if (c.tipo == TipoTransacao.gasto) c.nome,
                ],
              ),
              const SizedBox(height: 16),
              _Secao(
                titulo: 'Categorias de Receita',
                vazio: 'Nenhuma Categoria de Receita ainda.',
                itens: [
                  for (final c in listaCategorias)
                    if (c.tipo == TipoTransacao.receita) c.nome,
                ],
              ),
              const _NovaCategoria(),
            ],
          ),
        );
      },
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.titulo,
    required this.vazio,
    required this.itens,
  });

  final String titulo;
  final String vazio;
  final List<String> itens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (itens.isEmpty)
          Text(vazio)
        else
          for (final nome in itens)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(nome),
            ),
      ],
    );
  }
}

/// Estado comum dos mini-formulários de criação: campo de nome, envio,
/// erro inline (`409`/`422`) e aviso com retry para rede e `5xx`.
mixin _Envio<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final nome = TextEditingController();
  String? erro;
  bool falhaRede = false;
  bool enviando = false;

  @override
  void dispose() {
    nome.dispose();
    super.dispose();
  }

  Future<void> criar(Future<void> Function(String nome) chamada) async {
    final texto = nome.text.trim();
    if (texto.isEmpty) {
      setState(() {
        erro = 'Informe o nome.';
        falhaRede = false;
      });
      return;
    }
    setState(() {
      enviando = true;
      erro = null;
      falhaRede = false;
    });
    try {
      await chamada(texto);
      if (!mounted) return;
      nome.clear();
      setState(() => enviando = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        enviando = false;
        falhaRede = e.ehRedeOu5xx;
        erro = e.ehRedeOu5xx ? null : e.mensagem;
      });
    }
  }

  Widget avisos(Future<void> Function() tentar) => Column(
    children: [
      if (erro != null) ...[ErroInline(erro!), const SizedBox(height: 8)],
      if (falhaRede) ...[
        AvisoComRetry(onTentar: tentar),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _NovaConta extends ConsumerStatefulWidget {
  const _NovaConta();

  @override
  ConsumerState<_NovaConta> createState() => _NovaContaState();
}

class _NovaContaState extends ConsumerState<_NovaConta> with _Envio {
  Future<void> _enviar() => criar((n) async {
    await ref.read(repositorioProvider).criarConta(n);
    invalidarAposConta(ref);
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          avisos(_enviar),
          TextField(
            controller: nome,
            decoration: const InputDecoration(labelText: 'Nova Conta'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _enviar(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: enviando ? null : _enviar,
              child: const Text('Adicionar Conta'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NovaCategoria extends ConsumerStatefulWidget {
  const _NovaCategoria();

  @override
  ConsumerState<_NovaCategoria> createState() => _NovaCategoriaState();
}

class _NovaCategoriaState extends ConsumerState<_NovaCategoria> with _Envio {
  TipoTransacao tipo = TipoTransacao.gasto;

  Future<void> _enviar() => criar((n) async {
    await ref.read(repositorioProvider).criarCategoria(n, tipo);
    invalidarAposCategoria(ref);
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avisos(_enviar),
          SegmentedButton<TipoTransacao>(
            segments: const [
              ButtonSegment(value: TipoTransacao.gasto, label: Text('Gasto')),
              ButtonSegment(
                value: TipoTransacao.receita,
                label: Text('Receita'),
              ),
            ],
            selected: {tipo},
            onSelectionChanged: (s) => setState(() => tipo = s.first),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nome,
            decoration: const InputDecoration(labelText: 'Nova Categoria'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _enviar(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: enviando ? null : _enviar,
              child: const Text('Adicionar Categoria'),
            ),
          ),
        ],
      ),
    );
  }
}
