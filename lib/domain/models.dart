import 'enums.dart';

class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.createdAt,
    this.breed,
    this.sex,
    this.neutered = false,
    this.birthDate,
    this.microchip,
    this.photoPath,
    this.photoFocusX = 0,
    this.photoFocusY = 0,
    this.photoZoom = 1,
    this.allergiesNotes,
    this.vetName,
    this.vetClinic,
    this.vetPhone,
    this.adoptionDate,
    this.memorialDate,
    this.archived = false,
  });

  final String id;
  final String name;
  final PetSpecies species;
  final DateTime createdAt;
  final String? breed;
  final PetSex? sex;
  final bool neutered;
  final DateTime? birthDate; // día calendario (UTC)
  final String? microchip;
  final String? photoPath; // ruta relativa
  final double photoFocusX; // Alignment -1..1; 0 = centrada
  final double photoFocusY;
  final double photoZoom; // 1 = sin zoom
  final String? allergiesNotes;
  final String? vetName;
  final String? vetClinic;
  final String? vetPhone;
  final DateTime? adoptionDate; // día calendario (UTC): «gotcha day»
  final DateTime? memorialDate; // día calendario (UTC): ya no está con nosotros
  final bool archived;

  bool get inMemoriam => memorialDate != null;

  Pet withMemorial(DateTime day) => Pet(
        id: id,
        name: name,
        species: species,
        createdAt: createdAt,
        breed: breed,
        sex: sex,
        neutered: neutered,
        birthDate: birthDate,
        microchip: microchip,
        photoPath: photoPath,
        photoFocusX: photoFocusX,
        photoFocusY: photoFocusY,
        photoZoom: photoZoom,
        allergiesNotes: allergiesNotes,
        vetName: vetName,
        vetClinic: vetClinic,
        vetPhone: vetPhone,
        adoptionDate: adoptionDate,
        memorialDate: day,
        archived: archived,
      );
}

class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.petId,
    required this.date,
    required this.kg,
    this.note,
  });

  final String id;
  final String petId;
  final DateTime date; // día calendario (UTC)
  final double kg;
  final String? note;
}

class Treatment {
  const Treatment({
    required this.id,
    required this.petId,
    required this.type,
    required this.name,
    required this.intervalValue,
    required this.intervalUnit,
    required this.nextDueDate,
    this.reminderDaysBefore = 3,
    this.reminderEnabled = true,
    this.active = true,
  });

  final String id;
  final String petId;
  final EventType type;
  final String name;
  final int intervalValue;
  final IntervalUnit intervalUnit;
  final DateTime nextDueDate; // día calendario (UTC)
  final int reminderDaysBefore;
  final bool reminderEnabled;
  final bool active;

  Treatment copyWith({
    int? intervalValue,
    IntervalUnit? intervalUnit,
    DateTime? nextDueDate,
    int? reminderDaysBefore,
    bool? reminderEnabled,
    bool? active,
  }) =>
      Treatment(
        id: id,
        petId: petId,
        type: type,
        name: name,
        intervalValue: intervalValue ?? this.intervalValue,
        intervalUnit: intervalUnit ?? this.intervalUnit,
        nextDueDate: nextDueDate ?? this.nextDueDate,
        reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        active: active ?? this.active,
      );
}

class HealthEvent {
  const HealthEvent({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.occurredAt,
    required this.createdAt,
    this.treatmentId,
    this.product,
    this.lot,
    this.vetName,
    this.clinic,
    this.notes,
    this.weightKg,
  });

  final String id;
  final String petId;
  final EventType type;
  final String title;
  final DateTime occurredAt; // instante (hora local)
  final DateTime createdAt;
  final String? treatmentId;
  final String? product;
  final String? lot;
  final String? vetName;
  final String? clinic;
  final String? notes;
  final double? weightKg;
}

class Attachment {
  const Attachment({
    required this.id,
    required this.eventId,
    required this.relativePath,
    required this.kind,
    this.label,
  });

  final String id;
  final String eventId;
  final String relativePath;
  final AttachmentKind kind;
  final String? label;
}

class Medication {
  const Medication({
    required this.id,
    required this.petId,
    required this.name,
    required this.everyHours,
    required this.startAt,
    required this.days,
    this.eventId,
    this.instructions,
    this.reminderEnabled = true,
    this.active = true,
  });

  final String id;
  final String petId;
  final String? eventId;
  final String name;
  final String? instructions;
  final int everyHours;
  final DateTime startAt; // instante (hora local) de la primera dosis
  final int days;
  final bool reminderEnabled;
  final bool active;

  Medication copyWith({bool? active, int? everyHours, DateTime? startAt, int? days}) => Medication(
        id: id,
        petId: petId,
        eventId: eventId,
        name: name,
        instructions: instructions,
        everyHours: everyHours ?? this.everyHours,
        startAt: startAt ?? this.startAt,
        days: days ?? this.days,
        reminderEnabled: reminderEnabled,
        active: active ?? this.active,
      );
}

class DoseLog {
  const DoseLog({required this.medicationId, required this.doseIndex, required this.givenAt});
  final String medicationId;
  final int doseIndex;
  final DateTime givenAt;
}

class Routine {
  const Routine({
    required this.id,
    required this.petId,
    required this.name,
    required this.everyDays,
    this.lastDoneAt,
  });

  final String id;
  final String petId;
  final String name;
  final int everyDays;
  final DateTime? lastDoneAt; // instante (hora local)
}

class FoodStock {
  const FoodStock({
    required this.id,
    required this.petId,
    required this.brand,
    required this.bagKg,
    required this.gramsPerDay,
    required this.openedOn,
  });

  final String id;
  final String petId;
  final String brand;
  final double bagKg;
  final int gramsPerDay;
  final DateTime openedOn; // día calendario (UTC)
}

class Expense {
  const Expense({
    required this.id,
    required this.petId,
    required this.date,
    required this.amount,
    required this.category,
    this.note,
  });

  final String id;
  final String petId;
  final DateTime date; // día calendario (UTC)
  final double amount;
  final ExpenseCategory category;
  final String? note;
}
