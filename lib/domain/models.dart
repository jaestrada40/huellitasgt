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
  final bool archived;
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
