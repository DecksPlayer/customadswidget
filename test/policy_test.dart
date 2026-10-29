import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:customadswidget/customadswidget.dart';
import 'package:customadswidget/src/widgets/first_frame_image.dart';

const _ad = AdData(id: 'a', title: 'Title A', ctaLabel: 'See');

void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child, {AdPolicy policy = AdPolicy.nonIntrusive}) =>
    MaterialApp(
      home: Scaffold(
        body: CustomAdScope(policy: policy, child: Center(child: child)),
      ),
    );

/// On-screen size, with the scale applied.
Size _paintedSize(WidgetTester tester, Finder finder) {
  final rect = tester.getRect(finder);
  return rect.size;
}

void main() {
  setUp(
    () => VisibilityDetectorController.instance.updateInterval = Duration.zero,
  );

  group('mandatory label', () {
    testWidgets('uses "Ad" when the ad has no badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CustomAd(ad: AdData(id: 'x', title: 'No badge', badge: null)),
        ),
      );
      expect(find.text('Ad'), findsOneWidget);
    });

    testWidgets('keeps a custom badge', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CustomAd(ad: AdData(id: 'x', title: 'T', badge: 'Sponsored')),
        ),
      );
      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Ad'), findsNothing);
    });

    testWidgets('image banners and builders show the label on top', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CustomAd(
            format: AdFormat.creative,
            ad: AdData(
              id: 'c',
              title: 'Banner',
              assets: [AdAsset(url: 'assets/x.png', width: 300, height: 100)],
            ),
          ),
        ),
      );
      expect(find.text('Ad'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          CustomAd(
            ad: _ad,
            builder: (context, ad, style, hovered) => const Text('custom'),
          ),
        ),
      );
      expect(find.text('custom'), findsOneWidget);
      expect(find.text('Ad'), findsOneWidget);
    });
  });

  group('maximum size', () {
    testWidgets('an ad taller than 30% of the screen is scaled down', (
      tester,
    ) async {
      _view(tester, const Size(390, 600)); // 30% = 180px
      await tester.pumpWidget(_wrap(const CustomAd(ad: _ad)));
      expect(
        _paintedSize(tester, find.byType(InkWell).first),
        const Size(216, 180),
      );
    });

    testWidgets('the threshold can be tuned', (tester) async {
      _view(tester, const Size(390, 600));
      await tester.pumpWidget(
        _wrap(
          const CustomAd(ad: _ad),
          policy: const AdPolicy(maxViewportHeightFraction: 0.5),
        ),
      );
      expect(
        _paintedSize(tester, find.byType(InkWell).first),
        const Size(300, 250),
      );
    });

    testWidgets('creative picks the asset that fits the allowed height', (
      tester,
    ) async {
      _view(tester, const Size(1280, 500)); // 30% = 150px
      await tester.pumpWidget(
        _wrap(
          const CustomAd(
            format: AdFormat.creative,
            ad: AdData(
              id: 'c',
              title: 'Banner',
              assets: [
                AdAsset(url: 'assets/large.png', width: 1200, height: 300),
                AdAsset(url: 'assets/small.png', width: 728, height: 90),
              ],
            ),
          ),
        ),
      );
      expect(
        _paintedSize(tester, find.byType(InkWell).first),
        const Size(728, 90),
      );
    });
  });

  group('vertical ads', () {
    testWidgets('are hidden on narrow screens', (tester) async {
      _view(tester, const Size(800, 1000));
      await tester.pumpWidget(
        _wrap(const CustomAd(ad: _ad, format: AdFormat.skyscraper)),
      );
      expect(find.text('Title A'), findsNothing);
    });

    testWidgets('show unscaled on desktop', (tester) async {
      _view(tester, const Size(1280, 800));
      await tester.pumpWidget(
        _wrap(const CustomAd(ad: _ad, format: AdFormat.skyscraper)),
      );
      expect(
        _paintedSize(tester, find.byType(InkWell).first),
        const Size(160, 600),
      );
    });

    testWidgets('on desktop a vertical asset has no height limit', (
      tester,
    ) async {
      _view(tester, const Size(1280, 800)); // 30% = 240px < 600px
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: CustomAd(
              format: AdFormat.creative,
              ad: AdData(
                id: 'c',
                title: 'Banner',
                assets: [
                  AdAsset(url: 'assets/vertical.png', width: 160, height: 600),
                  AdAsset(url: 'assets/mobile.png', width: 320, height: 50),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getRect(find.byType(InkWell).first).size,
        const Size(160, 600),
      );
    });

    testWidgets('creative uses the landscape asset on narrow screens', (
      tester,
    ) async {
      _view(tester, const Size(400, 800));
      await tester.pumpWidget(
        _wrap(
          const CustomAd(
            format: AdFormat.creative,
            ad: AdData(
              id: 'c',
              title: 'Banner',
              assets: [
                AdAsset(url: 'assets/vertical.png', width: 160, height: 600),
                AdAsset(url: 'assets/mobile.png', width: 320, height: 50),
              ],
            ),
          ),
        ),
      );
      expect(
        _paintedSize(tester, find.byType(InkWell).first),
        const Size(320, 50),
      );
    });
  });

  testWidgets('rotation is never faster than 30 seconds', (tester) async {
    _view(tester, const Size(1280, 1000));
    const ads = [
      AdData(id: '1', title: 'First'),
      AdData(id: '2', title: 'Second'),
    ];
    await tester.pumpWidget(
      _wrap(const CustomAdRotator(ads: ads, interval: Duration(seconds: 2))),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('First'), findsOneWidget);

    await tester.pump(const Duration(seconds: 21));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Second'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('FirstFrameImage only delivers the first frame', (tester) async {
    final frames = await tester.runAsync(
      () async => [await createTestImage(), await createTestImage()],
    );
    final animated = _ManualImage();
    final provider = FirstFrameImage(animated);
    final received = <ImageInfo>[];

    final stream = provider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) => received.add(info)));

    animated.completer.emit(frames![0]);
    animated.completer.emit(frames[1]);
    await tester.pump();

    expect(received, hasLength(1));
    expect(animated.completer.listenerCount, 0);
  });
}

/// Test provider that emits frames by hand, like an animated GIF.
class _ManualImage extends ImageProvider<_ManualImage> {
  final completer = _ManualCompleter();

  @override
  Future<_ManualImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(
    _ManualImage key,
    ImageDecoderCallback decode,
  ) => completer;
}

class _ManualCompleter extends ImageStreamCompleter {
  int listenerCount = 0;

  void emit(ui.Image image) => setImage(ImageInfo(image: image.clone()));

  @override
  void addListener(ImageStreamListener listener) {
    listenerCount++;
    super.addListener(listener);
  }

  @override
  void removeListener(ImageStreamListener listener) {
    listenerCount--;
    super.removeListener(listener);
  }
}
