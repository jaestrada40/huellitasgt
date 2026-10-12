import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_backup_store.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/backup_data.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';

import '../helpers/samples.dart';

void main() {
  late AppDatabase db;
  late DriftPetRepository pets;
  late DriftTreatmentRepository treatments;
  late DriftEventRepository events;
  late DriftWeightRepository weights;

  setUp(() {
    db = AppDatabase.memory();
    pets = DriftPetRepository(db);
    treatments = DriftTreatmentRepository(db);
    events = DriftEventRepository(db);
    weights = DriftWeightRepository(db);
  });
  tearDown(() => db.close());

  test('mascota: guarda, lee y conserva la fecha de nacimiento como día UTC', () async {
    await pets.save(samplePet());
    final p = (await pets.get('p1'))!;
    expect(p.name, 'Toby');
    expect(p.species, PetSpecies.dog);
    expect(p.birthDate, DateTime.utc(2021, 6, 12)); // sin corrimiento por zona horaria
    expect(p.createdAt, DateTime(2024, 1, 1, 8));
  });

  test('archivar oculta de watchAll pero all() la conserva', () async {
    await pets.save(samplePet());
    await pets.save(samplePet(id: 'p2', name: 'Misi'));
    await pets.archive('p1');
    expect((await pets.watchAll().first).map((p) => p.id), ['p2']);
    expect((await pets.all()).map((p) => p.id), ['p1', 'p2']);
  });

  test('tratamiento: nextDueDate vuelve igual (día UTC)', () async {
    await treatments.save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 24)));
    final t = (await treatments.get('t1'))!;
    expect(t.nextDueDate, DateTime.utc(2024, 10, 24));
  });

  test('find ignora mayúsculas/espacios y distingue tipo; active() excluye inactivos', () async {
    await treatments.save(sampleTreatment());
    await treatments.save(sampleTreatment(id: 't2', name: 'Otra', active: false));
    expect((await treatments.find('p1', EventType.vaccine, '  antirrábica '))?.id, 't1');
    expect(await treatments.find('p1', EventType.deworming, 'Antirrábica'), isNull);
    expect(await treatments.find('p1', EventType.vaccine, 'Otra'), isNotNull);
    expect((await treatments.active()).map((t) => t.id), ['t1']);
  });

  test('evento: guardar reemplaza adjuntos y delete devuelve las rutas', () async {
    await events.save(sampleEvent(), [
      sampleAttachment(),
      sampleAttachment(id: 'a2', path: 'attachments/a2.jpg'),
    ]);
    expect((await events.attachmentsFor('e1')).length, 2);

    await events.save(sampleEvent(), [sampleAttachment(id: 'a3', path: 'attachments/a3.jpg')]);
    expect((await events.attachmentsFor('e1')).map((a) => a.id), ['a3']);

    final removed = await events.delete('e1');
    expect(removed, ['attachments/a3.jpg']);
    expect(await events.get('e1'), isNull);
    expect(await events.attachmentsFor('e1'), isEmpty);
  });

  test('eventos por mascota salen del más reciente al más antiguo', () async {
    await events.save(sampleEvent(id: 'old', occurredAt: DateTime(2024, 1, 1)), []);
    await events.save(sampleEvent(id: 'new', occurredAt: DateTime(2024, 9, 1)), []);
    expect((await events.watchForPet('p1').first).map((e) => e.id), ['new', 'old']);
  });

  test('peso: guarda, ordena y borra', () async {
    await weights.save(WeightEntry(id: 'w1', petId: 'p1', date: DateTime.utc(2024, 8, 3), kg: 28.2));
    await weights.save(WeightEntry(id: 'w2', petId: 'p1', date: DateTime.utc(2024, 10, 1), kg: 28.5));
    final list = await weights.watchForPet('p1').first;
    expect(list.map((w) => w.id), ['w2', 'w1']);
    expect(list.first.date, DateTime.utc(2024, 10, 1));
    await weights.delete('w2');
    expect((await weights.watchForPet('p1').first).length, 1);
  });

  test('BackupStore: replaceAll borra lo anterior y readAll devuelve lo nuevo', () async {
    await pets.save(samplePet(id: 'viejo'));
    final store = DriftBackupStore(db);
    await store.replaceAll(BackupData(
      pets: [samplePet()],
      weights: const [],
      treatments: [sampleTreatment()],
      events: [sampleEvent()],
      attachments: [sampleAttachment()],
    ));
    final data = await store.readAll();
    expect(data.pets.map((p) => p.id), ['p1']);
    expect(data.treatments.single.nextDueDate, DateTime.utc(2024, 10, 29));
    expect(data.events.single.id, 'e1');
    expect(data.attachments.single.relativePath, 'attachments/a1.jpg');
  });
}
