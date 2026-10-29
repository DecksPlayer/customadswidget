import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ad_config.dart';

/// Downloads the client's ads JSON and keeps it up to date.
///
/// Create it once (usually in [CustomAdScope]) and every [AdSlot] shares
/// it. If a refresh fails, the last valid configuration keeps being shown.
class RemoteAdSource extends ChangeNotifier {
  RemoteAdSource(
    this.url, {
    this.refreshInterval,
    this.headers = const {},
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final Uri url;

  /// When set, the JSON is requested again periodically to pick up new
  /// banners without reloading the page.
  final Duration? refreshInterval;

  /// Extra headers, for example a client API key.
  final Map<String, String> headers;

  final http.Client _client;
  final bool _ownsClient;
  AdConfig? _config;
  Object? _error;
  Future<void>? _inFlight;
  Timer? _refreshTimer;
  bool _disposed = false;

  AdConfig? get config => _config;

  /// Last loading error, null if the last load succeeded.
  Object? get error => _error;
  bool get isLoading => _inFlight != null;

  /// Loads the JSON if it hasn't been loaded yet and starts the periodic
  /// refresh. Safe to call many times: simultaneous requests are merged.
  Future<void> ensureLoaded() {
    if (refreshInterval != null && _refreshTimer == null) {
      _refreshTimer = Timer.periodic(refreshInterval!, (_) => reload());
    }
    if (_config != null) return Future.value();
    return reload();
  }

  Future<void> reload() =>
      _inFlight ??= _fetch().whenComplete(() {
        _inFlight = null;
        if (!_disposed) notifyListeners();
      });

  Future<void> _fetch() async {
    try {
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/json', ...headers},
      );
      if (response.statusCode != 200) {
        throw http.ClientException('HTTP ${response.statusCode}', url);
      }
      // JSON is UTF-8 even if the server sends no charset in Content-Type.
      // If it isn't valid UTF-8, the declared charset (or latin1) is used.
      String text;
      try {
        text = utf8.decode(response.bodyBytes);
      } on FormatException {
        text = response.body;
      }
      final json = jsonDecode(text);
      _config = AdConfig.fromJson(json as Map<String, dynamic>, baseUri: url);
      _error = null;
    } catch (e) {
      _error = e;
      debugPrint('customadswidget: could not load $url: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    if (_ownsClient) _client.close();
    super.dispose();
  }
}
