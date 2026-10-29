import 'package:flutter/foundation.dart';

/// Rules that keep ads non-intrusive.
///
/// They follow the Better Ads Standards (Coalition for Better Ads) and the
/// Acceptable Ads criteria. They always apply; the thresholds can be tuned
/// through [CustomAdScope.policy] but the rules can't be turned off:
///
/// * Every ad shows a label ([label] or its own [AdData.badge]), including
///   image banners and `builder` ads.
/// * Animated images (animated GIF, WebP or PNG) are frozen on their first
///   frame: no flashing ads.
/// * A landscape or rectangular ad can't take more than
///   [maxViewportHeightFraction] of the screen height; larger ones are scaled
///   down proportionally.
/// * Vertical ads (taller than wide, such as 160x600) are side ads: they
///   only show on screens at least [minViewportWidthForVerticalAds] wide, and
///   at most [maxVerticalAdWidth] wide. On narrow screens they would sit in
///   the middle of the content, so they are hidden (or another asset of the
///   banner is used).
/// * Automatic rotation can't be faster than [minRotationInterval].
///
/// The package offers no pop-ups, interstitials, sticky ads, video or sound.
@immutable
class AdPolicy {
  const AdPolicy({
    this.label = 'Ad',
    this.maxViewportHeightFraction = 0.3,
    this.minViewportWidthForVerticalAds = 1024,
    this.maxVerticalAdWidth = 350,
    this.minRotationInterval = const Duration(seconds: 30),
  }) : assert(maxViewportHeightFraction > 0 && maxViewportHeightFraction <= 1);

  static const nonIntrusive = AdPolicy();

  /// Label for ads that don't have an [AdData.badge].
  final String label;

  /// 0.3 = 30%, the Better Ads Standards threshold for large ads.
  final double maxViewportHeightFraction;
  final double minViewportWidthForVerticalAds;
  final double maxVerticalAdWidth;
  final Duration minRotationInterval;

  /// The rotation interval allowed for the requested one.
  Duration rotationInterval(Duration requested) =>
      requested < minRotationInterval ? minRotationInterval : requested;

  /// The effective label of an ad: its own, or [label] if it has none.
  String labelFor(String? badge) =>
      badge == null || badge.trim().isEmpty ? label : badge;

  @override
  bool operator ==(Object other) =>
      other is AdPolicy &&
      other.label == label &&
      other.maxViewportHeightFraction == maxViewportHeightFraction &&
      other.minViewportWidthForVerticalAds == minViewportWidthForVerticalAds &&
      other.maxVerticalAdWidth == maxVerticalAdWidth &&
      other.minRotationInterval == minRotationInterval;

  @override
  int get hashCode => Object.hash(
    label,
    maxViewportHeightFraction,
    minViewportWidthForVerticalAds,
    maxVerticalAdWidth,
    minRotationInterval,
  );
}
