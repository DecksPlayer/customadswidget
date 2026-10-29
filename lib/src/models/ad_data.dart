import 'package:flutter/foundation.dart';

/// An ad image together with the size it should be displayed at.
///
/// [width] and [height] are logical pixels (CSS px). The file itself can be
/// twice that resolution so it looks sharp on retina screens.
@immutable
class AdAsset {
  const AdAsset({required this.url, required this.width, required this.height});

  factory AdAsset.fromJson(Map<String, dynamic> json, {Uri? baseUri}) =>
      AdAsset(
        url: _resolveUrl(json['url'] as String, baseUri)!,
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  final String url;
  final double width;
  final double height;

  double get aspectRatio => width / height;

  Map<String, dynamic> toJson() => {
    'url': url,
    'width': width,
    'height': height,
  };

  @override
  bool operator ==(Object other) =>
      other is AdAsset &&
      other.url == url &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(url, width, height);
}

/// The content of an ad. It is independent of how it is drawn, so the same
/// [AdData] can be shown in any [AdFormat].
@immutable
class AdData {
  const AdData({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.assets = const [],
    this.ctaLabel = 'Learn more',
    this.targetUrl,
    this.sponsor,
    this.badge = 'Ad',
    this.startAt,
    this.endAt,
  });

  /// When [baseUri] is given (the URL the JSON came from), relative image
  /// and target URLs are resolved against it.
  factory AdData.fromJson(Map<String, dynamic> json, {Uri? baseUri}) {
    final id = json['id'] as String;
    return AdData(
      id: id,
      // Image banners have no visible title: the alt text plays that role
      // for screen readers.
      title: json['title'] as String? ?? json['alt'] as String? ?? id,
      description: json['description'] as String?,
      imageUrl: _resolveUrl(json['imageUrl'] as String?, baseUri),
      assets: [
        for (final asset in json['assets'] as List? ?? const [])
          AdAsset.fromJson(asset as Map<String, dynamic>, baseUri: baseUri),
      ],
      ctaLabel: json['ctaLabel'] as String? ?? 'Learn more',
      targetUrl: _resolveUrl(json['targetUrl'] as String?, baseUri),
      sponsor: json['sponsor'] as String?,
      badge: json.containsKey('badge') ? json['badge'] as String? : 'Ad',
      startAt: DateTime.tryParse(json['startAt'] as String? ?? ''),
      endAt: DateTime.tryParse(json['endAt'] as String? ?? ''),
    );
  }

  /// Identifier used to track impressions and clicks.
  final String id;

  /// Visible title in template formats, and alt text in [AdFormat.creative].
  final String title;
  final String? description;

  /// Network URL (`https://...`) or asset path (`assets/...`).
  final String? imageUrl;

  /// The advertiser's own images for [AdFormat.creative], one per size. The
  /// largest one that fits the available space is used.
  final List<AdAsset> assets;
  final String ctaLabel;

  /// Where a click leads. When null the ad only fires callbacks.
  final String? targetUrl;

  /// Advertiser name, shown next to the label.
  final String? sponsor;

  /// Disclosure label ("Ad", "Sponsored"). When null or empty, the
  /// [AdPolicy.label] is shown instead: the label can't be removed.
  final String? badge;

  /// Active window. Outside of it [AdSlot] doesn't show the ad.
  final DateTime? startAt;
  final DateTime? endAt;

  bool isActiveAt(DateTime now) =>
      (startAt == null || !now.isBefore(startAt!)) &&
      (endAt == null || now.isBefore(endAt!));

  /// The widest asset that fits in [maxWidth] (and passes [fits]), or the
  /// smallest one if none fits (it will be scaled down). [where] filters out
  /// assets that aren't allowed; returns null when none is left.
  AdAsset? assetFor(
    double maxWidth, {
    bool Function(AdAsset asset)? where,
    bool Function(AdAsset asset)? fits,
  }) {
    final candidates = [...assets.where(where ?? (_) => true)]
      ..sort((a, b) => b.width.compareTo(a.width));
    if (candidates.isEmpty) return null;
    return candidates.firstWhere(
      (asset) => asset.width <= maxWidth && (fits?.call(asset) ?? true),
      orElse: () => candidates.last,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (assets.isNotEmpty) 'assets': [for (final a in assets) a.toJson()],
    'ctaLabel': ctaLabel,
    if (targetUrl != null) 'targetUrl': targetUrl,
    if (sponsor != null) 'sponsor': sponsor,
    'badge': badge,
    if (startAt != null) 'startAt': startAt!.toIso8601String(),
    if (endAt != null) 'endAt': endAt!.toIso8601String(),
  };

  AdData copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    List<AdAsset>? assets,
    String? ctaLabel,
    String? targetUrl,
    String? sponsor,
    String? badge,
    DateTime? startAt,
    DateTime? endAt,
  }) => AdData(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    assets: assets ?? this.assets,
    ctaLabel: ctaLabel ?? this.ctaLabel,
    targetUrl: targetUrl ?? this.targetUrl,
    sponsor: sponsor ?? this.sponsor,
    badge: badge ?? this.badge,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
  );

  @override
  bool operator ==(Object other) =>
      other is AdData &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.imageUrl == imageUrl &&
      listEquals(other.assets, assets) &&
      other.ctaLabel == ctaLabel &&
      other.targetUrl == targetUrl &&
      other.sponsor == sponsor &&
      other.badge == badge &&
      other.startAt == startAt &&
      other.endAt == endAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    imageUrl,
    Object.hashAll(assets),
    ctaLabel,
    targetUrl,
    sponsor,
    badge,
    startAt,
    endAt,
  );
}

String? _resolveUrl(String? url, Uri? baseUri) {
  if (url == null || baseUri == null) return url;
  return baseUri.resolve(url).toString();
}
