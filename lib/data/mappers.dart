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
      allergiesNotes: r.allergiesNotes,
      vetName: r.vetName,
      vetClinic: r.vetClinic,
      vetPhone: r.vetPhone,
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
      allergiesNotes: Value(p.allergiesNotes),
      vetName: Value(p.vetName),
      vetClinic: Value(p.vetClinic),
      vetPhone: Value(p.vetPhone),
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
