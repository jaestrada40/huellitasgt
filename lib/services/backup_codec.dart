import '../domain/backup_data.dart';
import '../domain/enums.dart';
import '../domain/models.dart';

const int kBackupSchemaVersion = 1;

// Instantes se guardan en UTC y se leen en hora local; los días calendario se
// guardan y leen como medianoche UTC.
String _iso(DateTime d) => d.toUtc().toIso8601String();
DateTime _instant(Object? v) => DateTime.parse(v as String).toLocal();
DateTime _day(Object? v) => DateTime.parse(v as String).toUtc();
T? _enumOrNull<T extends Enum>(List<T> values, Object? v) =>
    v == null ? null : values.byName(v as String);
double? _doubleOrNull(Object? v) => (v as num?)?.toDouble();

Map<String, dynamic> backupToJson(
  BackupData d, {
  required int schemaVersion,
  required DateTime exportedAt,
}) =>
    {
      'schemaVersion': schemaVersion,
      'exportedAt': _iso(exportedAt),
      'pets': [
        for (final p in d.pets)
          {
            'id': p.id,
            'name': p.name,
            'species': p.species.name,
            'breed': p.breed,
            'sex': p.sex?.name,
            'neutered': p.neutered,
            'birthDate': p.birthDate == null ? null : _iso(p.birthDate!),
            'microchip': p.microchip,
            'photoPath': p.photoPath,
            'allergiesNotes': p.allergiesNotes,
            'vetName': p.vetName,
            'vetClinic': p.vetClinic,
            'vetPhone': p.vetPhone,
            'createdAt': _iso(p.createdAt),
            'archived': p.archived,
          },
      ],
      'weights': [
        for (final w in d.weights)
          {'id': w.id, 'petId': w.petId, 'date': _iso(w.date), 'kg': w.kg, 'note': w.note},
      ],
      'treatments': [
        for (final t in d.treatments)
          {
            'id': t.id,
            'petId': t.petId,
            'type': t.type.name,
            'name': t.name,
            'intervalValue': t.intervalValue,
            'intervalUnit': t.intervalUnit.name,
            'nextDueDate': _iso(t.nextDueDate),
            'reminderDaysBefore': t.reminderDaysBefore,
            'reminderEnabled': t.reminderEnabled,
            'active': t.active,
          },
      ],
      'events': [
        for (final e in d.events)
          {
            'id': e.id,
            'petId': e.petId,
            'treatmentId': e.treatmentId,
            'type': e.type.name,
            'title': e.title,
            'occurredAt': _iso(e.occurredAt),
            'product': e.product,
            'lot': e.lot,
            'vetName': e.vetName,
            'clinic': e.clinic,
            'notes': e.notes,
            'weightKg': e.weightKg,
            'createdAt': _iso(e.createdAt),
          },
      ],
      'attachments': [
        for (final a in d.attachments)
          {
            'id': a.id,
            'eventId': a.eventId,
            'relativePath': a.relativePath,
            'kind': a.kind.name,
            'label': a.label,
          },
      ],
    };

BackupData backupFromJson(Map<String, dynamic> j) {
  List<Map<String, dynamic>> list(String key) =>
      (j[key] as List).cast<Map<String, dynamic>>();

  return BackupData(
    pets: [
      for (final m in list('pets'))
        Pet(
          id: m['id'] as String,
          name: m['name'] as String,
          species: PetSpecies.values.byName(m['species'] as String),
          breed: m['breed'] as String?,
          sex: _enumOrNull(PetSex.values, m['sex']),
          neutered: m['neutered'] as bool,
          birthDate: m['birthDate'] == null ? null : _day(m['birthDate']),
          microchip: m['microchip'] as String?,
          photoPath: m['photoPath'] as String?,
          allergiesNotes: m['allergiesNotes'] as String?,
          vetName: m['vetName'] as String?,
          vetClinic: m['vetClinic'] as String?,
          vetPhone: m['vetPhone'] as String?,
          createdAt: _instant(m['createdAt']),
          archived: m['archived'] as bool,
        ),
    ],
    weights: [
      for (final m in list('weights'))
        WeightEntry(
          id: m['id'] as String,
          petId: m['petId'] as String,
          date: _day(m['date']),
          kg: (m['kg'] as num).toDouble(),
          note: m['note'] as String?,
        ),
    ],
    treatments: [
      for (final m in list('treatments'))
        Treatment(
          id: m['id'] as String,
          petId: m['petId'] as String,
          type: EventType.values.byName(m['type'] as String),
          name: m['name'] as String,
          intervalValue: m['intervalValue'] as int,
          intervalUnit: IntervalUnit.values.byName(m['intervalUnit'] as String),
          nextDueDate: _day(m['nextDueDate']),
          reminderDaysBefore: m['reminderDaysBefore'] as int,
          reminderEnabled: m['reminderEnabled'] as bool,
          active: m['active'] as bool,
        ),
    ],
    events: [
      for (final m in list('events'))
        HealthEvent(
          id: m['id'] as String,
          petId: m['petId'] as String,
          treatmentId: m['treatmentId'] as String?,
          type: EventType.values.byName(m['type'] as String),
          title: m['title'] as String,
          occurredAt: _instant(m['occurredAt']),
          product: m['product'] as String?,
          lot: m['lot'] as String?,
          vetName: m['vetName'] as String?,
          clinic: m['clinic'] as String?,
          notes: m['notes'] as String?,
          weightKg: _doubleOrNull(m['weightKg']),
          createdAt: _instant(m['createdAt']),
        ),
    ],
    attachments: [
      for (final m in list('attachments'))
        Attachment(
          id: m['id'] as String,
          eventId: m['eventId'] as String,
          relativePath: m['relativePath'] as String,
          kind: AttachmentKind.values.byName(m['kind'] as String),
          label: m['label'] as String?,
        ),
    ],
  );
}
