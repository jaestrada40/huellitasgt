import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/backup_data.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/services/backup_codec.dart';

void main() {
  final now = DateTime(2024, 10, 2, 12);
  final pet = Pet(
    id: 'p1',
    name: 'Koko',
    species: PetSpecies.dog,
    createdAt: DateTime(2024, 1, 1, 8),
    photoPath: 'attachments/koko.jpg',
    photoFocusX: -0.25,
    photoFocusY: 0.6,
    photoZoom: 2.5,
  );

  test('el enfoque de la foto se guarda y se lee', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = DriftPetRepository(db);
    await repo.save(pet);
    final p = (await repo.get('p1'))!;
    expect(p.photoFocusX, -0.25);
    expect(p.photoFocusY, 0.6);
    expect(p.photoZoom, 2.5);
  });

  test('sin enfoque guardado, la foto queda centrada', () {
    final p = Pet(id: 'x', name: 'X', species: PetSpecies.cat, createdAt: _epoch);
    expect(p.photoFocusX, 0);
    expect(p.photoFocusY, 0);
  });

  test('el respaldo conserva el enfoque', () {
    final data = BackupData(pets: [pet], weights: const [], treatments: const [], events: const [], attachments: const []);
    final back = backupFromJson(backupToJson(data, schemaVersion: 1, exportedAt: now));
    expect(back.pets.single.photoFocusX, -0.25);
    expect(back.pets.single.photoFocusY, 0.6);
    expect(back.pets.single.photoZoom, 2.5);
  });

  test('un respaldo anterior, sin enfoque, se restaura con la foto centrada', () {
    final data = BackupData(pets: [pet], weights: const [], treatments: const [], events: const [], attachments: const []);
    final json = backupToJson(data, schemaVersion: 1, exportedAt: now);
    for (final p in json['pets'] as List) {
      (p as Map<String, dynamic>)
        ..remove('photoFocusX')
        ..remove('photoFocusY')
        ..remove('photoZoom');
    }
    final back = backupFromJson(json);
    expect(back.pets.single.photoFocusX, 0);
    expect(back.pets.single.photoFocusY, 0);
    expect(back.pets.single.photoZoom, 1);
  });

  test('migración v1 a v2: conserva las mascotas y las deja centradas', () async {
    // Una base «de antes»: tabla pets sin las columnas de enfoque, versión 1.
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE pets (
          id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, species TEXT NOT NULL,
          breed TEXT NULL, sex TEXT NULL, neutered INTEGER NOT NULL DEFAULT 0,
          birth_date INTEGER NULL, microchip TEXT NULL, photo_path TEXT NULL,
          allergies_notes TEXT NULL, vet_name TEXT NULL, vet_clinic TEXT NULL,
          vet_phone TEXT NULL, created_at INTEGER NOT NULL, archived INTEGER NOT NULL DEFAULT 0
        )''');
      raw.execute("INSERT INTO pets (id, name, species, photo_path, created_at) VALUES ('old', 'Koko', 'dog', 'attachments/k.jpg', 1700000000)");
      raw.execute('PRAGMA user_version = 1');
    });
    final db = AppDatabase(executor);
    addTearDown(db.close);
    final p = (await DriftPetRepository(db).get('old'))!;
    expect(p.name, 'Koko');
    expect(p.photoPath, 'attachments/k.jpg');
    expect(p.photoFocusX, 0);
    expect(p.photoFocusY, 0);
    expect(p.photoZoom, 1);
  });

  test('migración v2 a v3: conserva el enfoque ya elegido y agrega zoom 1', () async {
    final executor = NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE pets (
          id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, species TEXT NOT NULL,
          breed TEXT NULL, sex TEXT NULL, neutered INTEGER NOT NULL DEFAULT 0,
          birth_date INTEGER NULL, microchip TEXT NULL, photo_path TEXT NULL,
          photo_focus_x REAL NOT NULL DEFAULT 0, photo_focus_y REAL NOT NULL DEFAULT 0,
          allergies_notes TEXT NULL, vet_name TEXT NULL, vet_clinic TEXT NULL,
          vet_phone TEXT NULL, created_at INTEGER NOT NULL, archived INTEGER NOT NULL DEFAULT 0
        )''');
      raw.execute("INSERT INTO pets (id, name, species, photo_focus_x, photo_focus_y, created_at) VALUES ('v2', 'Koko', 'dog', 0.5, -0.4, 1700000000)");
      raw.execute('PRAGMA user_version = 2');
    });
    final db = AppDatabase(executor);
    addTearDown(db.close);
    final p = (await DriftPetRepository(db).get('v2'))!;
    expect(p.photoFocusX, 0.5);
    expect(p.photoFocusY, -0.4);
    expect(p.photoZoom, 1);
  });
}

final _epoch = DateTime(2024);
