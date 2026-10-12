import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/reminder_plan.dart';

import '../helpers/samples.dart';

void main() {
  final names = {'p1': 'Toby'};

  test('avisa a las 9:00 locales, 3 días antes', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2024, 10, 29))],
      petNames: names,
      now: DateTime(2024, 10, 20, 8),
    );
    expect(plan.single.fireAt, DateTime(2024, 10, 26, 9));
    expect(plan.single.title, 'Antirrábica · Toby');
    expect(plan.single.body, 'Vence en 3 días');
  });

  test('si el aviso anticipado ya pasó pero el vencimiento no, avisa el día de vencimiento', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2024, 10, 29))],
      petNames: names,
      now: DateTime(2024, 10, 27, 10),
    );
    expect(plan.single.fireAt, DateTime(2024, 10, 29, 9));
    expect(plan.single.body, 'Toca hoy');
  });

  test('atrasada o ya pasada la hora del día de vencimiento: no programa nada', () {
    final due = sampleTreatment(nextDue: DateTime.utc(2024, 10, 29));
    expect(planReminders(treatments: [due], petNames: names, now: DateTime(2024, 10, 29, 9, 30)), isEmpty);
    expect(planReminders(treatments: [due], petNames: names, now: DateTime(2024, 11, 5)), isEmpty);
  });

  test('omite inactivos, sin recordatorio y mascotas archivadas (ausentes del mapa)', () {
    final now = DateTime(2024, 10, 20);
    expect(planReminders(treatments: [sampleTreatment(active: false)], petNames: names, now: now), isEmpty);
    expect(planReminders(treatments: [sampleTreatment(reminderEnabled: false)], petNames: names, now: now), isEmpty);
    expect(planReminders(treatments: [sampleTreatment(petId: 'archivada')], petNames: names, now: now), isEmpty);
  });

  test('respeta hora y minuto configurados', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2024, 10, 29))],
      petNames: names,
      now: DateTime(2024, 10, 20),
      hour: 18,
      minute: 30,
    );
    expect(plan.single.fireAt, DateTime(2024, 10, 26, 18, 30));
  });

  test('máximo 60, conserva los más próximos y ordena por fecha', () {
    final list = [
      for (var i = 0; i < 70; i++)
        sampleTreatment(id: 't$i', nextDue: DateTime.utc(2025, 1, 1).add(Duration(days: i))),
    ];
    final plan = planReminders(treatments: list.reversed, petNames: names, now: DateTime(2024, 12, 1));
    expect(plan.length, 60);
    expect(plan.first.treatmentId, 't0');
    expect(plan.last.treatmentId, 't59');
  });

  test('el aviso sale a las 9:00 locales también en un cambio de horario (TZ=America/New_York)', () {
    final plan = planReminders(
      treatments: [sampleTreatment(nextDue: DateTime.utc(2025, 3, 10), reminderDaysBefore: 1)],
      petNames: names,
      now: DateTime(2025, 3, 1),
    );
    expect(plan.single.fireAt.hour, 9);
    expect(plan.single.fireAt.day, 9);
  });

  test('stableId es determinista, no negativo y distinto entre ids', () {
    expect(stableId('abc'), stableId('abc'));
    expect(stableId('abc'), isNot(stableId('abd')));
    expect(stableId('cualquier-uuid-largo-1234'), greaterThanOrEqualTo(0));
  });
}
