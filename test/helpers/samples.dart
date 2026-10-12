import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';

Pet samplePet({
  String id = 'p1',
  String name = 'Toby',
  String? photoPath,
  bool archived = false,
}) =>
    Pet(
      id: id,
      name: name,
      species: PetSpecies.dog,
      breed: 'Golden Retriever',
      sex: PetSex.male,
      neutered: true,
      birthDate: DateTime.utc(2021, 6, 12),
      microchip: '981098102938471',
      photoPath: photoPath,
      allergiesNotes: 'Ninguna',
      vetName: 'Dra. Carmen Morales',
      vetClinic: 'Vet Narvarte',
      vetPhone: '5555555555',
      createdAt: DateTime(2024, 1, 1, 8),
      archived: archived,
    );

Treatment sampleTreatment({
  String id = 't1',
  String petId = 'p1',
  EventType type = EventType.vaccine,
  String name = 'Antirrábica',
  DateTime? nextDue,
  bool active = true,
  bool reminderEnabled = true,
  int reminderDaysBefore = 3,
}) =>
    Treatment(
      id: id,
      petId: petId,
      type: type,
      name: name,
      intervalValue: 1,
      intervalUnit: IntervalUnit.years,
      nextDueDate: nextDue ?? DateTime.utc(2024, 10, 29),
      reminderEnabled: reminderEnabled,
      reminderDaysBefore: reminderDaysBefore,
      active: active,
    );

HealthEvent sampleEvent({
  String id = 'e1',
  String petId = 'p1',
  EventType type = EventType.vaccine,
  String title = 'Antirrábica',
  DateTime? occurredAt,
  String? treatmentId,
  String? notes,
}) =>
    HealthEvent(
      id: id,
      petId: petId,
      type: type,
      title: title,
      occurredAt: occurredAt ?? DateTime(2024, 10, 15, 11, 30),
      createdAt: DateTime(2024, 10, 15, 11, 31),
      treatmentId: treatmentId,
      product: title,
      lot: 'NX-9921',
      vetName: 'Dra. Carmen Morales',
      clinic: 'Vet Narvarte',
      notes: notes,
      weightKg: null,
    );

Attachment sampleAttachment({
  String id = 'a1',
  String eventId = 'e1',
  String path = 'attachments/a1.jpg',
}) =>
    Attachment(
      id: id,
      eventId: eventId,
      relativePath: path,
      kind: AttachmentKind.image,
      label: 'Carnet',
    );
