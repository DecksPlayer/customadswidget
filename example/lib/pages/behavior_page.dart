import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

import '../event_log.dart';
import '../sample_ads.dart';
import '../widgets/demo.dart';

class BehaviorPage extends StatelessWidget {
  const BehaviorPage({super.key});

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return DemoPage(
      intro:
          'Clicks, impressions, closing and rotation. The counters in the top '
          'bar and the Events page show what reaches analytics.',
      children: [
        Wrap(
          spacing: 40,
          runSpacing: 24,
          children: [
            SizedBox(
              width: 320,
              child: DemoBlock(
                title: 'Can be closed',
                description:
                    'dismissible adds the close button; onClose '
                    'reports it.',
                code: '''
CustomAd(
  ad: ad,
  dismissible: true,
  onClose: (ad) => print('closed \${ad.id}'),
)''',
                child: CustomAd(
                  ad: templateAds[0],
                  dismissible: true,
                  onClose: (ad) {
                    eventLog.add(AdEventType.close, ad);
                    _snack(context, 'Closed: ${ad.id}');
                  },
                ),
              ),
            ),
            SizedBox(
              width: 320,
              child: DemoBlock(
                title: 'Per-ad callbacks',
                description:
                    'onTap and onImpression add to the CustomAdScope ones. The '
                    'click also opens targetUrl in a new tab.',
                code: '''
CustomAd(
  ad: ad,
  onTap: (ad) => ...,
  onImpression: (ad) => ...,
)''',
                child: CustomAd(
                  ad: templateAds[1],
                  onTap: (ad) {
                    eventLog.add(AdEventType.tap, ad);
                    _snack(context, 'onTap: ${ad.id}');
                  },
                  onImpression: (ad) =>
                      _snack(context, 'onImpression: ${ad.id}'),
                ),
              ),
            ),
            SizedBox(
              width: 320,
              child: DemoBlock(
                title: 'No destination',
                description:
                    'Without targetUrl it doesn\'t navigate: it only fires the '
                    'callbacks. Useful to open a dialog or an internal route.',
                code: '''
CustomAd(
  ad: AdData(id: 'promo', title: '...'),  // no targetUrl
  onTap: (ad) => Navigator.pushNamed(context, '/promo'),
)
// With a targetUrl, openInNewTab: false opens it in the same tab.''',
                child: CustomAd(
                  ad: const AdData(
                    id: 'no-destination',
                    title: 'Open a dialog instead of navigating',
                    description: 'This ad has no targetUrl.',
                    ctaLabel: 'Try it',
                  ),
                  style: AdStyle.vibrant(Colors.indigo),
                  onTap: (ad) => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Internal promo'),
                      content: Text(
                        'Clicked "${ad.id}" without leaving the app.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        DemoBlock(
          title: 'CustomAdRotator',
          description:
              'Rotates several ads in the same spot and pauses while the mouse '
              'is over it. Here it asks for every 3 seconds, but the '
              'non-intrusive policy raises it to the 30-second minimum. Closing '
              'it hides the whole rotator. AdSlot uses it automatically when a '
              'placement has several ads.',
          code: '''
CustomAdRotator(
  ads: [a, b, c],
  format: AdFormat.leaderboard,
  interval: Duration(seconds: 3), // the minimum applies: 30 s
  dismissible: true,
)''',
          child: const CustomAdRotator(
            ads: templateAds,
            format: AdFormat.leaderboard,
            interval: Duration(seconds: 3),
            dismissible: true,
          ),
        ),
        const DemoBlock(
          title: 'Impression rule',
          description:
              'An impression counts when at least 50% of the ad has been '
              'visible for 1 second straight (IAB criterion), and only once per '
              'mounted ad. Scroll down to the ad below and watch the '
              'impressions counter.',
          child: SizedBox(height: 600, child: Center(child: Icon(Icons.south))),
        ),
        DemoBlock(
          title: 'Ad at the bottom of the page',
          child: CustomAd(ad: templateAds[2], format: AdFormat.leaderboard),
        ),
      ],
    );
  }
}
