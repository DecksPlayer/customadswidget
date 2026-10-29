import 'dart:async';

import 'package:flutter/material.dart';

import '../custom_ad_scope.dart';
import '../models/ad_data.dart';
import '../models/ad_format.dart';
import '../models/ad_policy.dart';
import '../models/ad_style.dart';
import 'custom_ad.dart';

/// Rotates several ads in the same space. It pauses while the mouse is
/// over it, so the ad doesn't change right before the user clicks it.
class CustomAdRotator extends StatefulWidget {
  const CustomAdRotator({
    super.key,
    required this.ads,
    this.format = AdFormat.mediumRectangle,
    this.style,
    this.builder,
    this.interval = const Duration(seconds: 30),
    this.dismissible = false,
    this.onTap,
    this.onImpression,
  });

  /// Must not be empty.
  final List<AdData> ads;
  final AdFormat format;
  final AdStyle? style;
  final AdContentBuilder? builder;

  /// If shorter than [AdPolicy.minRotationInterval], that minimum is used.
  final Duration interval;

  /// Closing any ad hides the whole rotator.
  final bool dismissible;
  final AdEventCallback? onTap;
  final AdEventCallback? onImpression;

  @override
  State<CustomAdRotator> createState() => _CustomAdRotatorState();
}

class _CustomAdRotatorState extends State<CustomAdRotator> {
  Timer? _timer;
  Duration? _interval;
  int _index = 0;
  bool _paused = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    assert(widget.ads.isNotEmpty, 'CustomAdRotator needs at least one ad');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(CustomAdRotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.ads.length) _index = 0;
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Restarts the timer only if the effective interval changed.
  void _syncTimer() {
    if (_closed) return;
    final interval = CustomAdScope.policyOf(
      context,
    ).rotationInterval(widget.interval);
    if (interval == _interval) return;
    _interval = interval;
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      if (_paused || widget.ads.length < 2) return;
      setState(() => _index = (_index + 1) % widget.ads.length);
    });
  }

  void _close(AdData _) {
    _timer?.cancel();
    setState(() => _closed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_closed) return const SizedBox.shrink();

    final ad = widget.ads[_index];
    return MouseRegion(
      onEnter: (_) => _paused = true,
      onExit: (_) => _paused = false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: CustomAd(
          key: ValueKey(ad.id),
          ad: ad,
          format: widget.format,
          style: widget.style,
          builder: widget.builder,
          dismissible: widget.dismissible,
          onClose: _close,
          onTap: widget.onTap,
          onImpression: widget.onImpression,
        ),
      ),
    );
  }
}
