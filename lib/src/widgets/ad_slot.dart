import 'package:flutter/material.dart';

import '../custom_ad_scope.dart';
import '../models/ad_style.dart';
import '../remote/remote_ad_source.dart';
import 'custom_ad.dart';
import 'custom_ad_rotator.dart';

/// Shows the active ads of a placement from the remote JSON.
///
/// ```dart
/// const AdSlot(placement: 'home_top')
/// ```
///
/// If the placement doesn't exist, has no active ads or the JSON hasn't
/// loaded yet, it shows [placeholder] (nothing by default), so an empty slot
/// never leaves a gap on the page.
class AdSlot extends StatefulWidget {
  const AdSlot({
    super.key,
    required this.placement,
    this.source,
    this.style,
    this.builder,
    this.placeholder,
  });

  final String placement;

  /// When null, [CustomAdScope.source] is used.
  final RemoteAdSource? source;
  final AdStyle? style;

  /// Custom design in code for this slot's ads.
  final AdContentBuilder? builder;
  final Widget? placeholder;

  @override
  State<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends State<AdSlot> {
  RemoteAdSource? _source;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindSource();
  }

  @override
  void didUpdateWidget(AdSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bindSource();
  }

  void _bindSource() {
    final source = widget.source ?? CustomAdScope.maybeOf(context)?.source;
    assert(
      source != null,
      'AdSlot needs a RemoteAdSource: pass it in `source` or in CustomAdScope.',
    );
    if (source != _source) {
      _source = source;
      source?.ensureLoaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    final empty = widget.placeholder ?? const SizedBox.shrink();
    if (source == null) return empty;

    return ListenableBuilder(
      listenable: source,
      builder: (context, _) {
        final placement = source.config?[widget.placement];
        final ads = placement?.activeAds(DateTime.now()) ?? const [];
        if (placement == null || ads.isEmpty) return empty;

        if (ads.length == 1 || placement.rotationSeconds <= 0) {
          return CustomAd(
            key: ValueKey(ads.first.id),
            ad: ads.first,
            format: placement.format,
            style: widget.style,
            builder: widget.builder,
            dismissible: placement.dismissible,
          );
        }
        return CustomAdRotator(
          ads: ads,
          format: placement.format,
          style: widget.style,
          builder: widget.builder,
          dismissible: placement.dismissible,
          interval: Duration(seconds: placement.rotationSeconds),
        );
      },
    );
  }
}
