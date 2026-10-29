import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

import '../sample_ads.dart';
import '../widgets/demo.dart';

class StylesPage extends StatelessWidget {
  const StylesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ad = templateAds[0];
    return DemoPage(
      intro:
          'AdStyle controls colors, gradient, borders, shadow, hover and '
          'typography. Anything left unset comes from the app theme, so the '
          'default style also adapts to dark mode (try the button in the top '
          'bar).',
      children: [
        Wrap(
          spacing: 40,
          runSpacing: 24,
          children: [
            _StyleBlock(
              title: 'Default (theme)',
              code: 'CustomAd(ad: ad)',
              child: CustomAd(ad: ad),
            ),
            _StyleBlock(
              title: 'AdStyle.dark()',
              code:
                  'CustomAd(ad: ad, style: AdStyle.dark(accent: Colors.amber))',
              child: CustomAd(
                ad: ad,
                style: AdStyle.dark(accent: Colors.amber),
              ),
            ),
            _StyleBlock(
              title: 'AdStyle.vibrant(color)',
              code: 'CustomAd(ad: ad, style: AdStyle.vibrant(Colors.pink))',
              child: CustomAd(ad: ad, style: AdStyle.vibrant(Colors.pink)),
            ),
            _StyleBlock(
              title: 'AdStyle.vibrant without an image',
              code: 'CustomAd(ad: ad, style: AdStyle.vibrant(Colors.teal))',
              child: CustomAd(
                ad: textOnlyAd,
                style: AdStyle.vibrant(Colors.teal),
              ),
            ),
            _StyleBlock(
              title: 'Custom AdStyle',
              code: '''
AdStyle(
  backgroundColor: Color(0xFFFFF8E1),
  foregroundColor: Color(0xFF3E2723),
  accentColor: Color(0xFF3E2723),
  onAccentColor: Colors.white,
  borderRadius: 0,
  elevation: 0,
  hoverElevation: 0,
  hoverScale: 1.04,
  border: Border.all(color: Color(0xFF3E2723), width: 2),
  titleStyle: TextStyle(fontFamily: 'serif', fontSize: 18),
)''',
              child: CustomAd(
                ad: ad,
                style: AdStyle(
                  backgroundColor: const Color(0xFFFFF8E1),
                  foregroundColor: const Color(0xFF3E2723),
                  accentColor: const Color(0xFF3E2723),
                  onAccentColor: Colors.white,
                  borderRadius: 0,
                  elevation: 0,
                  hoverElevation: 0,
                  hoverScale: 1.04,
                  border: Border.all(color: const Color(0xFF3E2723), width: 2),
                  titleStyle: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            _StyleBlock(
              title: 'copyWith on a preset',
              code: '''
AdStyle.dark().copyWith(
  borderRadius: 28,
  accentColor: Colors.lightGreenAccent,
  onAccentColor: Colors.black,
)''',
              child: CustomAd(
                ad: ad,
                style: AdStyle.dark().copyWith(
                  borderRadius: 28,
                  accentColor: Colors.lightGreenAccent,
                  onAccentColor: Colors.black,
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: 'Per-section style with CustomAdScope.merge',
          description:
              'Every ad in this section takes the style without repeating it, '
              'and the remote source and analytics of the app scope are kept.',
          code: '''
CustomAdScope.merge(
  style: AdStyle.vibrant(Colors.deepPurple),
  child: Wrap(children: [
    CustomAd(ad: a),
    CustomAd(ad: b),
    CustomAd(ad: c, format: AdFormat.card),
  ]),
)''',
          child: CustomAdScope.merge(
            style: AdStyle.vibrant(Colors.deepPurple),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                CustomAd(ad: templateAds[1]),
                const CustomAd(ad: textOnlyAd),
                SizedBox(
                  width: 280,
                  child: CustomAd(ad: templateAds[2], format: AdFormat.card),
                ),
              ],
            ),
          ),
        ),
        DemoBlock(
          title: 'creative uses AdStyle.creative by default',
          description:
              'No rounded corners or zoom, so the banner is left untouched. '
              'Pass style to change it.',
          code: '''
CustomAd(
  ad: banner,
  format: AdFormat.creative,
  style: AdStyle.creative.copyWith(borderRadius: 16, elevation: 4),
)''',
          child: CustomAd(
            ad: localCreativeAd,
            format: AdFormat.creative,
            style: AdStyle.creative.copyWith(borderRadius: 16, elevation: 4),
          ),
        ),
      ],
    );
  }
}

class _StyleBlock extends StatelessWidget {
  const _StyleBlock({
    required this.title,
    required this.code,
    required this.child,
  });

  final String title;
  final String code;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: DemoBlock(title: title, code: code, child: child),
  );
}
