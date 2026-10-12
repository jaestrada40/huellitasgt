import 'models.dart';

class BackupData {
  const BackupData({
    required this.pets,
    required this.weights,
    required this.treatments,
    required this.events,
    required this.attachments,
  });

  final List<Pet> pets;
  final List<WeightEntry> weights;
  final List<Treatment> treatments;
  final List<HealthEvent> events;
  final List<Attachment> attachments;
}
