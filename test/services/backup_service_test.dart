import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_backup_store.dart';
import 'package:huellitas/domain/backup_data.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/services/backup_codec.dart';
import 'package:huellitas/services/backup_service.dart';

import '../helpers/samples.dart';

class ThrowingStore extends DriftBackupStore {
  ThrowingStore(super.db);
  @override
  Future<void> replaceAll(BackupData data) async => throw StateError('falla simulada');
}

void main() {
  late AppDatabase dbA;
  late AppDatabase dbB;
  late Directory rootA;
  late Directory rootB;
  late Directory out;
  final now = DateTime(2024, 10, 2, 12);

  BackupService serviceFor(AppDatabase db, Directory root, {DriftBackupStore? store}) => BackupService(
        store: store ?? DriftBackupStore(db),
        root: root,
        now: () => now,
      );

  String canonical(BackupData d) => jsonEncode(backupToJson(d, schemaVersion: 1, exportedAt: now));

  Future<void> seed() async {
    File('${rootA.path}/attachments/pet1.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('foto-mascota');
    File('${rootA.path}/attachments/a1.jpg').writeAsStringSync('foto-carnet');
    await DriftBackupStore(dbA).replaceAll(BackupData(
      pets: [samplePet(photoPath: 'attachments/pet1.jpg')],
      weights: const [],
      treatments: [sampleTreatment()],
      events: [sampleEvent(treatmentId: 't1')],
      attachments: [sampleAttachment()],
      medications: [
        Medication(
          id: 'm1',
          petId: 'p1',
          eventId: 'e1',
          name: 'Numelvi',
          instructions: '1 tableta cada 24 hrs',
          everyHours: 24,
          days: 21,
          startAt: DateTime(2024, 10, 19, 12),
        ),
      ],
      doseLogs: [DoseLog(medicationId: 'm1', doseIndex: 0, givenAt: DateTime(2024, 10, 19, 12, 3))],
      routines: [Routine(id: 'r1', petId: 'p1', name: 'Baño', everyDays: 15, lastDoneAt: DateTime(2024, 10, 1, 9))],
      foods: [FoodStock(id: 'f1', petId: 'p1', brand: 'Pro Plan', bagKg: 15, gramsPerDay: 300, openedOn: DateTime.utc(2024, 10, 1))],
      expenses: [
        Expense(id: 'x1', petId: 'p1', date: DateTime.utc(2024, 10, 3), amount: 150.5, category: ExpenseCategory.vet, note: 'Consulta'),
      ],
    ));
  }

  File zipWith(Map<String, List<int>> files, String name) {
    final a = Archive();
    files.forEach((path, bytes) => a.addFile(ArchiveFile(path, bytes.length, bytes)));
    final f = File('${out.path}/$name')..writeAsBytesSync(ZipEncoder().encode(a));
    return f;
  }

  Map<String, dynamic> json({int version = 1, List<Map<String, dynamic>>? attachments, String? petPhoto}) {
    final data = BackupData(
      pets: [samplePet(photoPath: petPhoto)],
      weights: const [],
      treatments: const [],
      events: [sampleEvent()],
      attachments: const [],
    );
    final j = backupToJson(data, schemaVersion: version, exportedAt: now);
    if (attachments != null) j['attachments'] = attachments;
    return j;
  }

  setUp(() {
    // Dos bases en memoria distintas simulan dos teléfonos.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dbA = AppDatabase.memory();
    dbB = AppDatabase.memory();
    rootA = Directory.systemTemp.createTempSync('huellitas_a_');
    rootB = Directory.systemTemp.createTempSync('huellitas_b_');
    out = Directory.systemTemp.createTempSync('huellitas_out_');
  });
  tearDown(() async {
    await dbA.close();
    await dbB.close();
    for (final d in [rootA, rootB, out]) {
      d.deleteSync(recursive: true);
    }
  });

  test('exportar e importar en otro teléfono devuelve los mismos datos y archivos', () async {
    await seed();
    final zip = await serviceFor(dbA, rootA).export(out);
    expect(zip.path.endsWith('huellitas-2024-10-02.zip'), isTrue);

    final b = serviceFor(dbB, rootB);
    final prepared = await b.prepare(zip);
    expect(prepared.summary.pets, 1);
    expect(prepared.summary.events, 1);
    await b.commit(prepared);

    final a = await DriftBackupStore(dbA).readAll();
    final c = await DriftBackupStore(dbB).readAll();
    expect(canonical(c), canonical(a));
    expect(c.medications.single.name, 'Numelvi');
    expect(c.doseLogs.single.doseIndex, 0);
    expect(c.routines.single.everyDays, 15);
    expect(c.foods.single.brand, 'Pro Plan');
    expect(c.expenses.single.amount, 150.5);
    expect(File('${rootB.path}/attachments/a1.jpg').readAsStringSync(), 'foto-carnet');
    expect(File('${rootB.path}/attachments/pet1.jpg').readAsStringSync(), 'foto-mascota');
    expect(Directory('${rootB.path}/.import_tmp').existsSync(), isFalse);
  });

  test('importar reemplaza los datos y archivos anteriores', () async {
    await seed();
    final zip = await serviceFor(dbA, rootA).export(out);

    File('${rootB.path}/attachments/viejo.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('viejo');
    await DriftBackupStore(dbB).replaceAll(BackupData(
      pets: [samplePet(id: 'otra', name: 'Otra')],
      weights: const [],
      treatments: const [],
      events: const [],
      attachments: const [],
    ));

    final b = serviceFor(dbB, rootB);
    await b.commit(await b.prepare(zip));
    expect((await DriftBackupStore(dbB).readAll()).pets.map((p) => p.id), ['p1']);
    expect(File('${rootB.path}/attachments/viejo.jpg').existsSync(), isFalse);
    expect(Directory('${rootB.path}/attachments.old').existsSync(), isFalse);
  });

  test('un respaldo de la versión 1 (sin medicinas, rutinas, comida ni gastos) se importa', () async {
    final j = json();
    for (final k in ['medications', 'doseLogs', 'routines', 'foods', 'expenses']) {
      j.remove(k);
    }
    for (final p in (j['pets'] as List).cast<Map<String, dynamic>>()) {
      p.remove('adoptionDate');
      p.remove('memorialDate');
    }
    j['schemaVersion'] = 1;
    final zip = zipWith({'backup.json': utf8.encode(jsonEncode(j))}, 'v1.zip');
    final b = serviceFor(dbB, rootB);
    await b.commit(await b.prepare(zip));
    final data = await DriftBackupStore(dbB).readAll();
    expect(data.pets.single.adoptionDate, isNull);
    expect(data.medications, isEmpty);
  });

  test('un respaldo de versión más nueva se rechaza', () async {
    final zip = zipWith({'backup.json': utf8.encode(jsonEncode(json(version: 99)))}, 'nuevo.zip');
    await expectLater(serviceFor(dbB, rootB).prepare(zip), throwsA(isA<BackupException>()));
  });

  test('un archivo que no es zip o sin backup.json se rechaza', () async {
    final basura = File('${out.path}/basura.zip')..writeAsStringSync('no soy un zip');
    await expectLater(serviceFor(dbB, rootB).prepare(basura), throwsA(isA<BackupException>()));
    final sinJson = zipWith({'otra.txt': utf8.encode('x')}, 'sin.zip');
    await expectLater(serviceFor(dbB, rootB).prepare(sinJson), throwsA(isA<BackupException>()));
  });

  test('si falta una foto referenciada se rechaza y no se tocan los datos', () async {
    await DriftBackupStore(dbB).replaceAll(BackupData(
      pets: [samplePet(id: 'intacta')],
      weights: const [],
      treatments: const [],
      events: const [],
      attachments: const [],
    ));
    final zip = zipWith({
      'backup.json': utf8.encode(jsonEncode(json(petPhoto: 'attachments/falta.jpg'))),
    }, 'falta.zip');
    await expectLater(serviceFor(dbB, rootB).prepare(zip), throwsA(isA<BackupException>()));
    expect((await DriftBackupStore(dbB).readAll()).pets.single.id, 'intacta');
  });

  test('rutas con ../ o absolutas se rechazan (zip-slip)', () async {
    for (final bad in ['../evil.jpg', 'attachments/../../evil.jpg', '/etc/passwd']) {
      final zip = zipWith({
        'backup.json': utf8.encode(jsonEncode(json(petPhoto: bad))),
        bad: utf8.encode('x'),
      }, 'slip.zip');
      await expectLater(serviceFor(dbB, rootB).prepare(zip), throwsA(isA<BackupException>()), reason: bad);
    }
    expect(File('${rootB.path}/../evil.jpg').existsSync(), isFalse);
  });

  test('si falla la escritura en la BD se restauran los archivos anteriores', () async {
    await seed();
    final zip = await serviceFor(dbA, rootA).export(out);

    File('${rootB.path}/attachments/viejo.jpg')
      ..createSync(recursive: true)
      ..writeAsStringSync('viejo');
    final b = serviceFor(dbB, rootB, store: ThrowingStore(dbB));
    final prepared = await b.prepare(zip);
    await expectLater(b.commit(prepared), throwsA(isA<BackupException>()));
    expect(File('${rootB.path}/attachments/viejo.jpg').readAsStringSync(), 'viejo');
    expect(File('${rootB.path}/attachments/a1.jpg').existsSync(), isFalse);
  });
}
