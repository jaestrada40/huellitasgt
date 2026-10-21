import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/medication_logic.dart';
import 'package:huellitas/domain/models.dart';

Medication med({int every = 12, int days = 7, DateTime? start, bool active = true}) => Medication(
      id: 'm1',
      petId: 'p1',
      name: 'Kiroftal',
      instructions: '2 gotas',
      everyHours: every,
      days: days,
      startAt: start ?? DateTime(2026, 10, 20, 8),
      active: active,
    );

void main() {
  group('parseInstructions (receta de Koko)', () {
    test('tableta cada 24 hrs por 3 semanas', () {
      final r = parseInstructions('DAR 1 TABLETA CADA 24 HRS POR 3 SEMANAS');
      expect((r.everyHours, r.days), (24, 21));
    });
    test('cada 24 horas durante 5 días', () {
      final r = parseInstructions('1 TAB CADA 24 HORAS DURANTE 5 DIAS ()');
      expect((r.everyHours, r.days), (24, 5));
    });
    test('2 gotas cada 12 hrs durante 7 días, esperar un minuto', () {
      final r = parseInstructions('2 GOTAS EN EL OJO DERECHO CADA 12 HRS DURANTE 7 DÍAS, ESPERAR UN MINUTO');
      expect((r.everyHours, r.days), (12, 7));
    });
    test('texto sin datos devuelve nulos', () {
      final r = parseInstructions('con la comida');
      expect((r.everyHours, r.days), (null, null));
    });
  });

  test('dosis totales: días*24/horas redondeado hacia arriba', () {
    expect(totalDoses(med(every: 12, days: 7)), 14);
    expect(totalDoses(med(every: 24, days: 21)), 21);
    expect(totalDoses(med(every: 5, days: 1)), 5);
  });

  test('la dosis n llega every horas después de la anterior', () {
    expect(doseAt(med(), 3), DateTime(2026, 10, 21, 20));
  });

  test('avisos: solo dosis futuras sin dar, ordenadas y con tope', () {
    final logs = [DoseLog(medicationId: 'm1', doseIndex: 2, givenAt: DateTime(2026, 10, 21, 7))];
    final plan = planMedicationReminders(
      meds: [med()],
      logs: logs,
      petNames: {'p1': 'Koko'},
      now: DateTime(2026, 10, 20, 9),
      max: 3,
    );
    // dosis 0 ya pasó; la 2 ya se dio -> 1, 3, 4
    expect(plan.map((r) => r.fireAt), [
      DateTime(2026, 10, 20, 20),
      DateTime(2026, 10, 21, 20),
      DateTime(2026, 10, 22, 8),
    ]);
    expect(plan.first.title, 'Medicina · Koko');
    expect(plan.first.body, 'Kiroftal: 2 gotas');
  });

  test('sin aviso si la mascota no existe (archivada) o el tratamiento está apagado', () {
    final now = DateTime(2026, 10, 20, 9);
    expect(planMedicationReminders(meds: [med()], logs: const [], petNames: const {}, now: now), isEmpty);
    expect(planMedicationReminders(meds: [med(active: false)], logs: const [], petNames: {'p1': 'K'}, now: now), isEmpty);
  });

  test('terminó cuando se dieron todas o pasó la última dosis', () {
    final m = med(every: 24, days: 2); // dosis: 20 y 21 a las 8
    expect(isFinished(m, const [], DateTime(2026, 10, 21, 9)), false);
    expect(isFinished(m, const [], DateTime(2026, 10, 22, 9)), true);
    final all = [for (var i = 0; i < 2; i++) DoseLog(medicationId: 'm1', doseIndex: i, givenAt: DateTime(2026, 10, 20))];
    expect(isFinished(m, all, DateTime(2026, 10, 20, 9)), true);
  });

  test('validación del horario', () {
    expect(isValidSchedule(12, 7), true);
    expect(isValidSchedule(0, 7), false);
    expect(isValidSchedule(12, 0), false);
    expect(isValidSchedule(200, 7), false);
  });

  group('pendingDoses: una fila por medicamento, la que toca o la siguiente', () {
    Medication daily(String id, {int hour = 8, int days = 21}) => Medication(
        id: id, petId: 'p1', name: 'Med $id', everyHours: 24, days: days, startAt: DateTime(2026, 10, 20, hour));
    DoseLog gave(String id, int i, DateTime at) => DoseLog(medicationId: id, doseIndex: i, givenAt: at);

    test('antes de darla sale la de hoy; al darla a las 8 pasa a la de mañana a las 8', () {
      final m = daily('a');
      final before = pendingDoses([m], const [], DateTime(2026, 10, 20, 7, 30));
      expect(before.single.at, DateTime(2026, 10, 20, 8));

      final after = pendingDoses([m], [gave('a', 0, DateTime(2026, 10, 20, 8, 2))], DateTime(2026, 10, 20, 8, 3));
      expect(after.single.at, DateTime(2026, 10, 21, 8)); // solo la de mañana
      expect(after.single.index, 1);
    });

    test('cada medicamento aporta una sola dosis, ordenadas por hora', () {
      final every12 = Medication(id: 'b', petId: 'p1', name: 'Gotas', everyHours: 12, days: 7, startAt: DateTime(2026, 10, 20, 8));
      final r = pendingDoses([daily('a', hour: 20), every12], const [], DateTime(2026, 10, 20, 7));
      expect(r.map((d) => d.medication.id), ['b', 'a']);
      expect(r.map((d) => d.at), [DateTime(2026, 10, 20, 8), DateTime(2026, 10, 20, 20)]);
    });

    test('un tratamiento terminado ya no sale (todas dadas, o ya pasó todo)', () {
      final m = daily('a', days: 2); // dosis: 20 y 21 a las 8
      final all = [gave('a', 0, DateTime(2026, 10, 20, 8)), gave('a', 1, DateTime(2026, 10, 21, 8))];
      expect(pendingDoses([m], all, DateTime(2026, 10, 21, 8, 5)), isEmpty);
      expect(pendingDoses([m], const [], DateTime(2026, 10, 25, 8)), isEmpty);
    });

    test('un tratamiento inactivo no sale', () {
      expect(pendingDoses([daily('a').copyWith(active: false)], const [], DateTime(2026, 10, 20, 7)), isEmpty);
    });

    test('una dosis olvidada se salta pasada la mitad del intervalo; antes, sigue como atrasada', () {
      final m = daily('a'); // 8:00, cada 24 h: se salta pasadas las 20:00
      expect(pendingDoses([m], const [], DateTime(2026, 10, 20, 18)).single.at, DateTime(2026, 10, 20, 8)); // atrasada
      expect(pendingDoses([m], const [], DateTime(2026, 10, 20, 21)).single.at, DateTime(2026, 10, 21, 8)); // olvidada
    });

    test('marcar una dosis anterior no cambia la actual; deshacer la devuelve', () {
      final m = daily('a');
      final now = DateTime(2026, 10, 20, 8, 3);
      expect(pendingDoses([m], [gave('a', 0, now)], now).single.index, 1);
      expect(pendingDoses([m], const [], now).single.index, 0); // sin la marca vuelve la de las 8
    });
  });
}
