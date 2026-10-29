import 'package:flutter/material.dart';

import '../models/ad_data.dart';
import '../models/ad_policy.dart';
import '../models/ad_style.dart';
import 'first_frame_image.dart';

/// An ad image. Accepts network URLs or `assets/...` paths.
///
/// Animated images are shown frozen on their first frame (see [AdPolicy]).
/// That's why, on the web, network images are decoded by Flutter and need
/// CORS: the native `<img>` element isn't used because it can't be frozen.
/// In your own `builder`, use this widget instead of `Image.network`.
class AdImage extends StatelessWidget {
  const AdImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_outlined, color: colors.onSurfaceVariant),
      ),
    );
    final ImageProvider provider =
        url.startsWith('assets/') ? AssetImage(url) : NetworkImage(url);

    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Image(
        image: FirstFrameImage(provider),
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: child,
          );
        },
      ),
    );
  }
}

/// Call-to-action button. It's decorative: the whole ad is the clickable
/// area, so the user doesn't have to aim at the button.
class AdCta extends StatelessWidget {
  const AdCta({
    super.key,
    required this.label,
    required this.style,
    required this.hovered,
    this.dense = false,
    this.expand = false,
  });

  final String label;
  final AdStyle style;
  final bool hovered;
  final bool dense;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final accent = style.accentColor!;
    final onAccent = style.onAccentColor!;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding:
          dense
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: hovered ? Color.lerp(accent, onAccent, 0.12) : accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (dense ? textTheme.labelMedium : textTheme.labelLarge)
                  ?.copyWith(color: onAccent, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSlide(
            offset: hovered ? const Offset(0.25, 0) : Offset.zero,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              Icons.arrow_forward,
              size: dense ? 14 : 16,
              color: onAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Line with the disclosure label ("Ad") and the advertiser.
class AdMetaLine extends StatelessWidget {
  const AdMetaLine({super.key, required this.ad, required this.style});

  final AdData ad;
  final AdStyle style;

  @override
  Widget build(BuildContext context) {
    final fg = style.foregroundColor!;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: fg.withValues(alpha: 0.7),
      height: 1.1,
    );

    // Both texts are Flexible so that narrow formats truncate them with "…"
    // instead of overflowing; the label takes priority over the sponsor.
    return Row(
      children: [
        if (ad.badge != null)
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: fg.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ad.badge!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ),
        if (ad.badge != null && ad.sponsor != null) const SizedBox(width: 6),
        if (ad.sponsor != null)
          Flexible(
            child: Text(
              ad.sponsor!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
      ],
    );
  }
}

TextStyle? adTitleStyle(
  BuildContext context,
  AdStyle style, {
  TextStyle? base,
}) => (base ?? Theme.of(context).textTheme.titleMedium)
    ?.copyWith(color: style.foregroundColor, fontWeight: FontWeight.w700)
    .merge(style.titleStyle);

TextStyle? adDescriptionStyle(BuildContext context, AdStyle style) =>
    Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: style.foregroundColor!.withValues(alpha: 0.8))
        .merge(style.descriptionStyle);
