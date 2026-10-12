import 'dates.dart';
import 'enums.dart';
import 'models.dart';
import 'treatment_status.dart';

const int backupReminderDays = 30;

/// Días de anticipación para mostrar un tratamiento en «Lo que toca pronto».
const int soonWindowDays = 30;

class HomeItem {
  const HomeItem(this.treatment, this.status, this.label);
  final Treatment treatment;
  final DueStatus status;
  final String label;
}

List<HomeItem> homeItems(Iterable<Treatment> treatments, DateTime today) {
  final list = treatments.where((t) => t.active).toList()
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  return [
    for (final t in list)
      HomeItem(t, dueStatus(t.nextDueDate, today), dueLabel(t.nextDueDate, today)),
  ];
}

bool needsBackupReminder({
  required DateTime? lastBackup,
  required DateTime now,
  required bool hasData,
}) {
  if (!hasData) return false;
  if (lastBackup == null) return true;
  return now.difference(lastBackup).inDays >= backupReminderDays;
}

class HomeSections {
  const HomeSections(this.pending, this.upToDate);

  /// Atrasados o que vencen dentro de [soonWindowDays] días, por fecha.
  final List<HomeItem> pending;

  /// Tratamientos activos que vencen más adelante.
  final List<Treatment> upToDate;
}

HomeSections homeSections(Iterable<Treatment> treatments, DateTime today) {
  final all = homeItems(treatments, today);
  return HomeSections(
    [for (final i in all) if (daysUntil(i.treatment.nextDueDate, today) <= soonWindowDays) i],
    [for (final i in all) if (daysUntil(i.treatment.nextDueDate, today) > soonWindowDays) i.treatment],
  );
}

int countByType(Iterable<Treatment> treatments, EventType type) =>
    treatments.where((t) => t.type == type).length;

/// Vacunas, desparasitaciones y antipulgas aplicadas en el mes de [today].
int appliedThisMonth(Iterable<HealthEvent> events, DateTime today) => events
    .where((e) =>
        e.type.canRecur && e.occurredAt.year == today.year && e.occurredAt.month == today.month)
    .length;
