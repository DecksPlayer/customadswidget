import 'package:flutter/material.dart';

/// The look of an ad. Null values are resolved from the current theme's
/// [ColorScheme], so by default an ad fits into any app.
@immutable
class AdStyle {
  const AdStyle({
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.accentColor,
    this.onAccentColor,
    this.borderRadius = 12,
    this.elevation = 1,
    this.hoverElevation = 6,
    this.hoverScale = 1.015,
    this.border,
    this.titleStyle,
    this.descriptionStyle,
  });

  /// Default style for [AdFormat.creative]: no rounded corners or shadow,
  /// so the banner's design is left untouched.
  static const creative = AdStyle(
    borderRadius: 0,
    elevation: 0,
    hoverElevation: 3,
    hoverScale: 1,
  );

  /// Dark background with a configurable accent.
  factory AdStyle.dark({Color accent = const Color(0xFF7C4DFF)}) => AdStyle(
    backgroundColor: const Color(0xFF16161D),
    foregroundColor: Colors.white,
    accentColor: accent,
    onAccentColor: Colors.white,
  );

  /// Eye-catching gradient generated from a single color.
  factory AdStyle.vibrant(Color color) {
    final hsl = HSLColor.fromColor(color);
    return AdStyle(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, hsl.withHue((hsl.hue + 40) % 360).toColor()],
      ),
      foregroundColor: Colors.white,
      accentColor: Colors.white,
      onAccentColor: color,
    );
  }

  final Color? backgroundColor;

  /// Takes precedence over [backgroundColor] when set.
  final Gradient? gradient;
  final Color? foregroundColor;

  /// Color of the call-to-action button.
  final Color? accentColor;
  final Color? onAccentColor;
  final double borderRadius;
  final double elevation;
  final double hoverElevation;

  /// Scale applied on mouse hover. 1.0 disables it.
  final double hoverScale;
  final BoxBorder? border;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;

  /// Returns a style with no null colors, using the theme as a base.
  AdStyle resolve(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return copyWith(
      backgroundColor: backgroundColor ?? colors.surfaceContainerLow,
      foregroundColor: foregroundColor ?? colors.onSurface,
      accentColor: accentColor ?? colors.primary,
      onAccentColor: onAccentColor ?? colors.onPrimary,
    );
  }

  AdStyle copyWith({
    Color? backgroundColor,
    Gradient? gradient,
    Color? foregroundColor,
    Color? accentColor,
    Color? onAccentColor,
    double? borderRadius,
    double? elevation,
    double? hoverElevation,
    double? hoverScale,
    BoxBorder? border,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
  }) => AdStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    gradient: gradient ?? this.gradient,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    accentColor: accentColor ?? this.accentColor,
    onAccentColor: onAccentColor ?? this.onAccentColor,
    borderRadius: borderRadius ?? this.borderRadius,
    elevation: elevation ?? this.elevation,
    hoverElevation: hoverElevation ?? this.hoverElevation,
    hoverScale: hoverScale ?? this.hoverScale,
    border: border ?? this.border,
    titleStyle: titleStyle ?? this.titleStyle,
    descriptionStyle: descriptionStyle ?? this.descriptionStyle,
  );
}
