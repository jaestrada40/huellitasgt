import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/services/app_prefs.dart';
import 'package:huellitas/services/reminder_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/samples.dart';

void main() {
  late AppDatabase db;
  late FakeScheduler scheduler;
  late ReminderCoordinator coordinator;
  late DriftPetRepository pets;
  late DriftTreatmentRepository treatments;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.memory();
    pets = DriftPetRepository(db);
    treatments = DriftTreatmentRepository(db);
    scheduler = FakeScheduler();
    coordinator = ReminderCoordinator(
      pets: pets,
      treatments: treatments,
      medications: DriftMedicationRepository(db),
      care: DriftCareRepository(db),
      scheduler: scheduler,
      prefs: await AppPrefs.load(),
      now: () => DateTime(2024, 10, 20, 8),
    );
  });
  tearDown(() => db.close());

  test('programa el siguiente vencimiento de cada tratamiento activo', () async {
    await pets.save(samplePet());
    await treatments.save(sampleTreatment());
    await treatments.save(sampleTreatment(id: 't2', name: 'NexGard', nextDue: DateTime.utc(2024, 11, 5)));
    await coordinator.sync();
    // t1 y t2 por vencimiento, y el cumpleaños de la mascota (p1) de ejemplo.
    expect(scheduler.last.map((r) => r.treatmentId), ['t1', 't2', 'p1']);
  });

  test('una mascota archivada deja de generar avisos', () async {
    await pets.save(samplePet());
    await treatments.save(sampleTreatment());
    await coordinator.sync();
    expect(scheduler.last.length, 2); // vacuna + cumpleaños

    await pets.archive('p1');
    await coordinator.sync();
    expect(scheduler.last, isEmpty);
  });

  test('las dosis de medicina se programan y una dosis dada deja de avisar', () async {
    await pets.save(samplePet());
    final meds = DriftMedicationRepository(db);
    await meds.saveAll([
      Medication(
        id: 'm1',
        petId: 'p1',
        name: 'Numelvi',
        everyHours: 24,
        days: 3,
        startAt: DateTime(2024, 10, 20, 12),
      ),
    ]);
    await coordinator.sync();
    final doses = scheduler.last.where((r) => r.treatmentId == 'm1').toList();
    expect(doses.map((r) => r.fireAt.day), [20, 21, 22]);

    await meds.setDose('m1', 0, DateTime(2024, 10, 20, 12, 5));
    await coordinator.sync();
    expect(scheduler.last.where((r) => r.treatmentId == 'm1').map((r) => r.fireAt.day), [21, 22]);
  });

  test('si el teléfono rechaza programar avisos (sin permiso) sync no falla ni interrumpe al llamador', () async {
    await pets.save(samplePet());
    await treatments.save(sampleTreatment());
    scheduler.failWith = StateError('Source is not authorized');
    await coordinator.sync(); // no lanza
    expect(scheduler.syncCount, 0);
  });
}
