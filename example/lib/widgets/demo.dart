import 'package:flutter/material.dart';

/// An example page: intro text and demo blocks.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.intro, required this.children});

  final String intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Text(intro, style: Theme.of(context).textTheme.bodyLarge),
      ),
      const SizedBox(height: 24),
      ...children,
    ],
  );
}

/// One use case: explanation, the widget running and its code.
class DemoBlock extends StatelessWidget {
  const DemoBlock({
    super.key,
    required this.title,
    this.description,
    this.code,
    required this.child,
  });

  final String title;
  final String? description;
  final String? code;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          if (description != null) ...[
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                description!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: child),
          if (code != null) _CodeView(code!.trim()),
        ],
      ),
    );
  }
}

class _CodeView extends StatefulWidget {
  const _CodeView(this.code);

  final String code;

  @override
  State<_CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<_CodeView> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _open = !_open),
          icon: Icon(_open ? Icons.expand_less : Icons.code, size: 18),
          label: Text(_open ? 'Hide code' : 'Show code'),
        ),
        if (_open)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}
