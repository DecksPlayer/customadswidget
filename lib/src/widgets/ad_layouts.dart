import 'package:flutter/material.dart';

import '../models/ad_data.dart';
import '../models/ad_format.dart';
import '../models/ad_style.dart';
import 'ad_parts.dart';

/// Draws the content of an ad according to its [AdFormat].
///
/// Expects an already resolved [AdStyle] (no null colors).
class AdLayout extends StatelessWidget {
  const AdLayout({
    super.key,
    required this.format,
    required this.ad,
    required this.style,
    required this.hovered,
    this.compact = false,
    this.asset,
    this.reserveCloseSpace = false,
  });

  final AdFormat format;
  final AdData ad;
  final AdStyle style;
  final bool hovered;

  /// Only for [AdFormat.leaderboard]: uses the 320x50 mobile variant.
  final bool compact;

  /// Only for [AdFormat.creative]: the image chosen for this width.
  final AdAsset? asset;

  /// Leaves room on the right for the close button.
  final bool reserveCloseSpace;

  double get _closeGap => reserveCloseSpace ? 24 : 0;

  @override
  Widget build(BuildContext context) => switch (format) {
    AdFormat.leaderboard =>
      compact ? _buildMobileBanner(context) : _buildLeaderboard(context),
    AdFormat.mediumRectangle => _buildMediumRectangle(context),
    AdFormat.skyscraper => _buildSkyscraper(context),
    AdFormat.card => _buildCard(context),
    AdFormat.hero => _buildHero(context),
    AdFormat.creative => _buildCreative(),
  };

  Widget _buildCreative() {
    final url = asset?.url ?? ad.imageUrl;
    if (url == null) return const SizedBox.shrink();
    return Semantics(image: true, label: ad.title, child: AdImage(url: url));
  }

  Widget _buildLeaderboard(BuildContext context) => Row(
    children: [
      if (ad.imageUrl != null)
        AspectRatio(aspectRatio: 1.4, child: AdImage(url: ad.imageUrl!)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdMetaLine(ad: ad, style: style),
              const SizedBox(height: 4),
              Text(
                ad.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: adTitleStyle(context, style),
              ),
              if (ad.description != null)
                Text(
                  ad.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: adDescriptionStyle(context, style),
                ),
            ],
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(right: 16 + _closeGap),
        child: AdCta(label: ad.ctaLabel, style: style, hovered: hovered),
      ),
    ],
  );

  Widget _buildMobileBanner(BuildContext context) => Row(
    children: [
      if (ad.imageUrl != null)
        AspectRatio(aspectRatio: 1, child: AdImage(url: ad.imageUrl!)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ad.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: adTitleStyle(
                  context,
                  style,
                  base: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 2),
              AdMetaLine(ad: ad, style: style),
            ],
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(right: 8 + _closeGap),
        child: AdCta(
          label: ad.ctaLabel,
          style: style,
          hovered: hovered,
          dense: true,
        ),
      ),
    ],
  );

  Widget _buildMediumRectangle(BuildContext context) {
    final hasImage = ad.imageUrl != null;
    final text = Padding(
      padding: EdgeInsets.fromLTRB(12, 10, hasImage ? 12 : 12 + _closeGap, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ad.title,
            maxLines: hasImage ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            style: adTitleStyle(context, style),
          ),
          if (ad.description != null) ...[
            const SizedBox(height: 2),
            Text(
              ad.description!,
              maxLines: hasImage ? 2 : 5,
              overflow: TextOverflow.ellipsis,
              style: adDescriptionStyle(context, style),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: AdMetaLine(ad: ad, style: style)),
              const SizedBox(width: 8),
              AdCta(
                label: ad.ctaLabel,
                style: style,
                hovered: hovered,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );

    if (!hasImage) return Center(child: text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Expanded(child: AdImage(url: ad.imageUrl!)), text],
    );
  }

  Widget _buildSkyscraper(BuildContext context) {
    final hasImage = ad.imageUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage) SizedBox(height: 220, child: AdImage(url: ad.imageUrl!)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              hasImage ? 12 : 12 + _closeGap,
              12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdMetaLine(ad: ad, style: style),
                const SizedBox(height: 8),
                Text(
                  ad.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: adTitleStyle(context, style),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      ad.description == null
                          ? const SizedBox.shrink()
                          : Text(
                            ad.description!,
                            overflow: TextOverflow.fade,
                            style: adDescriptionStyle(context, style),
                          ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: AdCta(
            label: ad.ctaLabel,
            style: style,
            hovered: hovered,
            dense: true,
            expand: true,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final hasImage = ad.imageUrl != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImage)
          AspectRatio(aspectRatio: 16 / 9, child: AdImage(url: ad.imageUrl!)),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            hasImage ? 16 : 16 + _closeGap,
            16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdMetaLine(ad: ad, style: style),
              const SizedBox(height: 8),
              Text(
                ad.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: adTitleStyle(context, style),
              ),
              if (ad.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  ad.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: adDescriptionStyle(context, style),
                ),
              ],
              const SizedBox(height: 14),
              AdCta(label: ad.ctaLabel, style: style, hovered: hovered),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final hasImage = ad.imageUrl != null;
    // Over a photo the text is always white on top of a dark overlay.
    final textStyle =
        hasImage ? style.copyWith(foregroundColor: Colors.white) : style;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage) ...[
          AnimatedScale(
            scale: hovered ? 1.04 : 1,
            duration: const Duration(milliseconds: 400),
            child: AdImage(url: ad.imageUrl!),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdMetaLine(ad: ad, style: textStyle),
                  const SizedBox(height: 10),
                  Text(
                    ad.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: adTitleStyle(
                      context,
                      textStyle,
                      base: textTheme.headlineSmall,
                    ),
                  ),
                  if (ad.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      ad.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: adDescriptionStyle(
                        context,
                        textStyle,
                      )?.copyWith(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 18),
                  AdCta(label: ad.ctaLabel, style: style, hovered: hovered),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
