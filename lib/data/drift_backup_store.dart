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
    return BackupData(
      pets: pets.map(petFromRow).toList(),
      weights: weights.map(weightFromRow).toList(),
      treatments: treatments.map(treatmentFromRow).toList(),
      events: events.map(eventFromRow).toList(),
      attachments: attachments.map(attachmentFromRow).toList(),
    );
  }

  @override
  Future<void> replaceAll(BackupData data) => _db.transaction(() async {
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
        });
      });
}
