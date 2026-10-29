import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

import '../sample_ads.dart';
import '../widgets/demo.dart';

class FormatsPage extends StatelessWidget {
  const FormatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      intro:
          'The same AdData can be shown in any format. Fixed-size formats '
          'follow the IAB standards; card and hero take the available width; '
          'creative shows the advertiser\'s own image.',
      children: [
        DemoBlock(
          title: 'creative: your own banner',
          description:
              'The image is shown as-is. The widest asset that fits the space '
              'is picked.',
          code: '''
CustomAd(
  format: AdFormat.creative,
  ad: AdData(
    id: 'summer',
    title: 'Summer sale: 50% off',       // alt text
    targetUrl: 'https://example.com/summer',
    assets: [
      AdAsset(url: '.../summer-728x90.png', width: 728, height: 90),
      AdAsset(url: '.../summer-320x50.png', width: 320, height: 50),
    ],
  ),
)''',
          child: CustomAd(ad: creativeAd, format: AdFormat.creative),
        ),
        DemoBlock(
          title: 'leaderboard: 728x90',
          description: 'Below 728px of width it switches to 320x50.',
          code: '''
CustomAd(ad: ad, format: AdFormat.leaderboard)''',
          child: CustomAd(ad: templateAds[1], format: AdFormat.leaderboard),
        ),
        DemoBlock(
          title: 'leaderboard inside a 360px container',
          code: '''
SizedBox(
  width: 360,
  child: CustomAd(ad: ad, format: AdFormat.leaderboard),
)''',
          child: SizedBox(
            width: 360,
            child: CustomAd(ad: templateAds[1], format: AdFormat.leaderboard),
          ),
        ),
        Wrap(
          spacing: 40,
          runSpacing: 24,
          children: [
            SizedBox(
              width: 320,
              child: DemoBlock(
                title: 'mediumRectangle: 300x250',
                code: '''
CustomAd(ad: ad, format: AdFormat.mediumRectangle)''',
                child: CustomAd(ad: templateAds[0]),
              ),
            ),
            SizedBox(
              width: 320,
              child: DemoBlock(
                title: 'mediumRectangle without an image',
                code: '''
CustomAd(ad: AdData(id: 'x', title: '...', ...))''',
                child: CustomAd(ad: textOnlyAd),
              ),
            ),
            SizedBox(
              width: 200,
              child: DemoBlock(
                title: 'skyscraper: 160x600',
                description: 'Side ad: only shown on screens 1024px or wider.',
                code: '''
CustomAd(ad: ad, format: AdFormat.skyscraper)''',
                child: CustomAd(
                  ad: templateAds[2],
                  format: AdFormat.skyscraper,
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: 'card: fluid width',
          description: 'Takes the container\'s width. Ideal for grids.',
          code: '''
SizedBox(
  width: 320,
  child: CustomAd(ad: ad, format: AdFormat.card),
)''',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 300).floor().clamp(1, 3);
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final ad in templateAds)
                    SizedBox(
                      width: width,
                      child: CustomAd(ad: ad, format: AdFormat.card),
                    ),
                ],
              );
            },
          ),
        ),
        DemoBlock(
          title: 'hero: full width with a background image',
          code: '''
CustomAd(ad: ad, format: AdFormat.hero)''',
          child: CustomAd(ad: templateAds[2], format: AdFormat.hero),
        ),
        const DemoBlock(
          title: 'hero without an image',
          code: '''
CustomAd(ad: adWithoutImage, format: AdFormat.hero)''',
          child: CustomAd(ad: textOnlyAd, format: AdFormat.hero),
        ),
      ],
    );
  }
}
