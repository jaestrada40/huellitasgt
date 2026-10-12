import 'dates.dart';
import 'models.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.treatmentId,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  final int id;
  final String treatmentId;
  final DateTime fireAt; // hora local
  final String title;
  final String body;
}

/// FNV-1a de 32 bits. `String.hashCode` no es estable entre ejecuciones.
int stableId(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h & 0x7FFFFFFF;
}

/// Un aviso por tratamiento activo (su siguiente vencimiento). iOS permite 64
/// pendientes; se devuelven como máximo [max], los más próximos.
List<PlannedReminder> planReminders({
  required Iterable<Treatment> treatments,
  required Map<String, String> petNames,
  required DateTime now,
  int hour = 9,
  int minute = 0,
  int max = 60,
}) {
  DateTime at(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute);

  final out = <PlannedReminder>[];
  for (final t in treatments) {
    if (!t.active || !t.reminderEnabled) continue;
    final pet = petNames[t.petId];
    if (pet == null) continue; // mascota archivada o inexistente

    final due = t.nextDueDate;
    final early = at(DateTime.utc(due.year, due.month, due.day - t.reminderDaysBefore));
    final onDue = at(due);
    final DateTime fireAt;
    if (early.isAfter(now)) {
      fireAt = early;
    } else if (onDue.isAfter(now)) {
      fireAt = onDue;
    } else {
      continue;
    }

    final days = daysUntil(due, fireAt);
    out.add(PlannedReminder(
      id: stableId(t.id),
      treatmentId: t.id,
      fireAt: fireAt,
      title: '${t.name} · $pet',
      body: days <= 0 ? 'Toca hoy' : 'Vence en $days ${days == 1 ? 'día' : 'días'}',
    ));
  }
  out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return out.length > max ? out.sublist(0, max) : out;
}
