import 'package:drift/drift.dart';

import '../domain/models.dart';
import 'database.dart';

// Fechas de día calendario: se leen con .toUtc() (la BD las devuelve en hora
// local y en UTC-6 el día se correría). Instantes: se leen con .toLocal().

Pet petFromRow(PetRow r) => Pet(
      id: r.id,
      name: r.name,
      species: r.species,
      breed: r.breed,
      sex: r.sex,
      neutered: r.neutered,
      birthDate: r.birthDate?.toUtc(),
      microchip: r.microchip,
      photoPath: r.photoPath,
      photoFocusX: r.photoFocusX,
      photoFocusY: r.photoFocusY,
      photoZoom: r.photoZoom,
      allergiesNotes: r.allergiesNotes,
      vetName: r.vetName,
      vetClinic: r.vetClinic,
      vetPhone: r.vetPhone,
      adoptionDate: r.adoptionDate?.toUtc(),
      memorialDate: r.memorialDate?.toUtc(),
      createdAt: r.createdAt.toLocal(),
      archived: r.archived,
    );

PetsCompanion petToCompanion(Pet p) => PetsCompanion.insert(
      id: p.id,
      name: p.name,
      species: p.species,
      createdAt: p.createdAt,
      breed: Value(p.breed),
      sex: Value(p.sex),
      neutered: Value(p.neutered),
      birthDate: Value(p.birthDate),
      microchip: Value(p.microchip),
      photoPath: Value(p.photoPath),
      photoFocusX: Value(p.photoFocusX),
      photoFocusY: Value(p.photoFocusY),
      photoZoom: Value(p.photoZoom),
      allergiesNotes: Value(p.allergiesNotes),
      vetName: Value(p.vetName),
      vetClinic: Value(p.vetClinic),
      vetPhone: Value(p.vetPhone),
      adoptionDate: Value(p.adoptionDate),
      memorialDate: Value(p.memorialDate),
      archived: Value(p.archived),
    );

WeightEntry weightFromRow(WeightRow r) => WeightEntry(
      id: r.id,
      petId: r.petId,
      date: r.date.toUtc(),
      kg: r.kg,
      note: r.note,
    );

WeightEntriesCompanion weightToCompanion(WeightEntry w) => WeightEntriesCompanion.insert(
      id: w.id,
      petId: w.petId,
      date: w.date,
      kg: w.kg,
      note: Value(w.note),
    );

Treatment treatmentFromRow(TreatmentRow r) => Treatment(
      id: r.id,
      petId: r.petId,
      type: r.type,
      name: r.name,
      intervalValue: r.intervalValue,
      intervalUnit: r.intervalUnit,
      nextDueDate: r.nextDueDate.toUtc(),
      reminderDaysBefore: r.reminderDaysBefore,
      reminderEnabled: r.reminderEnabled,
      active: r.active,
    );

TreatmentsCompanion treatmentToCompanion(Treatment t) => TreatmentsCompanion.insert(
      id: t.id,
      petId: t.petId,
      type: t.type,
      name: t.name,
      intervalValue: t.intervalValue,
      intervalUnit: t.intervalUnit,
      nextDueDate: t.nextDueDate,
      reminderDaysBefore: Value(t.reminderDaysBefore),
      reminderEnabled: Value(t.reminderEnabled),
      active: Value(t.active),
    );

HealthEvent eventFromRow(EventRow r) => HealthEvent(
      id: r.id,
      petId: r.petId,
      treatmentId: r.treatmentId,
      type: r.type,
      title: r.title,
      occurredAt: r.occurredAt.toLocal(),
      product: r.product,
      lot: r.lot,
      vetName: r.vetName,
      clinic: r.clinic,
      notes: r.notes,
      weightKg: r.weightKg,
      createdAt: r.createdAt.toLocal(),
    );

HealthEventsCompanion eventToCompanion(HealthEvent e) => HealthEventsCompanion.insert(
      id: e.id,
      petId: e.petId,
      type: e.type,
      title: e.title,
      occurredAt: e.occurredAt,
      createdAt: e.createdAt,
      treatmentId: Value(e.treatmentId),
      product: Value(e.product),
      lot: Value(e.lot),
      vetName: Value(e.vetName),
      clinic: Value(e.clinic),
      notes: Value(e.notes),
      weightKg: Value(e.weightKg),
    );

Attachment attachmentFromRow(AttachmentRow r) => Attachment(
      id: r.id,
      eventId: r.eventId,
      relativePath: r.relativePath,
      kind: r.kind,
      label: r.label,
    );

AttachmentsCompanion attachmentToCompanion(Attachment a) => AttachmentsCompanion.insert(
      id: a.id,
      eventId: a.eventId,
      relativePath: a.relativePath,
      kind: a.kind,
      label: Value(a.label),
    );

Medication medicationFromRow(MedicationRow r) => Medication(
      id: r.id,
      petId: r.petId,
      eventId: r.eventId,
      name: r.name,
      instructions: r.instructions,
      everyHours: r.everyHours,
      startAt: r.startAt.toLocal(),
      days: r.days,
      reminderEnabled: r.reminderEnabled,
      active: r.active,
    );

MedicationsCompanion medicationToCompanion(Medication m) => MedicationsCompanion.insert(
      id: m.id,
      petId: m.petId,
      name: m.name,
      everyHours: m.everyHours,
      startAt: m.startAt,
      days: m.days,
      eventId: Value(m.eventId),
      instructions: Value(m.instructions),
      reminderEnabled: Value(m.reminderEnabled),
      active: Value(m.active),
    );

DoseLog doseLogFromRow(DoseLogRow r) =>
    DoseLog(medicationId: r.medicationId, doseIndex: r.doseIndex, givenAt: r.givenAt.toLocal());

DoseLogsCompanion doseLogToCompanion(DoseLog l) => DoseLogsCompanion.insert(
      medicationId: l.medicationId,
      doseIndex: l.doseIndex,
      givenAt: l.givenAt,
    );

Routine routineFromRow(RoutineRow r) => Routine(
      id: r.id,
      petId: r.petId,
      name: r.name,
      everyDays: r.everyDays,
      lastDoneAt: r.lastDoneAt?.toLocal(),
    );

RoutinesCompanion routineToCompanion(Routine r) => RoutinesCompanion.insert(
      id: r.id,
      petId: r.petId,
      name: r.name,
      everyDays: r.everyDays,
      lastDoneAt: Value(r.lastDoneAt),
    );

FoodStock foodFromRow(FoodRow r) => FoodStock(
      id: r.id,
      petId: r.petId,
      brand: r.brand,
      bagKg: r.bagKg,
      gramsPerDay: r.gramsPerDay,
      openedOn: r.openedOn.toUtc(),
    );

FoodStocksCompanion foodToCompanion(FoodStock f) => FoodStocksCompanion.insert(
      id: f.id,
      petId: f.petId,
      brand: f.brand,
      bagKg: f.bagKg,
      gramsPerDay: f.gramsPerDay,
      openedOn: f.openedOn,
    );

Expense expenseFromRow(ExpenseRow r) => Expense(
      id: r.id,
      petId: r.petId,
      date: r.date.toUtc(),
      amount: r.amount,
      category: r.category,
      note: r.note,
    );

ExpensesCompanion expenseToCompanion(Expense e) => ExpensesCompanion.insert(
      id: e.id,
      petId: e.petId,
      date: e.date,
      amount: e.amount,
      category: e.category,
      note: Value(e.note),
    );
