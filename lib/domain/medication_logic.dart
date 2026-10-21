import 'models.dart';
import 'reminder_plan.dart';

/// Horas entre dosis y duración que se leen de un texto como
/// «1 tab cada 24 horas durante 5 días» (lo que dice la receta, escrito o dictado).
({int? everyHours, int? days}) parseInstructions(String text) {
  final t = text.toLowerCase();
  final h = RegExp(r'cada\s+(\d{1,3})\s*(?:h|hr|hrs|hora|horas)\b').firstMatch(t);
  final d = RegExp(r'(?:por|durante|x)\s+(\d{1,3})\s*(d[ií]as?|semanas?|sem)\b').firstMatch(t);
  int? days;
  if (d != null) {
    final n = int.parse(d.group(1)!);
    days = d.group(2)!.startsWith('d') ? n : n * 7;
  }
  return (everyHours: h == null ? null : int.parse(h.group(1)!), days: days);
}

bool isValidSchedule(int everyHours, int days) =>
    everyHours >= 1 && everyHours <= 168 && days >= 1 && days <= 365;

int totalDoses(Medication m) => (m.days * 24 / m.everyHours).ceil().clamp(1, 1 << 20);

DateTime doseAt(Medication m, int index) => m.startAt.add(Duration(hours: m.everyHours * index));

class Dose {
  const Dose(this.medication, this.index, this.at, this.givenAt);
  final Medication medication;
  final int index;
  final DateTime at;
  final DateTime? givenAt;
  bool get given => givenAt != null;
}

List<Dose> dosesOf(Medication m, Iterable<DoseLog> logs) {
  final given = {
    for (final l in logs)
      if (l.medicationId == m.id) l.doseIndex: l.givenAt,
  };
  return [
    for (var i = 0; i < totalDoses(m); i++) Dose(m, i, doseAt(m, i), given[i]),
  ];
}

/// Una dosis sin marcar se considera olvidada (y se salta) si pasó más de la
/// mitad del intervalo entre dosis; si no, una dosis vieja se quedaría para siempre.
Duration _grace(Medication m) => Duration(hours: (m.everyHours / 2).ceil());

/// La dosis que toca ahora o la siguiente: la primera sin dar que no esté
/// olvidada. `null` si ya se dieron o pasaron todas (tratamiento terminado).
Dose? currentDose(Medication m, Iterable<DoseLog> logs, DateTime now) {
  for (final d in dosesOf(m, logs)) {
    if (d.given || d.at.isBefore(now.subtract(_grace(m)))) continue;
    return d;
  }
  return null;
}

/// Una dosis por tratamiento activo (la que toca ahora o la siguiente), por hora.
/// Al marcar una como dada pasa a la siguiente; los tratamientos terminados no salen.
List<Dose> pendingDoses(Iterable<Medication> meds, Iterable<DoseLog> logs, DateTime now) => [
      for (final m in meds)
        if (m.active) ?currentDose(m, logs, now),
    ]..sort((a, b) => a.at.compareTo(b.at));

/// Un tratamiento ya terminó si se dieron todas las dosis o pasó su última dosis.
bool isFinished(Medication m, Iterable<DoseLog> logs, DateTime now) {
  final given = logs.where((l) => l.medicationId == m.id).length;
  return given >= totalDoses(m) || now.isAfter(doseAt(m, totalDoses(m) - 1).add(const Duration(hours: 12)));
}

/// Un aviso por dosis pendiente. iOS permite 64 pendientes, así que se
/// devuelven solo las [max] más próximas; la ventana avanza cada vez que se
/// abre la app o se marca una dosis.
List<PlannedReminder> planMedicationReminders({
  required Iterable<Medication> meds,
  required Iterable<DoseLog> logs,
  required Map<String, String> petNames,
  required DateTime now,
  int max = 40,
}) {
  final out = <PlannedReminder>[];
  for (final m in meds) {
    final pet = petNames[m.petId];
    if (!m.active || !m.reminderEnabled || pet == null) continue;
    for (final d in dosesOf(m, logs)) {
      if (d.given || !d.at.isAfter(now)) continue;
      out.add(PlannedReminder(
        id: stableId('${m.id}#${d.index}'),
        treatmentId: m.id,
        fireAt: d.at,
        title: 'Medicina · $pet',
        body: m.instructions == null ? m.name : '${m.name}: ${m.instructions}',
      ));
    }
  }
  out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return out.length > max ? out.sublist(0, max) : out;
}
