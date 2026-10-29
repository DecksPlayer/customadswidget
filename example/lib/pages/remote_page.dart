import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

import '../widgets/demo.dart';

/// The main use case: the client publishes a JSON at their URL and each
/// AdSlot shows what belongs to it. See web/ads/ads.json.
class RemotePage extends StatefulWidget {
  const RemotePage({super.key, required this.source});

  final RemoteAdSource source;

  @override
  State<RemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<RemotePage> {
  // A source pointing to a missing URL, to show error handling.
  final _brokenSource = RemoteAdSource(Uri.base.resolve('ads/missing.json'));

  @override
  void dispose() {
    _brokenSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      intro:
          'Banners come from a JSON published by the client (here: '
          'web/ads/ads.json). Each AdSlot names a placement and the JSON '
          'decides its image, link and schedule. Banners are the client\'s own '
          'images, with one version per size.',
      children: [
        _SourceStatus(source: widget.source),
        const DemoBlock(
          title: 'Setup (once)',
          description:
              'RemoteAdSource downloads the JSON and refreshes it every 5 '
              'minutes. It goes into CustomAdScope so every AdSlot uses it.',
          code: '''
CustomAdScope(
  source: RemoteAdSource(
    Uri.parse('https://cdn.client.com/ads/ads.json'),
    refreshInterval: const Duration(minutes: 5),
    // headers: {'X-Api-Key': '...'},
  ),
  onImpression: (ad) => analytics.log('ad_impression', ad.id),
  onClick: (ad) => analytics.log('ad_click', ad.id),
  child: MyApp(),
)''',
          child: SizedBox.shrink(),
        ),
        const DemoBlock(
          title: 'home_top: rotates between 2 banners every 30 s',
          description:
              'Each banner has a 728x90 and a 320x50 version; the widest one '
              'that fits is used. Shrink the window to see the mobile version. '
              'Rotation pauses while the mouse is over the ad.',
          code: '''
const AdSlot(placement: 'home_top')

// JSON
"home_top": {
  "rotationSeconds": 30,
  "ads": [{
    "id": "summer-2026",
    "alt": "Summer sale: 50% off",
    "targetUrl": "https://example.com/summer",
    "assets": [
      { "url": "banners/summer-728x90.png", "width": 728, "height": 90 },
      { "url": "banners/summer-320x50.png", "width": 320, "height": 50 }
    ]
  }, ...]
}''',
          child: AdSlot(placement: 'home_top'),
        ),
        const DemoBlock(
          title: 'Forcing a 360px width',
          description: 'The same placement inside a narrow container.',
          code: '''
SizedBox(width: 360, child: AdSlot(placement: 'home_top'))''',
          child: SizedBox(width: 360, child: AdSlot(placement: 'home_top')),
        ),
        const DemoBlock(
          title: 'home_hero: 1200x300 / 600x300, can be closed',
          description: '"dismissible": true in the JSON adds the close button.',
          code: '''
const AdSlot(placement: 'home_hero')

// JSON
"home_hero": { "dismissible": true, "ads": [ ... ] }''',
          child: AdSlot(placement: 'home_hero'),
        ),
        Wrap(
          spacing: 40,
          runSpacing: 24,
          children: const [
            SizedBox(
              width: 320,
              child: DemoBlock(
                title: 'sidebar: 300x250',
                description:
                    'It has 2 banners, but the second one has an "endAt" in '
                    'the past and isn\'t shown.',
                code: '''
const AdSlot(placement: 'sidebar')''',
                child: AdSlot(placement: 'sidebar'),
              ),
            ),
            SizedBox(
              width: 220,
              child: DemoBlock(
                title: 'sidebar_vertical: 160x600',
                description: 'Side ad: desktop only.',
                code: '''
const AdSlot(placement: 'sidebar_vertical')''',
                child: AdSlot(placement: 'sidebar_vertical'),
              ),
            ),
          ],
        ),
        const DemoBlock(
          title: 'coming_soon: scheduled campaign',
          description:
              'Its "startAt" is in 2099, so the placeholder is shown. Without '
              'a placeholder, an empty slot takes no space.',
          code: '''
AdSlot(
  placement: 'coming_soon',
  placeholder: Text('No active ads'),
)''',
          child: AdSlot(
            placement: 'coming_soon',
            placeholder: _Placeholder('No active ads in "coming_soon"'),
          ),
        ),
        const DemoBlock(
          title: 'blog_card: template defined in the JSON',
          description:
              'With "format": "card" the JSON sends text and an image, and the '
              'app builds the design.',
          code: '''
"blog_card": {
  "format": "card",
  "ads": [{
    "id": "blog-collection",
    "title": "The new collection is online",
    "description": "...",
    "imageUrl": "banners/collection-600x300.png",
    "ctaLabel": "See the collection",
    "targetUrl": "https://example.com/collection",
    "sponsor": "Demo Store"
  }]
}''',
          child: SizedBox(width: 360, child: AdSlot(placement: 'blog_card')),
        ),
        DemoBlock(
          title: 'URL down or missing CORS',
          description:
              'If the JSON doesn\'t load, the slot shows the placeholder (or '
              'nothing) and the page keeps working. If a reload fails, the '
              'last valid version keeps being shown.',
          code: '''
AdSlot(
  placement: 'home_top',
  source: RemoteAdSource(Uri.parse('https://.../missing.json')),
  placeholder: Text('Could not load'),
)''',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdSlot(
                placement: 'home_top',
                source: _brokenSource,
                placeholder: const _Placeholder('Could not load the JSON'),
              ),
              const SizedBox(height: 8),
              _SourceStatus(source: _brokenSource),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceStatus extends StatelessWidget {
  const _SourceStatus({required this.source});

  final RemoteAdSource source;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) {
        final (icon, color, text) = switch (source) {
          RemoteAdSource(error: final error?) => (
            Icons.error_outline,
            colors.error,
            'Error: $error',
          ),
          RemoteAdSource(config: final config?) => (
            Icons.check_circle_outline,
            colors.primary,
            '${config.placements.length} placements loaded',
          ),
          _ => (Icons.hourglass_empty, colors.outline, 'Loading…'),
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Icon(icon, color: color, size: 18),
              SelectableText('${source.url}'),
              Text('· $text', style: TextStyle(color: color)),
              TextButton.icon(
                onPressed: source.isLoading ? null : source.reload,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reload'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text),
  );
}
