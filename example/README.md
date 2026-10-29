# customadswidget example

A Flutter Web app that shows every feature of `customadswidget`, each one with its code.

```bash
flutter run -d chrome
```

| Page | What it shows |
|---|---|
| Remote banners | `RemoteAdSource` + `AdSlot` reading [`web/ads/ads.json`](web/ads/ads.json): rotation, scheduling, closing, placeholder, loading errors |
| Non-intrusive | Each `AdPolicy` rule in action for the current screen size |
| Formats | `creative`, `leaderboard`, `mediumRectangle`, `skyscraper`, `card`, `hero` |
| Styles | Theme, `AdStyle.dark`, `AdStyle.vibrant`, a custom style, `CustomAdScope.merge` |
| Behavior | `dismissible`, per-ad callbacks, an ad without a destination, `CustomAdRotator`, the impression rule |
| Custom design | `builder` in `CustomAd` and `AdSlot`, the `AdImage` / `AdCta` building blocks |
| Local JSON | Banners bundled as assets, `AdConfig.fromJson`, `AdData.fromJson` |
| Editor | Builds an ad with a live preview and generates the server JSON |
| Events | Logged impressions, clicks and closes |

## Minimal setup

```dart
import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _ads = RemoteAdSource(Uri.parse('https://cdn.example.com/ads/ads.json'));

  @override
  void dispose() {
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => CustomAdScope(
        source: _ads,
        onImpression: (ad) => debugPrint('impression: ${ad.id}'),
        onClick: (ad) => debugPrint('click: ${ad.id}'),
        child: child!,
      ),
      home: const Scaffold(
        body: Center(child: AdSlot(placement: 'home_top')),
      ),
    );
  }
}
```

The banners in [`web/ads/banners/`](web/ads/banners/) are sample images generated for this example. The photos in the template ads come from [picsum.photos](https://picsum.photos).
