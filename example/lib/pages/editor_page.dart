import 'dart:convert';

import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sample_ads.dart';

enum _StylePreset { theme, dark, vibrant }

/// Builds an ad with a live preview and generates the JSON for the
/// client's server.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  static const _accents = [
    Colors.indigo,
    Colors.teal,
    Colors.deepOrange,
    Colors.pink,
    Colors.green,
  ];

  final _placement = TextEditingController(text: 'home_top');
  final _id = TextEditingController(text: 'my-banner');
  final _title = TextEditingController(text: 'Summer sale: 50% off');
  final _description = TextEditingController(
    text: 'Say in one line why people should click.',
  );
  final _image = TextEditingController(text: bannerUrl('summer-728x90.png'));
  final _width = TextEditingController(text: '728');
  final _height = TextEditingController(text: '90');
  final _cta = TextEditingController(text: 'Learn more');
  final _url = TextEditingController(text: 'https://example.com');
  final _sponsor = TextEditingController(text: 'My brand');

  AdFormat _format = AdFormat.creative;
  _StylePreset _preset = _StylePreset.theme;
  Color _accent = _accents.first;
  bool _dismissible = false;

  List<TextEditingController> get _controllers => [
    _placement,
    _id,
    _title,
    _description,
    _image,
    _width,
    _height,
    _cta,
    _url,
    _sponsor,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String? _valueOf(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  bool get _isCreative => _format == AdFormat.creative;

  AdData get _ad {
    final image = _valueOf(_image);
    final width = double.tryParse(_width.text);
    final height = double.tryParse(_height.text);
    final hasSize = width != null && height != null && width > 0 && height > 0;
    return AdData(
      id: _valueOf(_id) ?? 'no-id',
      title: _valueOf(_title) ?? 'Untitled',
      description: _isCreative ? null : _valueOf(_description),
      imageUrl: _isCreative ? null : image,
      assets: _isCreative && image != null && hasSize
          ? [AdAsset(url: image, width: width, height: height)]
          : const [],
      ctaLabel: _valueOf(_cta) ?? 'Learn more',
      targetUrl: _valueOf(_url),
      sponsor: _isCreative ? null : _valueOf(_sponsor),
    );
  }

  AdStyle? get _style => switch (_preset) {
    _ when _isCreative => null,
    _StylePreset.theme => AdStyle(
      accentColor: _accent,
      onAccentColor: Colors.white,
    ),
    _StylePreset.dark => AdStyle.dark(accent: _accent),
    _StylePreset.vibrant => AdStyle.vibrant(_accent),
  };

  /// JSON in the same format the client publishes.
  Map<String, dynamic> _configJson(AdData ad) {
    final adJson = ad.toJson();
    if (_isCreative) {
      // On image banners the title is the alt text.
      adJson
        ..['alt'] = adJson.remove('title')
        ..remove('ctaLabel')
        ..remove('badge');
    }
    return {
      'version': 1,
      'placements': {
        _valueOf(_placement) ?? 'placement': {
          if (!_isCreative) 'format': _format.name,
          if (_dismissible) 'dismissible': true,
          'ads': [adJson],
        },
      },
    };
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      keyboardType: number ? TextInputType.number : null,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final form = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DropdownButtonFormField<AdFormat>(
          initialValue: _format,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Format',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final f in AdFormat.values)
              DropdownMenuItem(
                value: f,
                child: Text(
                  f == AdFormat.creative ? 'creative (your own image)' : f.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (f) => setState(() => _format = f!),
        ),
        const SizedBox(height: 16),
        _field('Placement', _placement),
        _field('ID', _id),
        _field(_isCreative ? 'Alt text' : 'Title', _title),
        if (!_isCreative) _field('Description', _description),
        _field('Image URL', _image),
        if (_isCreative)
          Row(
            children: [
              Expanded(child: _field('Width (px)', _width, number: true)),
              const SizedBox(width: 12),
              Expanded(child: _field('Height (px)', _height, number: true)),
            ],
          ),
        if (!_isCreative) _field('Button text', _cta),
        _field('Target URL', _url),
        if (!_isCreative) ...[
          _field('Advertiser', _sponsor),
          const SizedBox(height: 4),
          SegmentedButton<_StylePreset>(
            segments: const [
              ButtonSegment(value: _StylePreset.theme, label: Text('Theme')),
              ButtonSegment(value: _StylePreset.dark, label: Text('Dark')),
              ButtonSegment(
                value: _StylePreset.vibrant,
                label: Text('Vibrant'),
              ),
            ],
            selected: {_preset},
            onSelectionChanged: (s) => setState(() => _preset = s.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final color in _accents)
                ChoiceChip(
                  label: const SizedBox.shrink(),
                  avatar: CircleAvatar(backgroundColor: color),
                  labelPadding: EdgeInsets.zero,
                  selected: _accent == color,
                  onSelected: (_) => setState(() => _accent = color),
                ),
            ],
          ),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Allow closing'),
          value: _dismissible,
          onChanged: (v) => setState(() => _dismissible = v),
        ),
        if (_isCreative)
          Text(
            'Tip: try ${bannerUrl('course-300x250.png')} at 300x250.',
            style: textTheme.bodySmall,
          ),
      ],
    );

    final ad = _ad;
    final json = const JsonEncoder.withIndent('  ').convert(_configJson(ad));
    final preview = ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Preview', style: textTheme.titleMedium),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: CustomAd(
            // The key recreates the ad (and reopens it if closed) when editing.
            key: ValueKey(
              Object.hash(ad, _format, _dismissible, _preset, _accent),
            ),
            ad: ad,
            format: _format,
            style: _style,
            dismissible: _dismissible,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Text(
                "JSON for the client's server",
                style: textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('JSON copied')));
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            json,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 860
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: form),
                const VerticalDivider(width: 1),
                Expanded(child: preview),
              ],
            )
          : Column(
              children: [
                Expanded(child: preview),
                const Divider(height: 1),
                Expanded(child: form),
              ],
            ),
    );
  }
}
