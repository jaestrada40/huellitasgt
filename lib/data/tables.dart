import 'package:drift/drift.dart';

import '../domain/enums.dart';

@DataClassName('PetRow')
class Pets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get species => textEnum<PetSpecies>()();
  TextColumn get breed => text().nullable()();
  TextColumn get sex => textEnum<PetSex>().nullable()();
  BoolColumn get neutered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get microchip => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  // Punto de enfoque de la foto, como Alignment (-1..1); 0,0 = centrada.
  RealColumn get photoFocusX => real().withDefault(const Constant(0))();
  RealColumn get photoFocusY => real().withDefault(const Constant(0))();
  RealColumn get photoZoom => real().withDefault(const Constant(1))(); // 1 = sin zoom
  TextColumn get allergiesNotes => text().nullable()();
  TextColumn get vetName => text().nullable()();
  TextColumn get vetClinic => text().nullable()();
  TextColumn get vetPhone => text().nullable()();
  DateTimeColumn get adoptionDate => dateTime().nullable()();
  DateTimeColumn get memorialDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeightRow')
class WeightEntries extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get kg => real()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TreatmentRow')
class Treatments extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  TextColumn get type => textEnum<EventType>()();
  TextColumn get name => text()();
  IntColumn get intervalValue => integer()();
  TextColumn get intervalUnit => textEnum<IntervalUnit>()();
  DateTimeColumn get nextDueDate => dateTime()();
  IntColumn get reminderDaysBefore => integer().withDefault(const Constant(3))();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EventRow')
class HealthEvents extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  TextColumn get treatmentId => text().nullable()();
  TextColumn get type => textEnum<EventType>()();
  TextColumn get title => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get product => text().nullable()();
  TextColumn get lot => text().nullable()();
  TextColumn get vetName => text().nullable()();
  TextColumn get clinic => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get weightKg => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text()();
  TextColumn get relativePath => text()();
  TextColumn get kind => textEnum<AttachmentKind>()();
  TextColumn get label => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationRow')
class Medications extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  // Receta (registro con la foto) de la que salió; nula si se capturó a mano.
  TextColumn get eventId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get instructions => text().nullable()();
  IntColumn get everyHours => integer()();
  DateTimeColumn get startAt => dateTime()(); // primera dosis (instante)
  IntColumn get days => integer()();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DoseLogRow')
class DoseLogs extends Table {
  TextColumn get medicationId => text()();
  IntColumn get doseIndex => integer()();
  DateTimeColumn get givenAt => dateTime()();

  @override
  Set<Column> get primaryKey => {medicationId, doseIndex};
}

@DataClassName('RoutineRow')
class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  TextColumn get name => text()();
  IntColumn get everyDays => integer()();
  DateTimeColumn get lastDoneAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FoodRow')
class FoodStocks extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  TextColumn get brand => text()();
  RealColumn get bagKg => real()();
  IntColumn get gramsPerDay => integer()();
  DateTimeColumn get openedOn => dateTime()(); // día calendario

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get petId => text()();
  DateTimeColumn get date => dateTime()(); // día calendario
  RealColumn get amount => real()();
  TextColumn get category => textEnum<ExpenseCategory>()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
