import 'package:flutter/widgets.dart';

/// Supported ad formats.
///
/// Formats with a [fixedSize] follow the IAB standard sizes and shrink when
/// the container is narrower. Fluid formats take the available width.
enum AdFormat {
  /// 728x90. Below 728px of width it turns into a 320x50 mobile banner.
  leaderboard(Size(728, 90)),

  /// 300x250, the most common format for sidebars and in-content ads.
  mediumRectangle(Size(300, 250)),

  /// 160x600, vertical column.
  skyscraper(Size(160, 600)),

  /// Fluid-width card, meant for feeds and grids.
  card(null),

  /// Full-width banner with the image as background.
  hero(null),

  /// The advertiser's own banner: shows their image as-is (see
  /// [AdData.assets]), with no template on top. The size comes from the
  /// asset.
  creative(null);

  const AdFormat(this.fixedSize);

  final Size? fixedSize;

  /// Mobile banner size that [leaderboard] falls back to on narrow screens.
  static const Size mobileBanner = Size(320, 50);
}
