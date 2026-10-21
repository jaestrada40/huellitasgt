import 'package:drift/drift.dart';

import '../domain/backup_data.dart';
import '../domain/repositories.dart';
import 'database.dart';
import 'mappers.dart';

class DriftBackupStore implements BackupStore {
  DriftBackupStore(this._db);
  final AppDatabase _db;

  @override
  Future<BackupData> readAll() async {
    final pets = await (_db.select(_db.pets)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final weights =
        await (_db.select(_db.weightEntries)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final treatments =
        await (_db.select(_db.treatments)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final events =
        await (_db.select(_db.healthEvents)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final attachments =
        await (_db.select(_db.attachments)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final medications = await (_db.select(_db.medications)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final doseLogs = await _db.select(_db.doseLogs).get();
    final routines = await (_db.select(_db.routines)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final foods = await (_db.select(_db.foodStocks)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final expenses = await (_db.select(_db.expenses)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return BackupData(
      pets: pets.map(petFromRow).toList(),
      weights: weights.map(weightFromRow).toList(),
      treatments: treatments.map(treatmentFromRow).toList(),
      events: events.map(eventFromRow).toList(),
      attachments: attachments.map(attachmentFromRow).toList(),
      medications: medications.map(medicationFromRow).toList(),
      doseLogs: doseLogs.map(doseLogFromRow).toList(),
      routines: routines.map(routineFromRow).toList(),
      foods: foods.map(foodFromRow).toList(),
      expenses: expenses.map(expenseFromRow).toList(),
    );
  }

  @override
  Future<void> replaceAll(BackupData data) => _db.transaction(() async {
        await _db.delete(_db.expenses).go();
        await _db.delete(_db.foodStocks).go();
        await _db.delete(_db.routines).go();
        await _db.delete(_db.doseLogs).go();
        await _db.delete(_db.medications).go();
        await _db.delete(_db.attachments).go();
        await _db.delete(_db.healthEvents).go();
        await _db.delete(_db.treatments).go();
        await _db.delete(_db.weightEntries).go();
        await _db.delete(_db.pets).go();
        await _db.batch((b) {
          b.insertAll(_db.pets, data.pets.map(petToCompanion));
          b.insertAll(_db.weightEntries, data.weights.map(weightToCompanion));
          b.insertAll(_db.treatments, data.treatments.map(treatmentToCompanion));
          b.insertAll(_db.healthEvents, data.events.map(eventToCompanion));
          b.insertAll(_db.attachments, data.attachments.map(attachmentToCompanion));
          b.insertAll(_db.medications, data.medications.map(medicationToCompanion));
          b.insertAll(_db.doseLogs, data.doseLogs.map(doseLogToCompanion));
          b.insertAll(_db.routines, data.routines.map(routineToCompanion));
          b.insertAll(_db.foodStocks, data.foods.map(foodToCompanion));
          b.insertAll(_db.expenses, data.expenses.map(expenseToCompanion));
        });
      });
}
