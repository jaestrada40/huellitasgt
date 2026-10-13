import 'backup_data.dart';
import 'enums.dart';
import 'models.dart';

abstract class PetRepository {
  Stream<List<Pet>> watchAll();
  Future<List<Pet>> all();
  Future<Pet?> get(String id);
  Future<void> save(Pet pet);
  Future<void> archive(String id);
}

abstract class TreatmentRepository {
  Stream<List<Treatment>> watchActive();
  Future<List<Treatment>> active();
  Future<Treatment?> get(String id);
  Future<Treatment?> find(String petId, EventType type, String name);
  Future<void> save(Treatment t);
}

abstract class EventRepository {
  Stream<List<HealthEvent>> watchForPet(String petId);
  Future<HealthEvent?> get(String id);
  Future<List<Attachment>> attachmentsFor(String eventId);
  Future<void> save(HealthEvent e, List<Attachment> attachments);

  /// Agrega un documento a un registro ya guardado, sin tocar el resto.
  Future<void> addAttachment(Attachment a);

  /// Quita un documento y devuelve su ruta relativa (para borrar el archivo),
  /// o `null` si ya no existía.
  Future<String?> removeAttachment(String id);
  Future<List<String>> delete(String id);
}

abstract class WeightRepository {
  Stream<List<WeightEntry>> watchForPet(String petId);
  Future<void> save(WeightEntry w);
  Future<void> delete(String id);
}

abstract class BackupStore {
  Future<BackupData> readAll();
  Future<void> replaceAll(BackupData data);
}
