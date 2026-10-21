import '../domain/backup_data.dart';
import '../domain/enums.dart';
import '../domain/models.dart';

const int kBackupSchemaVersion = 2;

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
            'photoFocusX': p.photoFocusX,
            'photoFocusY': p.photoFocusY,
            'photoZoom': p.photoZoom,
            'allergiesNotes': p.allergiesNotes,
            'vetName': p.vetName,
            'vetClinic': p.vetClinic,
            'vetPhone': p.vetPhone,
            'adoptionDate': p.adoptionDate == null ? null : _iso(p.adoptionDate!),
            'memorialDate': p.memorialDate == null ? null : _iso(p.memorialDate!),
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
      'medications': [
        for (final m in d.medications)
          {
            'id': m.id,
            'petId': m.petId,
            'eventId': m.eventId,
            'name': m.name,
            'instructions': m.instructions,
            'everyHours': m.everyHours,
            'startAt': _iso(m.startAt),
            'days': m.days,
            'reminderEnabled': m.reminderEnabled,
            'active': m.active,
          },
      ],
      'doseLogs': [
        for (final l in d.doseLogs)
          {'medicationId': l.medicationId, 'doseIndex': l.doseIndex, 'givenAt': _iso(l.givenAt)},
      ],
      'routines': [
        for (final r in d.routines)
          {
            'id': r.id,
            'petId': r.petId,
            'name': r.name,
            'everyDays': r.everyDays,
            'lastDoneAt': r.lastDoneAt == null ? null : _iso(r.lastDoneAt!),
          },
      ],
      'foods': [
        for (final f in d.foods)
          {
            'id': f.id,
            'petId': f.petId,
            'brand': f.brand,
            'bagKg': f.bagKg,
            'gramsPerDay': f.gramsPerDay,
            'openedOn': _iso(f.openedOn),
          },
      ],
      'expenses': [
        for (final e in d.expenses)
          {
            'id': e.id,
            'petId': e.petId,
            'date': _iso(e.date),
            'amount': e.amount,
            'category': e.category.name,
            'note': e.note,
          },
      ],
    };

BackupData backupFromJson(Map<String, dynamic> j) {
  // Los respaldos de la versión 1 no traen las listas nuevas.
  List<Map<String, dynamic>> list(String key) =>
      ((j[key] ?? const <Object?>[]) as List).cast<Map<String, dynamic>>();

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
          // Los respaldos anteriores no traen enfoque: foto centrada.
          photoFocusX: _doubleOrNull(m['photoFocusX']) ?? 0,
          photoFocusY: _doubleOrNull(m['photoFocusY']) ?? 0,
          photoZoom: _doubleOrNull(m['photoZoom']) ?? 1,
          allergiesNotes: m['allergiesNotes'] as String?,
          vetName: m['vetName'] as String?,
          vetClinic: m['vetClinic'] as String?,
          vetPhone: m['vetPhone'] as String?,
          adoptionDate: m['adoptionDate'] == null ? null : _day(m['adoptionDate']),
          memorialDate: m['memorialDate'] == null ? null : _day(m['memorialDate']),
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
    medications: [
      for (final m in list('medications'))
        Medication(
          id: m['id'] as String,
          petId: m['petId'] as String,
          eventId: m['eventId'] as String?,
          name: m['name'] as String,
          instructions: m['instructions'] as String?,
          everyHours: m['everyHours'] as int,
          startAt: _instant(m['startAt']),
          days: m['days'] as int,
          reminderEnabled: m['reminderEnabled'] as bool,
          active: m['active'] as bool,
        ),
    ],
    doseLogs: [
      for (final m in list('doseLogs'))
        DoseLog(
          medicationId: m['medicationId'] as String,
          doseIndex: m['doseIndex'] as int,
          givenAt: _instant(m['givenAt']),
        ),
    ],
    routines: [
      for (final m in list('routines'))
        Routine(
          id: m['id'] as String,
          petId: m['petId'] as String,
          name: m['name'] as String,
          everyDays: m['everyDays'] as int,
          lastDoneAt: m['lastDoneAt'] == null ? null : _instant(m['lastDoneAt']),
        ),
    ],
    foods: [
      for (final m in list('foods'))
        FoodStock(
          id: m['id'] as String,
          petId: m['petId'] as String,
          brand: m['brand'] as String,
          bagKg: (m['bagKg'] as num).toDouble(),
          gramsPerDay: m['gramsPerDay'] as int,
          openedOn: _day(m['openedOn']),
        ),
    ],
    expenses: [
      for (final m in list('expenses'))
        Expense(
          id: m['id'] as String,
          petId: m['petId'] as String,
          date: _day(m['date']),
          amount: (m['amount'] as num).toDouble(),
          category: ExpenseCategory.values.byName(m['category'] as String),
          note: m['note'] as String?,
        ),
    ],
  );
}
