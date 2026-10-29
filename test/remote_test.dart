import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:customadswidget/customadswidget.dart';

final _configUrl = Uri.parse('https://cdn.client.com/ads/ads.json');

final _json = {
  'version': 1,
  'placements': {
    'top': {
      'ads': [
        {
          'id': 'summer',
          'alt': 'Summer promo',
          'targetUrl': '/deals',
          'assets': [
            {'url': 'banners/728.jpg', 'width': 728, 'height': 90},
            {'url': 'banners/320.jpg', 'width': 320, 'height': 50},
          ],
        },
        {'id': 'broken', 'assets': 'this is not a list'},
        {
          'id': 'expired',
          'endAt': '2020-01-01T00:00:00Z',
          'assets': [
            {'url': 'old.jpg', 'width': 300, 'height': 250},
          ],
        },
      ],
    },
    'blog': {
      'format': 'card',
      'ads': [
        {'id': 'coffee', 'title': 'Specialty coffee', 'ctaLabel': 'See'},
      ],
    },
  },
};

RemoteAdSource _source({int status = 200, Object? body}) => RemoteAdSource(
  _configUrl,
  client: MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(body ?? _json)), status),
  ),
);

Widget _app(RemoteAdSource source, Widget child) => MaterialApp(
  home: Scaffold(
    body: CustomAdScope(source: source, child: Center(child: child)),
  ),
);

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );

  group('AdConfig.fromJson', () {
    final config = AdConfig.fromJson(_json, baseUri: _configUrl);

    test('resolves relative paths against the JSON URL', () {
      final ad = config['top']!.ads.first;
      expect(ad.title, 'Summer promo');
      expect(ad.targetUrl, 'https://cdn.client.com/deals');
      expect(ad.assets.first.url, 'https://cdn.client.com/ads/banners/728.jpg');
    });

    test('drops invalid ads without breaking the placement', () {
      expect(config['top']!.ads.map((a) => a.id), ['summer', 'expired']);
    });

    test('filters by schedule and reads the format', () {
      expect(config['top']!.activeAds(DateTime.now()).map((a) => a.id), [
        'summer',
      ]);
      expect(config['top']!.format, AdFormat.creative);
      expect(config['blog']!.format, AdFormat.card);
    });

    test('picks the largest asset that fits', () {
      final ad = config['top']!.ads.first;
      expect(ad.assetFor(1000)!.width, 728);
      expect(ad.assetFor(500)!.width, 320);
      expect(ad.assetFor(200)!.width, 320);
    });
  });

  group('RemoteAdSource', () {
    test('loads the JSON and merges simultaneous requests', () async {
      var requests = 0;
      final source = RemoteAdSource(
        _configUrl,
        client: MockClient((_) async {
          requests++;
          return http.Response(jsonEncode(_json), 200);
        }),
      );
      await Future.wait([source.ensureLoaded(), source.ensureLoaded()]);
      expect(requests, 1);
      expect(source.config!['top'], isNotNull);
      expect(source.error, isNull);
    });

    test('keeps the last valid config when a reload fails', () async {
      var fail = false;
      final source = RemoteAdSource(
        _configUrl,
        client: MockClient(
          (_) async =>
              fail
                  ? http.Response('down', 503)
                  : http.Response(jsonEncode(_json), 200),
        ),
      );
      await source.ensureLoaded();
      fail = true;
      await source.reload();
      expect(source.error, isNotNull);
      expect(source.config!['top'], isNotNull);
    });
  });

  group('AdSlot', () {
    testWidgets('shows the image banner at its asset size', (tester) async {
      final source = _source();
      await source.ensureLoaded();

      await tester.pumpWidget(_app(source, const AdSlot(placement: 'top')));
      expect(tester.getSize(find.byType(InkWell)), const Size(728, 90));
      expect(find.bySemanticsLabel(RegExp('Summer promo')), findsWidgets);
      expect(find.text('Ad'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          source,
          const SizedBox(width: 400, child: AdSlot(placement: 'top')),
        ),
      );
      expect(tester.getSize(find.byType(InkWell)), const Size(320, 50));
    });

    testWidgets('placement with a template format', (tester) async {
      final source = _source();
      await source.ensureLoaded();
      await tester.pumpWidget(
        _app(
          source,
          const SizedBox(width: 360, child: AdSlot(placement: 'blog')),
        ),
      );
      expect(find.text('Specialty coffee'), findsOneWidget);
    });

    testWidgets('shows the placeholder on error or missing placement', (
      tester,
    ) async {
      final source = _source(status: 500);
      await source.ensureLoaded();
      await tester.pumpWidget(
        _app(
          source,
          const AdSlot(placement: 'top', placeholder: Text('empty')),
        ),
      );
      expect(find.text('empty'), findsOneWidget);
    });
  });
}
