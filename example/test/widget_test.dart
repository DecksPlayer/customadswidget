import 'package:customadswidget_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  testWidgets('every example page builds without errors', (tester) async {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    const pages = [
      'Remote banners',
      'Non-intrusive',
      'Formats',
      'Styles',
      'Behavior',
      'Custom design',
      'Local JSON',
      'Editor',
      'Events',
    ];
    for (final page in pages) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(page),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: page);
      expect(find.widgetWithText(AppBar, page), findsOneWidget);
    }

    // Unmount the app to cancel timers (rotators, JSON refresh).
    await tester.pumpWidget(const SizedBox());
  });
}
