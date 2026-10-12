import 'dates.dart';
import 'models.dart';

enum DueStatus { overdue, dueSoon, upcoming }

DueStatus dueStatus(DateTime nextDue, DateTime today) {
  final days = daysUntil(nextDue, today);
  if (days < 0) return DueStatus.overdue;
  if (days <= 7) return DueStatus.dueSoon;
  return DueStatus.upcoming;
}

String _days(int n) => '$n ${n == 1 ? 'día' : 'días'}';

String dueLabel(DateTime nextDue, DateTime today) {
  final days = daysUntil(nextDue, today);
  if (days < 0) return 'Atrasada ${_days(-days)}';
  if (days == 0) return 'Hoy';
  return 'Vence en ${_days(days)}';
}

/// Porcentaje de tratamientos activos que no están atrasados.
/// Sin tratamientos activos devuelve 100.
int percentUpToDate(Iterable<Treatment> treatments, DateTime today) {
  final active = treatments.where((t) => t.active).toList();
  if (active.isEmpty) return 100;
  final ok = active.where((t) => daysUntil(t.nextDueDate, today) >= 0).length;
  return (ok * 100 / active.length).round();
}
