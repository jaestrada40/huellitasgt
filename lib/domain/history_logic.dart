import 'enums.dart';
import 'models.dart';
import 'text.dart';

String _haystack(HealthEvent e) => foldText(
      [e.title, e.product, e.notes, e.vetName, e.clinic, e.lot].whereType<String>().join(' '),
    );

List<HealthEvent> filterEvents(
  List<HealthEvent> events, {
  EventType? type,
  String query = '',
}) {
  final q = foldText(query.trim());
  return [
    for (final e in events)
      if ((type == null || e.type == type) && (q.isEmpty || _haystack(e).contains(q))) e,
  ];
}

class MonthGroup {
  MonthGroup(this.year, this.month, this.events);
  final int year;
  final int month;
  final List<HealthEvent> events;
}

List<MonthGroup> groupByMonth(List<HealthEvent> events) {
  final sorted = [...events]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  final groups = <MonthGroup>[];
  for (final e in sorted) {
    final last = groups.isEmpty ? null : groups.last;
    if (last != null && last.year == e.occurredAt.year && last.month == e.occurredAt.month) {
      last.events.add(e);
    } else {
      groups.add(MonthGroup(e.occurredAt.year, e.occurredAt.month, [e]));
    }
  }
  return groups;
}
