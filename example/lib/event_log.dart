import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

enum AdEventType {
  impression('Impression', Icons.visibility_outlined),
  click('Click', Icons.ads_click),
  close('Close', Icons.close),
  tap('Custom onTap', Icons.touch_app_outlined);

  const AdEventType(this.label, this.icon);

  final String label;
  final IconData icon;
}

typedef AdEvent = ({DateTime time, AdEventType type, String adId});

/// In-memory log of what a real app would send to analytics.
class EventLog extends ChangeNotifier {
  final List<AdEvent> _events = [];

  /// Most recent first.
  List<AdEvent> get events => _events.reversed.toList();

  int count(AdEventType type) => _events.where((e) => e.type == type).length;

  void add(AdEventType type, AdData ad) {
    _events.add((time: DateTime.now(), type: type, adId: ad.id));
    if (_events.length > 500) _events.removeAt(0);
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }
}

final eventLog = EventLog();
