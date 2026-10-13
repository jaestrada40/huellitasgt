import 'package:drift/drift.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../domain/text.dart';
import 'database.dart';
import 'mappers.dart';

class DriftPetRepository implements PetRepository {
  DriftPetRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Pet>> watchAll() => (_db.select(_db.pets)
        ..where((t) => t.archived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map(petFromRow).toList());

  @override
  Future<List<Pet>> all() async => (await (_db.select(_db.pets)
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get())
      .map(petFromRow)
      .toList();

  @override
  Future<Pet?> get(String id) async {
    final r = await (_db.select(_db.pets)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : petFromRow(r);
  }

  @override
  Future<void> save(Pet pet) => _db.into(_db.pets).insertOnConflictUpdate(petToCompanion(pet));

  @override
  Future<void> archive(String id) => (_db.update(_db.pets)..where((t) => t.id.equals(id)))
      .write(const PetsCompanion(archived: Value(true)));
}

class DriftTreatmentRepository implements TreatmentRepository {
  DriftTreatmentRepository(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$TreatmentsTable, TreatmentRow> get _activeQuery =>
      _db.select(_db.treatments)
        ..where((t) => t.active.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]);

  @override
  Stream<List<Treatment>> watchActive() =>
      _activeQuery.watch().map((rows) => rows.map(treatmentFromRow).toList());

  @override
  Future<List<Treatment>> active() async =>
      (await _activeQuery.get()).map(treatmentFromRow).toList();

  @override
  Future<Treatment?> get(String id) async {
    final r = await (_db.select(_db.treatments)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : treatmentFromRow(r);
  }

  @override
  Future<Treatment?> find(String petId, EventType type, String name) async {
    final rows = await (_db.select(_db.treatments)
          ..where((t) => t.petId.equals(petId) & t.type.equalsValue(type)))
        .get();
    final key = normalizeName(name);
    for (final r in rows) {
      if (normalizeName(r.name) == key) return treatmentFromRow(r);
    }
    return null;
  }

  @override
  Future<void> save(Treatment t) =>
      _db.into(_db.treatments).insertOnConflictUpdate(treatmentToCompanion(t));
}

class DriftEventRepository implements EventRepository {
  DriftEventRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<HealthEvent>> watchForPet(String petId) => (_db.select(_db.healthEvents)
        ..where((t) => t.petId.equals(petId))
        ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
      .watch()
      .map((rows) => rows.map(eventFromRow).toList());

  @override
  Future<HealthEvent?> get(String id) async {
    final r = await (_db.select(_db.healthEvents)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : eventFromRow(r);
  }

  @override
  Future<List<Attachment>> attachmentsFor(String eventId) async =>
      (await (_db.select(_db.attachments)..where((t) => t.eventId.equals(eventId))).get())
          .map(attachmentFromRow)
          .toList();

  @override
  Future<void> save(HealthEvent e, List<Attachment> attachments) => _db.transaction(() async {
        await _db.into(_db.healthEvents).insertOnConflictUpdate(eventToCompanion(e));
        await (_db.delete(_db.attachments)..where((t) => t.eventId.equals(e.id))).go();
        for (final a in attachments) {
          await _db.into(_db.attachments).insert(attachmentToCompanion(a));
        }
      });

  @override
  Future<void> addAttachment(Attachment a) =>
      _db.into(_db.attachments).insert(attachmentToCompanion(a));

  @override
  Future<String?> removeAttachment(String id) => _db.transaction(() async {
        final row = await (_db.select(_db.attachments)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        await (_db.delete(_db.attachments)..where((t) => t.id.equals(id))).go();
        return row.relativePath;
      });

  @override
  Future<List<String>> delete(String id) => _db.transaction(() async {
        final rows = await (_db.select(_db.attachments)..where((t) => t.eventId.equals(id))).get();
        await (_db.delete(_db.attachments)..where((t) => t.eventId.equals(id))).go();
        await (_db.delete(_db.healthEvents)..where((t) => t.id.equals(id))).go();
        return rows.map((r) => r.relativePath).toList();
      });
}

class DriftWeightRepository implements WeightRepository {
  DriftWeightRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<WeightEntry>> watchForPet(String petId) => (_db.select(_db.weightEntries)
        ..where((t) => t.petId.equals(petId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch()
      .map((rows) => rows.map(weightFromRow).toList());

  @override
  Future<void> save(WeightEntry w) =>
      _db.into(_db.weightEntries).insertOnConflictUpdate(weightToCompanion(w));

  @override
  Future<void> delete(String id) =>
      (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();
}
