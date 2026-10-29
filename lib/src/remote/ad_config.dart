import 'package:flutter/foundation.dart';

import '../models/ad_data.dart';
import '../models/ad_format.dart';

/// A spot on the page where ads are shown ("home_top", "sidebar"...). The
/// client decides which banners go in each one.
@immutable
class AdPlacement {
  const AdPlacement({
    required this.id,
    required this.ads,
    this.format = AdFormat.creative,
    this.rotationSeconds = 30,
    this.dismissible = false,
  });

  /// Malformed ads are dropped (with a console warning) instead of breaking
  /// the whole placement.
  factory AdPlacement.fromJson(
    String id,
    Map<String, dynamic> json, {
    Uri? baseUri,
  }) {
    final ads = <AdData>[];
    for (final raw in json['ads'] as List? ?? const []) {
      try {
        ads.add(AdData.fromJson(raw as Map<String, dynamic>, baseUri: baseUri));
      } catch (e) {
        debugPrint('customadswidget: invalid ad in "$id" ($e): $raw');
      }
    }
    return AdPlacement(
      id: id,
      ads: ads,
      format: AdFormat.values.asNameMap()[json['format']] ?? AdFormat.creative,
      rotationSeconds: (json['rotationSeconds'] as num?)?.toInt() ?? 30,
      dismissible: json['dismissible'] as bool? ?? false,
    );
  }

  final String id;
  final List<AdData> ads;
  final AdFormat format;

  /// How often it rotates when there is more than one active ad. 0 disables
  /// rotation and only the first ad is shown.
  final int rotationSeconds;
  final bool dismissible;

  List<AdData> activeAds(DateTime now) =>
      ads.where((ad) => ad.isActiveAt(now)).toList();
}

/// The full content of the JSON published by the client.
@immutable
class AdConfig {
  const AdConfig({this.version = 1, this.placements = const {}});

  /// [baseUri] is the JSON URL: relative image and link paths are resolved
  /// against it.
  factory AdConfig.fromJson(Map<String, dynamic> json, {Uri? baseUri}) {
    final placements = json['placements'] as Map<String, dynamic>? ?? const {};
    return AdConfig(
      version: (json['version'] as num?)?.toInt() ?? 1,
      placements: {
        for (final MapEntry(:key, :value) in placements.entries)
          key: AdPlacement.fromJson(
            key,
            value as Map<String, dynamic>,
            baseUri: baseUri,
          ),
      },
    );
  }

  final int version;
  final Map<String, AdPlacement> placements;

  AdPlacement? operator [](String placementId) => placements[placementId];
}
