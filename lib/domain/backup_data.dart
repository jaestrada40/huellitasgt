import 'models.dart';

class BackupData {
  const BackupData({
    required this.pets,
    required this.weights,
    required this.treatments,
    required this.events,
    required this.attachments,
    this.medications = const [],
    this.doseLogs = const [],
    this.routines = const [],
    this.foods = const [],
    this.expenses = const [],
  });

  final List<Pet> pets;
  final List<WeightEntry> weights;
  final List<Treatment> treatments;
  final List<HealthEvent> events;
  final List<Attachment> attachments;
  final List<Medication> medications;
  final List<DoseLog> doseLogs;
  final List<Routine> routines;
  final List<FoodStock> foods;
  final List<Expense> expenses;
}
