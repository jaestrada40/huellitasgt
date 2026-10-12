import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_repositories.dart';
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
    expect(scheduler.last.map((r) => r.treatmentId), ['t1', 't2']);
  });

  test('una mascota archivada deja de generar avisos', () async {
    await pets.save(samplePet());
    await treatments.save(sampleTreatment());
    await coordinator.sync();
    expect(scheduler.last.length, 1);

    await pets.archive('p1');
    await coordinator.sync();
    expect(scheduler.last, isEmpty);
  });
}
