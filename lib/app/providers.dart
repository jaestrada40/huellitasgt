import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../data/drift_backup_store.dart';
import '../data/drift_repositories.dart';
import '../domain/health_service.dart';
import '../domain/models.dart';
import '../domain/repositories.dart';
import '../domain/weight_unit.dart';
import '../services/app_prefs.dart';
import '../services/attachment_store.dart';
import '../services/backup_service.dart';
import '../services/pdf_exporter.dart';
import '../services/platform_hooks.dart';
import '../services/pin_store.dart';
import '../services/reminder_coordinator.dart';
import '../services/reminder_scheduler.dart';
import '../services/share_service.dart';

// Se sobreescriben en main.dart (y en las pruebas).
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override'));
final docsDirProvider = Provider<Directory>((ref) => throw UnimplementedError('override'));
final prefsProvider = Provider<AppPrefs>((ref) => throw UnimplementedError('override'));
final schedulerProvider = Provider<ReminderScheduler>((ref) => throw UnimplementedError('override'));

final secretStoreProvider = Provider<SecretStore>((ref) => const SecureSecretStore());
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final idGeneratorProvider = Provider<String Function()>((ref) => () => const Uuid().v4());

final petRepoProvider =
    Provider<PetRepository>((ref) => DriftPetRepository(ref.watch(databaseProvider)));
final treatmentRepoProvider =
    Provider<TreatmentRepository>((ref) => DriftTreatmentRepository(ref.watch(databaseProvider)));
final medicationRepoProvider =
    Provider<MedicationRepository>((ref) => DriftMedicationRepository(ref.watch(databaseProvider)));
final careRepoProvider =
    Provider<CareRepository>((ref) => DriftCareRepository(ref.watch(databaseProvider)));
final eventRepoProvider =
    Provider<EventRepository>((ref) => DriftEventRepository(ref.watch(databaseProvider)));
final weightRepoProvider =
    Provider<WeightRepository>((ref) => DriftWeightRepository(ref.watch(databaseProvider)));
final backupStoreProvider =
    Provider<BackupStore>((ref) => DriftBackupStore(ref.watch(databaseProvider)));

final attachmentStoreProvider = Provider<AttachmentStore>((ref) => AttachmentStore(
      root: ref.watch(docsDirProvider),
      newId: ref.watch(idGeneratorProvider),
    ));

final healthServiceProvider = Provider<HealthService>((ref) => HealthService(
      events: ref.watch(eventRepoProvider),
      treatments: ref.watch(treatmentRepoProvider),
      weights: ref.watch(weightRepoProvider),
      now: ref.watch(clockProvider),
      newId: ref.watch(idGeneratorProvider),
    ));

final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) => ReminderCoordinator(
      pets: ref.watch(petRepoProvider),
      treatments: ref.watch(treatmentRepoProvider),
      medications: ref.watch(medicationRepoProvider),
      care: ref.watch(careRepoProvider),
      scheduler: ref.watch(schedulerProvider),
      prefs: ref.watch(prefsProvider),
      now: ref.watch(clockProvider),
    ));

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(
      store: ref.watch(backupStoreProvider),
      root: ref.watch(docsDirProvider),
      now: ref.watch(clockProvider),
    ));

final pinStoreProvider = Provider<PinStore>((ref) => PinStore(ref.watch(secretStoreProvider)));

final petsProvider =
    StreamProvider<List<Pet>>((ref) => ref.watch(petRepoProvider).watchAll());

final activeTreatmentsProvider = StreamProvider<List<Treatment>>(
    (ref) => ref.watch(treatmentRepoProvider).watchActive());

class SelectedPetId extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedPetIdProvider = NotifierProvider<SelectedPetId, String?>(SelectedPetId.new);

/// Unidad de peso elegida en Ajustes (el peso se guarda siempre en kg).
class WeightUnitNotifier extends Notifier<WeightUnit> {
  @override
  WeightUnit build() => ref.read(prefsProvider).weightUnit;

  Future<void> select(WeightUnit unit) async {
    state = unit;
    await ref.read(prefsProvider).setWeightUnit(unit);
  }
}

final weightUnitProvider = NotifierProvider<WeightUnitNotifier, WeightUnit>(WeightUnitNotifier.new);

/// Filtro de Inicio: `null` = «Todas» las mascotas.
class HomeFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? petId) => state = petId;
}

final homeFilterProvider = NotifierProvider<HomeFilter, String?>(HomeFilter.new);

/// La mascota seleccionada, o la primera si no hay selección válida.
final currentPetProvider = Provider<Pet?>((ref) {
  final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
  if (pets.isEmpty) return null;
  final id = ref.watch(selectedPetIdProvider);
  return pets.firstWhere((p) => p.id == id, orElse: () => pets.first);
});

final medicationsProvider =
    StreamProvider<List<Medication>>((ref) => ref.watch(medicationRepoProvider).watchAll());
final doseLogsProvider =
    StreamProvider<List<DoseLog>>((ref) => ref.watch(medicationRepoProvider).watchLogs());
final routinesForPetProvider = StreamProvider.family<List<Routine>, String>(
    (ref, petId) => ref.watch(careRepoProvider).watchRoutines(petId));
final foodsForPetProvider = StreamProvider.family<List<FoodStock>, String>(
    (ref, petId) => ref.watch(careRepoProvider).watchFoods(petId));
final expensesForPetProvider = StreamProvider.family<List<Expense>, String>(
    (ref, petId) => ref.watch(careRepoProvider).watchExpenses(petId));

final eventsForPetProvider = StreamProvider.family<List<HealthEvent>, String>(
    (ref, petId) => ref.watch(eventRepoProvider).watchForPet(petId));

final weightsForPetProvider = StreamProvider.family<List<WeightEntry>, String>(
    (ref, petId) => ref.watch(weightRepoProvider).watchForPet(petId));

final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
    (ref) => ref.watch(schedulerProvider).hasPermission());

final pdfExporterProvider = Provider<PdfExporter>((ref) => const PdfExporter());
final shareFileProvider = Provider<ShareFile>((ref) => shareFileWithSystem);

typedef BiometricAuth = Future<bool> Function();
typedef PickBackupFile = Future<File?> Function();
typedef PickPhoto = Future<File?> Function(ImageSource source);
typedef OpenUri = Future<bool> Function(Uri uri);
typedef RecognizeText = Future<RecognizedText?> Function(File image);

final biometricAuthProvider = Provider<BiometricAuth>((ref) => authenticateWithBiometrics);
final pickBackupFileProvider = Provider<PickBackupFile>((ref) => pickBackupZip);
final pickPhotoProvider = Provider<PickPhoto>((ref) => pickPhotoWithPicker);
final openUriProvider = Provider<OpenUri>((ref) => openUri);
final recognizeTextProvider = Provider<RecognizeText>((ref) => recognizeTextInImage);
