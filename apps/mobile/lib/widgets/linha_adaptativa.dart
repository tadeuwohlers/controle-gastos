import 'package:flutter/material.dart';

/// Item de lista que se adapta à fonte grande. Com fonte normal é um
/// `ListTile`; a partir de 1,3× o valor (trailing) desce para baixo do título,
/// porque ao lado dele o `ListTile` espreme o título numa coluna estreita e
/// quebra as palavras no meio.
class LinhaAdaptativa extends StatelessWidget {
  const LinhaAdaptativa({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.tileColor,
    this.tresLinhas = false,
  });

  final Widget titulo;
  final Widget? subtitulo;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? tileColor;

  /// Subtítulo com mais de uma linha (só vale no layout normal).
  final bool tresLinhas;

  static const _limite = 1.3;

  static bool fonteGrande(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(16) / 16 >= _limite;

  @override
  Widget build(BuildContext context) {
    if (!fonteGrande(context)) {
      return ListTile(
        leading: leading,
        title: titulo,
        subtitle: subtitulo,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
        tileColor: tileColor,
        isThreeLine: tresLinhas,
      );
    }

    final texto = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: Material(
          color: tileColor ?? Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle.merge(
                            style: texto.bodyLarge,
                            child: titulo,
                          ),
                          if (trailing != null) ...[
                            const SizedBox(height: 4),
                            trailing!,
                          ],
                          if (subtitulo != null) ...[
                            const SizedBox(height: 4),
                            DefaultTextStyle.merge(
                              style: texto.bodyMedium,
                              child: subtitulo!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
