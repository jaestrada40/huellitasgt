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

class DriftMedicationRepository implements MedicationRepository {
  DriftMedicationRepository(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$MedicationsTable, MedicationRow> get _q =>
      _db.select(_db.medications)..orderBy([(t) => OrderingTerm.asc(t.startAt)]);

  @override
  Stream<List<Medication>> watchAll() => _q.watch().map((r) => r.map(medicationFromRow).toList());

  @override
  Future<List<Medication>> all() async => (await _q.get()).map(medicationFromRow).toList();

  @override
  Future<void> saveAll(List<Medication> meds) => _db.batch((b) {
        b.insertAllOnConflictUpdate(_db.medications, meds.map(medicationToCompanion));
      });

  @override
  Future<void> setActive(String id, bool active) =>
      (_db.update(_db.medications)..where((t) => t.id.equals(id)))
          .write(MedicationsCompanion(active: Value(active)));

  @override
  Stream<List<DoseLog>> watchLogs() =>
      _db.select(_db.doseLogs).watch().map((r) => r.map(doseLogFromRow).toList());

  @override
  Future<List<DoseLog>> logs() async =>
      (await _db.select(_db.doseLogs).get()).map(doseLogFromRow).toList();

  @override
  Future<void> setDose(String medicationId, int doseIndex, DateTime? at) async {
    if (at == null) {
      await (_db.delete(_db.doseLogs)
            ..where((t) => t.medicationId.equals(medicationId) & t.doseIndex.equals(doseIndex)))
          .go();
    } else {
      await _db.into(_db.doseLogs).insertOnConflictUpdate(
          doseLogToCompanion(DoseLog(medicationId: medicationId, doseIndex: doseIndex, givenAt: at)));
    }
  }
}

class DriftCareRepository implements CareRepository {
  DriftCareRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Routine>> watchRoutines(String petId) => (_db.select(_db.routines)
        ..where((t) => t.petId.equals(petId))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch()
      .map((r) => r.map(routineFromRow).toList());

  @override
  Future<void> saveRoutine(Routine r) =>
      _db.into(_db.routines).insertOnConflictUpdate(routineToCompanion(r));

  @override
  Future<void> deleteRoutine(String id) =>
      (_db.delete(_db.routines)..where((t) => t.id.equals(id))).go();

  @override
  Stream<List<FoodStock>> watchFoods(String petId) => (_db.select(_db.foodStocks)
        ..where((t) => t.petId.equals(petId)))
      .watch()
      .map((r) => r.map(foodFromRow).toList());

  @override
  Future<List<FoodStock>> foods() async =>
      (await _db.select(_db.foodStocks).get()).map(foodFromRow).toList();

  @override
  Future<void> saveFood(FoodStock f) =>
      _db.into(_db.foodStocks).insertOnConflictUpdate(foodToCompanion(f));

  @override
  Future<void> deleteFood(String id) =>
      (_db.delete(_db.foodStocks)..where((t) => t.id.equals(id))).go();

  @override
  Stream<List<Expense>> watchExpenses(String petId) => (_db.select(_db.expenses)
        ..where((t) => t.petId.equals(petId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch()
      .map((r) => r.map(expenseFromRow).toList());

  @override
  Future<void> saveExpense(Expense e) =>
      _db.into(_db.expenses).insertOnConflictUpdate(expenseToCompanion(e));

  @override
  Future<void> deleteExpense(String id) =>
      (_db.delete(_db.expenses)..where((t) => t.id.equals(id))).go();
}
