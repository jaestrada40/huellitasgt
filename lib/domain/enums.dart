enum PetSpecies { dog, cat, other }

enum PetSex { male, female }

enum EventType { vaccine, deworming, fleaTick, illness, checkup }

enum IntervalUnit { days, weeks, months, years }

enum AttachmentKind { image, pdf }

enum ExpenseCategory { vet, food, grooming, accessories, other }

extension ExpenseCategoryInfo on ExpenseCategory {
  String get label => switch (this) {
        ExpenseCategory.vet => 'Veterinario',
        ExpenseCategory.food => 'Comida',
        ExpenseCategory.grooming => 'Baño y peluquería',
        ExpenseCategory.accessories => 'Accesorios',
        ExpenseCategory.other => 'Otros',
      };
}

extension EventTypeInfo on EventType {
  bool get canRecur =>
      this == EventType.vaccine ||
      this == EventType.deworming ||
      this == EventType.fleaTick;

  String get label => switch (this) {
        EventType.vaccine => 'Vacuna',
        EventType.deworming => 'Desparasitación',
        EventType.fleaTick => 'Antipulgas y garrapatas',
        EventType.illness => 'Enfermedad',
        EventType.checkup => 'Consulta',
      };

  String get pluralLabel => switch (this) {
        EventType.vaccine => 'Vacunas',
        EventType.deworming => 'Desparasitación',
        EventType.fleaTick => 'Antipulgas',
        EventType.illness => 'Enfermedades',
        EventType.checkup => 'Consultas',
      };
}
