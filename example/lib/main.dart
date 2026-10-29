import 'package:customadswidget/customadswidget.dart';
import 'package:flutter/material.dart';

import 'event_log.dart';
import 'pages/behavior_page.dart';
import 'pages/builder_page.dart';
import 'pages/editor_page.dart';
import 'pages/events_page.dart';
import 'pages/formats_page.dart';
import 'pages/local_json_page.dart';
import 'pages/policy_page.dart';
import 'pages/remote_page.dart';
import 'pages/styles_page.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // The client's JSON URL. Here it's web/ads/ads.json, which Flutter serves
  // together with the app; in production it would be something like
  // Uri.parse('https://cdn.client.com/ads/ads.json').
  final _source = RemoteAdSource(
    Uri.base.resolve('ads/ads.json'),
    refreshInterval: const Duration(minutes: 5),
  );
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'customadswidget example',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      // A single scope for the whole app: remote source + analytics.
      builder: (context, child) => CustomAdScope(
        source: _source,
        onImpression: (ad) => eventLog.add(AdEventType.impression, ad),
        onClick: (ad) => eventLog.add(AdEventType.click, ad),
        child: child!,
      ),
      home: _Shell(
        source: _source,
        darkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: () => setState(
          () => _themeMode = _themeMode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
      ),
    );
  }
}

typedef _Page = ({IconData icon, String label, WidgetBuilder builder});

class _Shell extends StatefulWidget {
  const _Shell({
    required this.source,
    required this.darkMode,
    required this.onToggleTheme,
  });

  final RemoteAdSource source;
  final bool darkMode;
  final VoidCallback onToggleTheme;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _selected = 0;

  late final List<_Page> _pages = [
    (
      icon: Icons.cloud_download_outlined,
      label: 'Remote banners',
      builder: (_) => RemotePage(source: widget.source),
    ),
    (
      icon: Icons.verified_user_outlined,
      label: 'Non-intrusive',
      builder: (_) => const PolicyPage(),
    ),
    (
      icon: Icons.aspect_ratio,
      label: 'Formats',
      builder: (_) => const FormatsPage(),
    ),
    (
      icon: Icons.palette_outlined,
      label: 'Styles',
      builder: (_) => const StylesPage(),
    ),
    (
      icon: Icons.touch_app_outlined,
      label: 'Behavior',
      builder: (_) => const BehaviorPage(),
    ),
    (
      icon: Icons.brush_outlined,
      label: 'Custom design',
      builder: (_) => const BuilderPage(),
    ),
    (
      icon: Icons.inventory_2_outlined,
      label: 'Local JSON',
      builder: (_) => const LocalJsonPage(),
    ),
    (
      icon: Icons.edit_outlined,
      label: 'Editor',
      builder: (_) => const EditorPage(),
    ),
    (
      icon: Icons.analytics_outlined,
      label: 'Events',
      builder: (_) => const EventsPage(),
    ),
  ];

  void _select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final page = KeyedSubtree(
      key: ValueKey(_selected),
      child: _pages[_selected].builder(context),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_pages[_selected].label),
        actions: [
          const _EventCounters(),
          IconButton(
            tooltip: widget.darkMode ? 'Light theme' : 'Dark theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide
          ? null
          : NavigationDrawer(
              selectedIndex: _selected,
              onDestinationSelected: (i) {
                _select(i);
                Navigator.pop(context);
              },
              children: [
                const SizedBox(height: 16),
                for (final p in _pages)
                  NavigationDrawerDestination(
                    icon: Icon(p.icon),
                    label: Text(p.label),
                  ),
              ],
            ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  extended: true,
                  selectedIndex: _selected,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final p in _pages)
                      NavigationRailDestination(
                        icon: Icon(p.icon),
                        label: Text(p.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            )
          : page,
    );
  }
}

class _EventCounters extends StatelessWidget {
  const _EventCounters();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: eventLog,
    builder: (context, _) => Row(
      children: [
        for (final type in [AdEventType.impression, AdEventType.click])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Chip(
              avatar: Icon(type.icon, size: 16),
              label: Text('${eventLog.count(type)}'),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    ),
  );
}
