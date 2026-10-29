import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

import '../sample_ads.dart';
import '../widgets/demo.dart';

/// The AdPolicy rules in action. Resize the window to see how they change
/// with the screen size.
class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final policy = CustomAdScope.policyOf(context);
    final viewport = MediaQuery.sizeOf(context);
    final maxHeight = viewport.height * policy.maxViewportHeightFraction;
    final verticalAllowed =
        viewport.width >= policy.minViewportWidthForVerticalAds;

    return DemoPage(
      intro:
          'Only non-intrusive ads are shown, following the Better Ads '
          'Standards and the Acceptable Ads criteria. The rules always apply; '
          'the thresholds are tuned with AdPolicy.',
      children: [
        _Rules(
          viewport: viewport,
          maxHeight: maxHeight,
          verticalAllowed: verticalAllowed,
          policy: policy,
        ),
        const DemoBlock(
          title: '1. Label always visible',
          description:
              'This ad has badge: null and still shows "Ad". The text can be '
              'changed ("Sponsored") but not removed. On image banners and '
              'builders the label sits on top of the image.',
          code: '''
CustomAd(ad: AdData(id: 'x', title: '...', badge: null))
// -> shows "Ad"''',
          child: CustomAd(
            ad: AdData(
              id: 'no-badge',
              title: 'Ad without a badge',
              description: 'The policy adds the label anyway.',
              ctaLabel: 'See',
              badge: null,
            ),
          ),
        ),
        DemoBlock(
          title: '2. Maximum size',
          description:
              'No landscape or rectangular ad takes more than '
              '${(policy.maxViewportHeightFraction * 100).round()}% of the '
              'screen height (now: ${maxHeight.round()}px). Larger ones are '
              'scaled down proportionally. Make the window shorter to see this '
              'hero shrink.',
          code: '''
CustomAd(ad: ad, format: AdFormat.hero)''',
          child: CustomAd(ad: templateAds[0], format: AdFormat.hero),
        ),
        DemoBlock(
          title: '3. Vertical ads only as side ads',
          description: verticalAllowed
              ? 'Your screen is ${viewport.width.round()}px wide: the 160x600 '
                    'is shown. Shrink the window below '
                    '${policy.minViewportWidthForVerticalAds.round()}px and it '
                    'disappears, because on mobile it would sit in the middle '
                    'of the content.'
              : 'Your screen is ${viewport.width.round()}px wide, less than '
                    '${policy.minViewportWidthForVerticalAds.round()}px: the '
                    '160x600 is not shown.',
          code: '''
CustomAd(ad: ad, format: AdFormat.skyscraper)''',
          child: CustomAd(ad: templateAds[2], format: AdFormat.skyscraper),
        ),
        const DemoBlock(
          title: '4. Image banners: the allowed asset is picked',
          description:
              'This banner has a 160x600 and a 320x50, inside a 200px column. '
              'On desktop it uses the vertical one; on narrow screens the '
              'vertical one isn\'t allowed and the landscape one is used.',
          code: '''
AdData(
  id: 'app',
  title: 'Get the app',
  assets: [
    AdAsset(url: '.../app-160x600.png', width: 160, height: 600),
    AdAsset(url: '.../summer-320x50.png', width: 320, height: 50),
  ],
)''',
          child: SizedBox(width: 200, child: _ResponsiveCreative()),
        ),
        const DemoBlock(
          title: '5. No automatic animations',
          description:
              'Animated GIF, WebP or PNG images are shown frozen on their first '
              'frame. Automatic rotation is never faster than 30 seconds. The '
              'only motion comes from hover, which the user starts.',
          code: '''
// In your own builders use AdImage (it freezes animations)
// instead of Image.network.
AdImage(url: ad.imageUrl!)''',
          child: SizedBox.shrink(),
        ),
        const DemoBlock(
          title: '6. Formats that don\'t exist in the package',
          description:
              'Pop-ups, interstitials (with or without a countdown), sticky '
              'ads covering content, autoplay video and sound. The user can '
              'always keep reading and, with dismissible, close the ad.',
          child: SizedBox.shrink(),
        ),
        const DemoBlock(
          title: 'Tuning the thresholds',
          description:
              'The numbers can be made stricter or looser, but the rules stay '
              'on.',
          code: '''
CustomAdScope(
  policy: AdPolicy(
    label: 'Advertisement',
    maxViewportHeightFraction: 0.25,
    minViewportWidthForVerticalAds: 1200,
    minRotationInterval: Duration(seconds: 45),
  ),
  child: ...,
)''',
          child: SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({
    required this.viewport,
    required this.maxHeight,
    required this.verticalAllowed,
    required this.policy,
  });

  final Size viewport;
  final double maxHeight;
  final bool verticalAllowed;
  final AdPolicy policy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'On this screen (${viewport.width.round()}x'
              '${viewport.height.round()})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            row(Icons.label_outline, 'Label: "${policy.label}"'),
            row(Icons.height, 'Maximum height per ad: ${maxHeight.round()}px'),
            row(
              verticalAllowed ? Icons.check : Icons.block,
              verticalAllowed
                  ? 'Vertical ads: allowed'
                  : 'Vertical ads: hidden',
            ),
            row(
              Icons.timer_outlined,
              'Minimum rotation: ${policy.minRotationInterval.inSeconds} s',
            ),
            row(Icons.motion_photos_off_outlined, 'Animated images: frozen'),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveCreative extends StatelessWidget {
  const _ResponsiveCreative();

  @override
  Widget build(BuildContext context) => CustomAd(
    format: AdFormat.creative,
    ad: AdData(
      id: 'app-responsive',
      title: 'Get the app',
      targetUrl: 'https://example.com/app',
      assets: [
        AdAsset(url: bannerUrl('app-160x600.png'), width: 160, height: 600),
        AdAsset(url: bannerUrl('summer-320x50.png'), width: 320, height: 50),
      ],
    ),
  );
}
