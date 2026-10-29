import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../custom_ad_scope.dart';
import '../models/ad_data.dart';
import '../models/ad_format.dart';
import '../models/ad_policy.dart';
import '../models/ad_style.dart';
import 'ad_layouts.dart';

/// Replaces the ad's content while keeping the frame
/// (hover, click, tracking, close). [style] arrives already resolved.
typedef AdContentBuilder =
    Widget Function(
      BuildContext context,
      AdData ad,
      AdStyle style,
      bool hovered,
    );

/// A reusable ad.
///
/// ```dart
/// CustomAd(
///   ad: AdData(id: 'promo-1', title: 'Free shipping', targetUrl: 'https://...'),
///   format: AdFormat.mediumRectangle,
/// )
/// ```
class CustomAd extends StatefulWidget {
  const CustomAd({
    super.key,
    required this.ad,
    this.format = AdFormat.mediumRectangle,
    this.style,
    this.builder,
    this.onTap,
    this.onImpression,
    this.onClose,
    this.dismissible = false,
    this.openInNewTab = true,
  });

  final AdData ad;
  final AdFormat format;

  /// When null, the [CustomAdScope] style or the default style is used.
  final AdStyle? style;

  /// Fully custom content. It ignores the [format] layout but
  /// keeps its size.
  final AdContentBuilder? builder;

  /// Called on click, before opening [AdData.targetUrl].
  final AdEventCallback? onTap;

  /// See [CustomAdScope.onImpression].
  final AdEventCallback? onImpression;
  final AdEventCallback? onClose;

  /// Shows a button so the user can hide the ad.
  final bool dismissible;

  /// On the web, opens [AdData.targetUrl] in a new tab.
  final bool openInNewTab;

  @override
  State<CustomAd> createState() => _CustomAdState();
}

class _CustomAdState extends State<CustomAd> {
  final _visibilityKey = UniqueKey();
  bool _hovered = false;
  bool _dismissed = false;
  bool _impressionSent = false;
  Timer? _viewTimer;

  @override
  void didUpdateWidget(CustomAd oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.id != widget.ad.id) {
      _viewTimer?.cancel();
      _viewTimer = null;
      _impressionSent = false;
      _dismissed = false;
    }
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    super.dispose();
  }

  CustomAdScope? get _scope =>
      context.getInheritedWidgetOfExactType<CustomAdScope>();

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_impressionSent || !mounted) return;
    if (info.visibleFraction >= 0.5) {
      _viewTimer ??= Timer(const Duration(seconds: 1), _sendImpression);
    } else {
      _viewTimer?.cancel();
      _viewTimer = null;
    }
  }

  void _sendImpression() {
    _viewTimer = null;
    if (!mounted || _impressionSent) return;
    _impressionSent = true;
    widget.onImpression?.call(widget.ad);
    _scope?.onImpression?.call(widget.ad);
  }

  Future<void> _handleTap() async {
    final ad = widget.ad;
    widget.onTap?.call(ad);
    _scope?.onClick?.call(ad);

    final uri = ad.targetUrl == null ? null : Uri.tryParse(ad.targetUrl!);
    if (uri == null) return;
    await launchUrl(
      uri,
      webOnlyWindowName: widget.openInNewTab ? '_blank' : '_self',
    );
  }

  void _handleClose() {
    setState(() => _dismissed = true);
    widget.onClose?.call(widget.ad);
  }

  /// Final width and height for the format, the available space and the
  /// [AdPolicy]. A null height means the content defines its own height.
  /// Returns null if the ad isn't allowed on this screen.
  _AdSize? _resolveSize(
    BoxConstraints constraints,
    AdPolicy policy,
    Size? viewport,
  ) {
    final maxWidth = constraints.maxWidth;
    final fixed = widget.format.fixedSize;
    final verticalAllowed =
        viewport == null ||
        viewport.width >= policy.minViewportWidthForVerticalAds;
    bool allowsVertical(double width) =>
        verticalAllowed && width <= policy.maxVerticalAdWidth;

    if (widget.format == AdFormat.creative) {
      final maxHeight = _maxHeight(policy, viewport);
      final asset = widget.ad.assetFor(
        maxWidth,
        where: (a) => a.aspectRatio >= 1 || allowsVertical(a.width),
        // Vertical ads are side ads: they have no height limit.
        fits: (a) => a.aspectRatio < 1 || a.height <= maxHeight,
      );
      if (asset == null) {
        // It has assets but none is allowed on this screen.
        if (widget.ad.assets.isNotEmpty) return null;
        // Only imageUrl, no declared size: assume a fluid 16:9.
        final width = maxWidth.isFinite ? maxWidth : 728.0;
        return (
          width: width,
          height: width * 9 / 16,
          compact: false,
          asset: null,
          vertical: false,
        );
      }
      final width = math.min(asset.width, maxWidth);
      return (
        width: width,
        height: width / asset.aspectRatio,
        compact: false,
        asset: asset,
        vertical: asset.aspectRatio < 1,
      );
    }

    if (widget.format == AdFormat.leaderboard && maxWidth < fixed!.width) {
      const mobile = AdFormat.mobileBanner;
      return (
        width: math.min(maxWidth, mobile.width),
        height: mobile.height,
        compact: true,
        asset: null,
        vertical: false,
      );
    }
    if (fixed != null) {
      final width = math.min(maxWidth, fixed.width);
      final vertical = fixed.height > fixed.width;
      if (vertical && !allowsVertical(width)) return null;
      return (
        width: width,
        height: fixed.height,
        compact: false,
        asset: null,
        vertical: vertical,
      );
    }

    final width = maxWidth.isFinite ? maxWidth : 360.0;
    return switch (widget.format) {
      AdFormat.hero => (
        width: width,
        height: (width * 0.32).clamp(220.0, 360.0),
        compact: false,
        asset: null,
        vertical: false,
      ),
      _ => (
        width: width,
        height: null,
        compact: false,
        asset: null,
        vertical: false,
      ),
    };
  }

  double _maxHeight(AdPolicy policy, Size? viewport) =>
      viewport == null
          ? double.infinity
          : viewport.height * policy.maxViewportHeightFraction;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final scope = CustomAdScope.maybeOf(context);
    final policy = scope?.policy ?? AdPolicy.nonIntrusive;
    final viewport = MediaQuery.maybeSizeOf(context);
    final fallbackStyle =
        widget.format == AdFormat.creative
            ? AdStyle.creative
            : (scope?.style ?? const AdStyle());
    final style = (widget.style ?? fallbackStyle).resolve(context);

    // The "Ad" label is mandatory: if the ad has no badge, the policy
    // label is used.
    final label = policy.labelFor(widget.ad.badge);
    final ad =
        label == widget.ad.badge ? widget.ad : widget.ad.copyWith(badge: label);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _resolveSize(constraints, policy, viewport);
        if (size == null) {
          assert(() {
            debugPrint(
              'customadswidget: "${ad.id}" (${widget.format.name}) hidden: '
              'vertical ads only show on screens at least '
              '${policy.minViewportWidthForVerticalAds}px wide.',
            );
            return true;
          }());
          return const SizedBox.shrink();
        }

        final content =
            widget.builder?.call(context, ad, style, _hovered) ??
            AdLayout(
              format: widget.format,
              ad: ad,
              style: style,
              hovered: _hovered,
              compact: size.compact,
              asset: size.asset,
              reserveCloseSpace: widget.dismissible,
            );

        Widget sized = SizedBox(
          width: size.width,
          height: size.height,
          child: _AdFrame(
            ad: ad,
            style: style,
            hovered: _hovered,
            // Image banners and builders don't guarantee that the
            // content shows the label, so the frame adds it.
            overlayLabel:
                widget.format == AdFormat.creative || widget.builder != null
                    ? label
                    : null,
            onHover: (value) => setState(() => _hovered = value),
            onTap: _handleTap,
            onClose: widget.dismissible ? _handleClose : null,
            child: content,
          ),
        );

        // Side (vertical) ads don't cover the content; the rest are
        // scaled down proportionally when taller than allowed.
        final maxHeight = _maxHeight(policy, viewport);
        if (!size.vertical && maxHeight.isFinite) {
          sized = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: FittedBox(fit: BoxFit.scaleDown, child: sized),
          );
        }

        return VisibilityDetector(
          key: _visibilityKey,
          onVisibilityChanged: _onVisibilityChanged,
          // Center keeps a parent with tight constraints from stretching
          // fixed-size formats; with loose constraints it takes just enough.
          child: Center(widthFactor: 1, heightFactor: 1, child: sized),
        );
      },
    );
  }
}

typedef _AdSize =
    ({
      double width,
      double? height,
      bool compact,
      AdAsset? asset,
      bool vertical,
    });

/// Frame shared by every format: background, shadow, hover, click, close.
class _AdFrame extends StatelessWidget {
  const _AdFrame({
    required this.ad,
    required this.style,
    required this.hovered,
    required this.overlayLabel,
    required this.onHover,
    required this.onTap,
    required this.onClose,
    required this.child,
  });

  final AdData ad;
  final AdStyle style;
  final bool hovered;
  final String? overlayLabel;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final VoidCallback? onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(style.borderRadius);

    return Semantics(
      container: true,
      link: ad.targetUrl != null,
      label: [ad.badge, ad.sponsor, ad.title].nonNulls.join(', '),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: AnimatedScale(
          scale: hovered ? style.hoverScale : 1,
          duration: const Duration(milliseconds: 150),
          child: Material(
            color: style.backgroundColor,
            elevation: hovered ? style.hoverElevation : style.elevation,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: style.gradient,
                border: style.border,
                borderRadius: radius,
              ),
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  children: [
                    child,
                    if (overlayLabel != null)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              overlayLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (onClose != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: onClose,
                          tooltip: 'Close ad',
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 22,
                            height: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black45,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
