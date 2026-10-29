import 'dart:convert';

import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sample_ads.dart';
import '../widgets/demo.dart';

/// Banners bundled inside the app: no server needed, useful as an offline
/// fallback or for fixed campaigns.
class LocalJsonPage extends StatefulWidget {
  const LocalJsonPage({super.key});

  @override
  State<LocalJsonPage> createState() => _LocalJsonPageState();
}

class _LocalJsonPageState extends State<LocalJsonPage> {
  static const _path = 'assets/ads/local_ads.json';
  late final Future<(String, AdConfig)> _config = _load();

  Future<(String, AdConfig)> _load() async {
    final text = await rootBundle.loadString(_path);
    // No baseUri: "assets/..." paths stay as Flutter assets.
    return (text, AdConfig.fromJson(jsonDecode(text) as Map<String, dynamic>));
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      intro:
          'The same JSON format can also be read from the app assets. Images '
          'with an "assets/..." path are loaded as Flutter assets, without '
          'any network request.',
      children: [
        DemoBlock(
          title: 'Read the JSON and show a placement',
          description:
              'The 728x90 or the 300x250 is picked depending on the available '
              'width (try shrinking the window).',
          code: '''
// pubspec.yaml
flutter:
  assets:
    - assets/ads/
    - assets/banners/

// code
final text = await rootBundle.loadString('assets/ads/local_ads.json');
final config = AdConfig.fromJson(jsonDecode(text));

for (final ad in config['offline']!.activeAds(DateTime.now()))
  CustomAd(ad: ad, format: config['offline']!.format)''',
          child: FutureBuilder(
            future: _config,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final (text, config) = snapshot.data!;
              final placement = config['offline']!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final ad in placement.activeAds(DateTime.now()))
                    CustomAd(ad: ad, format: placement.format),
                  const SizedBox(height: 24),
                  const Text('JSON content:'),
                  const SizedBox(height: 8),
                  _JsonView(text),
                ],
              );
            },
          ),
        ),
        DemoBlock(
          title: 'A single ad with AdData.fromJson',
          description:
              'For a standalone ad (for example, one returned by an API) no '
              'placement is needed.',
          code: '''
final ad = AdData.fromJson({
  'id': 'local-asset',
  'alt': 'Local banner',
  'targetUrl': 'https://example.com/local',
  'assets': [
    {'url': 'assets/banners/local-300x250.png', 'width': 300, 'height': 250},
  ],
});

CustomAd(ad: ad, format: AdFormat.creative)''',
          child: CustomAd(
            ad: AdData.fromJson(localCreativeAd.toJson()),
            format: AdFormat.creative,
          ),
        ),
        const DemoBlock(
          title: 'Relative paths in remote JSONs',
          description:
              'When the JSON comes from a URL (RemoteAdSource), relative paths '
              'are resolved against that URL. To do the same by hand, pass '
              'baseUri.',
          code: '''
final url = Uri.parse('https://cdn.client.com/ads/ads.json');
final config = AdConfig.fromJson(json, baseUri: url);
// "banners/x.png" -> "https://cdn.client.com/ads/banners/x.png"''',
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _JsonView extends StatelessWidget {
  const _JsonView(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: SelectableText(
      text.trim(),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
    ),
  );
}
