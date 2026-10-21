import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/models.dart';

void main() {
  test('una base de la versión 3 sube a la 4 sin perder mascotas y con las tablas nuevas', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE pets (
          id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, species TEXT NOT NULL, breed TEXT, sex TEXT,
          neutered INTEGER NOT NULL DEFAULT 0, birth_date INTEGER, microchip TEXT, photo_path TEXT,
          photo_focus_x REAL NOT NULL DEFAULT 0, photo_focus_y REAL NOT NULL DEFAULT 0,
          photo_zoom REAL NOT NULL DEFAULT 1, allergies_notes TEXT, vet_name TEXT, vet_clinic TEXT,
          vet_phone TEXT, created_at INTEGER NOT NULL, archived INTEGER NOT NULL DEFAULT 0
        )''');
      raw.execute("INSERT INTO pets (id, name, species, created_at) VALUES ('koko', 'Koko', 'dog', 1700000000)");
      raw.execute('PRAGMA user_version = 3');
    }));
    addTearDown(db.close);

    final pets = await DriftPetRepository(db).all();
    expect(pets.single.name, 'Koko');
    expect(pets.single.adoptionDate, isNull);
    expect(pets.single.inMemoriam, isFalse);

    final meds = DriftMedicationRepository(db);
    await meds.saveAll([
      Medication(id: 'm', petId: 'koko', name: 'Numelvi', everyHours: 24, days: 21, startAt: DateTime(2026, 10, 20, 9)),
    ]);
    expect((await meds.all()).single.name, 'Numelvi');
    final care = DriftCareRepository(db);
    expect(await care.foods(), isEmpty);
  });
}
