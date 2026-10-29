import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:customadswidget/customadswidget.dart';

const _ad = AdData(
  id: 'test',
  title: 'Test title',
  description: 'Description',
  ctaLabel: 'Buy',
  sponsor: 'ACME',
);

Widget _wrap(Widget child, {CustomAdScope Function(Widget)? scope}) {
  final body = Center(child: child);
  return MaterialApp(home: Scaffold(body: scope?.call(body) ?? body));
}

/// Desktop screen: 30% of the height = 300px, vertical ads allowed.
void _desktop(WidgetTester tester) => _view(tester, const Size(1280, 1000));

void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );

  testWidgets('shows the content in every format', (tester) async {
    _desktop(tester);
    // creative has no text: it only shows the advertiser's image.
    for (final format in AdFormat.values.where((f) => f != AdFormat.creative)) {
      await tester.pumpWidget(_wrap(CustomAd(ad: _ad, format: format)));
      expect(find.text('Test title'), findsOneWidget, reason: format.name);
      expect(find.text('Buy'), findsOneWidget, reason: format.name);
      expect(tester.takeException(), isNull, reason: format.name);
    }
  });

  testWidgets('keeps the IAB size and falls back to 320x50 on narrow screens', (
    tester,
  ) async {
    _desktop(tester);
    await tester.pumpWidget(_wrap(const CustomAd(ad: _ad)));
    expect(tester.getSize(find.byType(CustomAd)), const Size(300, 250));

    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 400,
          child: CustomAd(ad: _ad, format: AdFormat.leaderboard),
        ),
      ),
    );
    final banner =
        find
            .descendant(
              of: find.byType(CustomAd),
              matching: find.byType(InkWell),
            )
            .first;
    expect(tester.getSize(banner), const Size(320, 50));
  });

  testWidgets('click and close fire callbacks', (tester) async {
    final clicks = <String>[];
    final scopeClicks = <String>[];
    final closed = <String>[];

    await tester.pumpWidget(
      _wrap(
        CustomAd(
          ad: _ad,
          dismissible: true,
          onTap: (ad) => clicks.add(ad.id),
          onClose: (ad) => closed.add(ad.id),
        ),
        scope:
            (child) => CustomAdScope(
              onClick: (ad) => scopeClicks.add(ad.id),
              child: child,
            ),
      ),
    );

    await tester.tap(find.text('Test title'));
    expect(clicks, ['test']);
    expect(scopeClicks, ['test']);

    await tester.tap(find.byTooltip('Close ad'));
    await tester.pump();
    expect(closed, ['test']);
    expect(find.text('Test title'), findsNothing);
  });

  testWidgets('CustomAdScope.merge changes the style and keeps callbacks', (
    tester,
  ) async {
    final clicks = <String>[];
    await tester.pumpWidget(
      _wrap(
        CustomAdScope.merge(
          style: const AdStyle(backgroundColor: Colors.red),
          child: const CustomAd(ad: _ad),
        ),
        scope:
            (child) =>
                CustomAdScope(onClick: (ad) => clicks.add(ad.id), child: child),
      ),
    );

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(CustomAd),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, Colors.red);
    await tester.tap(find.text('Test title'));
    expect(clicks, ['test']);
  });

  testWidgets('records the impression after 1s visible', (tester) async {
    final impressions = <String>[];
    await tester.pumpWidget(
      _wrap(CustomAd(ad: _ad, onImpression: (ad) => impressions.add(ad.id))),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(impressions, isEmpty);
    await tester.pump(const Duration(milliseconds: 600));
    expect(impressions, ['test']);

    await tester.pump(const Duration(seconds: 3));
    expect(impressions, ['test'], reason: 'only one impression per mount');
  });

  test('AdData round trip through JSON', () {
    expect(AdData.fromJson(_ad.toJson()), _ad);
  });
}
