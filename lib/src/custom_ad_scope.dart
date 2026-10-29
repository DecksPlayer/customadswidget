import 'package:flutter/widgets.dart';

import 'models/ad_data.dart';
import 'models/ad_policy.dart';
import 'models/ad_style.dart';
import 'remote/remote_ad_source.dart';

typedef AdEventCallback = void Function(AdData ad);

/// Shared configuration for every [CustomAd] below this widget.
///
/// Place it once (for example in `MaterialApp.builder`) to set the default
/// style and connect analytics without repeating them on every ad.
class CustomAdScope extends InheritedWidget {
  const CustomAdScope({
    super.key,
    this.source,
    this.style,
    this.policy = AdPolicy.nonIntrusive,
    this.onImpression,
    this.onClick,
    required super.child,
  });

  /// Remote JSON that every [AdSlot] reads from.
  final RemoteAdSource? source;
  final AdStyle? style;

  /// Thresholds of the non-intrusive ads policy. Without a scope,
  /// [AdPolicy.nonIntrusive] is used.
  final AdPolicy policy;

  /// Fired once per mounted ad when at least 50% of it has been visible for
  /// 1 second (IAB viewability criterion).
  final AdEventCallback? onImpression;
  final AdEventCallback? onClick;

  /// Creates a scope that inherits from the enclosing scope everything that
  /// isn't passed. Useful to change the style of one section without losing
  /// the remote source or the analytics callbacks.
  static Widget merge({
    Key? key,
    RemoteAdSource? source,
    AdStyle? style,
    AdPolicy? policy,
    AdEventCallback? onImpression,
    AdEventCallback? onClick,
    required Widget child,
  }) => Builder(
    key: key,
    builder: (context) {
      final parent = maybeOf(context);
      return CustomAdScope(
        source: source ?? parent?.source,
        style: style ?? parent?.style,
        policy: policy ?? parent?.policy ?? AdPolicy.nonIntrusive,
        onImpression: onImpression ?? parent?.onImpression,
        onClick: onClick ?? parent?.onClick,
        child: child,
      );
    },
  );

  static CustomAdScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CustomAdScope>();

  static AdPolicy policyOf(BuildContext context) =>
      maybeOf(context)?.policy ?? AdPolicy.nonIntrusive;

  @override
  bool updateShouldNotify(CustomAdScope oldWidget) =>
      source != oldWidget.source ||
      style != oldWidget.style ||
      policy != oldWidget.policy ||
      onImpression != oldWidget.onImpression ||
      onClick != oldWidget.onClick;
}
