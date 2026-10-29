import 'package:flutter/material.dart';

import '../event_log.dart';

/// What a real app would send to analytics: impressions, clicks, closes.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: eventLog,
      builder: (context, _) {
        final events = eventLog.events;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final type in AdEventType.values)
                    Chip(
                      avatar: Icon(type.icon, size: 16),
                      label: Text('${type.label}: ${eventLog.count(type)}'),
                    ),
                  TextButton.icon(
                    onPressed: events.isEmpty ? null : eventLog.clear,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Impressions and clicks come from CustomAdScope (set up once in '
                'main.dart). Closes and custom onTap events come from the '
                'per-ad callbacks on the Behavior page.',
              ),
            ),
            const Divider(height: 32),
            Expanded(
              child: events.isEmpty
                  ? const Center(
                      child: Text(
                        'No events yet. Browse the other pages '
                        'and click on an ad.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, i) {
                        final e = events[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(e.type.icon),
                          title: Text(e.adId),
                          subtitle: Text(e.type.label),
                          trailing: Text(_time(e.time)),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
