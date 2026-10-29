import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

import '../sample_ads.dart';
import '../widgets/demo.dart';

class BuilderPage extends StatelessWidget {
  const BuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      intro:
          'With builder you draw the ad however you like, in code. The frame '
          'still handles clicks, hover, impressions, closing, the format size '
          'and the non-intrusive policy: it always adds the "Ad" label at the '
          'top left. It works the same in CustomAd, CustomAdRotator and '
          'AdSlot.',
      children: [
        DemoBlock(
          title: 'Free design in a 300x250',
          description: 'hovered lets you animate the design on mouse hover.',
          code: '''
CustomAd(
  ad: ad,
  style: AdStyle.vibrant(Colors.deepOrange),
  builder: (context, ad, style, hovered) => Stack(children: [
    Positioned(right: -30, bottom: -30,
      child: AnimatedRotation(
        turns: hovered ? 0.1 : 0,
        duration: Duration(milliseconds: 300),
        child: Icon(Icons.local_cafe, size: 180, color: Colors.white24),
      )),
    Padding(
      padding: EdgeInsets.all(20),
      child: Column(..., children: [
        Text('-30%', style: TextStyle(fontSize: 56, ...)),
        Text(ad.title, ...),
        AdCta(label: ad.ctaLabel, style: style, hovered: hovered),
      ]),
    ),
  ]),
)''',
          child: CustomAd(
            ad: templateAds[0],
            style: AdStyle.vibrant(Colors.deepOrange),
            builder: (context, ad, style, hovered) => Stack(
              children: [
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: AnimatedRotation(
                    turns: hovered ? 0.1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.local_cafe,
                      size: 180,
                      color: Colors.white24,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      const Text(
                        '-30%',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ad.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AdCta(label: ad.ctaLabel, style: style, hovered: hovered),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        DemoBlock(
          title: 'Composing with the package building blocks',
          description:
              'AdImage and AdCta are public so you can build your own layouts. '
              'Here: a horizontal card. Use AdImage instead of Image.network '
              'so animated images are frozen.',
          code: '''
CustomAd(
  ad: ad,
  format: AdFormat.card,
  builder: (context, ad, style, hovered) => Row(children: [
    SizedBox(width: 160, height: 140, child: AdImage(url: ad.imageUrl!)),
    Expanded(child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(children: [
        Text(ad.sponsor ?? ''),
        Text(ad.title),
        AdCta(label: ad.ctaLabel, style: style, hovered: hovered, dense: true),
      ]),
    )),
  ]),
)''',
          child: SizedBox(
            width: 520,
            child: CustomAd(
              ad: templateAds[1],
              format: AdFormat.card,
              builder: (context, ad, style, hovered) => Row(
                children: [
                  SizedBox(
                    width: 160,
                    height: 140,
                    child: AdImage(url: ad.imageUrl!),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad.sponsor ?? '',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ad.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          AdCta(
                            label: ad.ctaLabel,
                            style: style,
                            hovered: hovered,
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        DemoBlock(
          title: 'Custom design with remote data',
          description:
              'AdSlot with builder: the client\'s JSON sends the image and the '
              'link, and the app decides how it looks. Here the "sidebar" '
              'banner is shown as a framed card with its alt text.',
          code: '''
AdSlot(
  placement: 'sidebar',
  builder: (context, ad, style, hovered) => Column(children: [
    Expanded(child: AdImage(url: ad.assets.first.url, fit: BoxFit.contain)),
    Text(ad.title),
  ]),
)''',
          child: SizedBox(
            width: 300,
            child: AdSlot(
              placement: 'sidebar',
              builder: (context, ad, style, hovered) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedScale(
                        scale: hovered ? 0.97 : 0.92,
                        duration: const Duration(milliseconds: 200),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AdImage(
                            url: ad.assets.first.url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
