import '../data/database.dart';
import '../data/drift_repositories.dart';
import '../domain/dates.dart';
import '../domain/enums.dart';
import '../domain/health_service.dart';
import '../domain/models.dart';
import '../services/app_prefs.dart';

/// Datos de ejemplo SOLO para desarrollo: se activa con
/// `flutter run --dart-define=SEED_DEMO=true` y nunca en la app publicada.
const bool kSeedDemo = bool.fromEnvironment('SEED_DEMO');

/// Recorre las pantallas solo (para capturas de pantalla en desarrollo):
/// `--dart-define=SEED_DEMO=true --dart-define=TOUR=true`.
const bool kTour = bool.fromEnvironment('TOUR');

const List<String> kTourRoutes = [
  '/home',
  '/pets/canela',
  '/pets/canela/meds',
  '/pets/canela/prescription',
  '/pets/canela/routines',
  '/pets/canela/food',
  '/pets/canela/expenses',
  '/history',
  '/pets',
  '/pets/canela',
  '/events/demo1',
  '/events/new?petId=canela',
  '/settings',
  '/pets/canela/carnet',
  '/pets/canela/weight',
  '/onboarding?replay=1',
  '/pets/new?first=1',
];

Future<void> seedDemo(AppDatabase db, AppPrefs prefs) async {
  final pets = DriftPetRepository(db);
  if ((await pets.all()).isNotEmpty) return;
  await prefs.setUserName('Javier');

  final now = DateTime.now();
  final today = dateOnly(now);
  var n = 0;
  final health = HealthService(
    events: DriftEventRepository(db),
    treatments: DriftTreatmentRepository(db),
    weights: DriftWeightRepository(db),
    now: () => now,
    newId: () => 'demo${n++}',
  );

  await pets.save(Pet(
    id: 'canela',
    name: 'Canela',
    species: PetSpecies.dog,
    breed: 'Golden Retriever',
    sex: PetSex.female,
    birthDate: DateTime.utc(2023, 6, 12),
    microchip: '985 112 004 553 210',
    vetName: 'Dra. Lucía Ramírez',
    vetClinic: 'Clínica Patitas',
    createdAt: now.subtract(const Duration(days: 400)),
  ));
  await pets.save(Pet(
    id: 'mango',
    name: 'Mango',
    species: PetSpecies.cat,
    breed: 'Doméstico atigrado',
    sex: PetSex.male,
    neutered: true,
    birthDate: DateTime.utc(2025, 8, 2),
    createdAt: now.subtract(const Duration(days: 399)),
  ));

  Future<void> log(String pet, EventType type, String title, int daysAgo, int every, IntervalUnit unit,
      {String? notes, String? vet}) {
    return health.logEvent(LogEventInput(
      petId: pet,
      type: type,
      title: title,
      occurredAt: DateTime(now.year, now.month, now.day - daysAgo, 11, 30),
      product: title,
      notes: notes,
      vetName: vet,
      intervalValue: every,
      intervalUnit: unit,
    ));
  }

  // Vencimientos relativos a hoy: atrasada, hoy, en 5, 12 y 18 días.
  await log('canela', EventType.fleaTick, 'NexGard Spectra', 33, 1, IntervalUnit.months, notes: 'Tableta masticable, la comió con premio.', vet: 'En casa');
  await log('mango', EventType.deworming, 'Milbemax gatos', 90, 3, IntervalUnit.months, notes: 'Dosis para 2–8 kg.');
  await log('canela', EventType.vaccine, 'Vacuna antirrábica', 360, 1, IntervalUnit.years, notes: 'Sin reacciones. Lote RB-2291.', vet: 'Dra. Lucía Ramírez');
  await log('mango', EventType.vaccine, 'Triple felina', 353, 1, IntervalUnit.years, notes: 'Refuerzo anual.', vet: 'Clínica Patitas');
  await log('mango', EventType.fleaTick, 'Revolution Plus', 12, 1, IntervalUnit.months, notes: 'Pipeta en la nuca.', vet: 'En casa');
  await log('canela', EventType.deworming, 'Drontal Plus', 20, 4, IntervalUnit.months, notes: '1 tableta de 35 kg.', vet: 'En casa');
  await health.logEvent(LogEventInput(
    petId: 'canela',
    type: EventType.checkup,
    title: 'Chequeo general',
    occurredAt: today.subtract(const Duration(days: 47)),
    vetName: 'Dra. Lucía Ramírez',
    clinic: 'Clínica Patitas',
    notes: 'Todo en orden. Limpieza dental sugerida.',
    weightKg: 28.4,
  ));
  final start = DateTime(now.year, now.month, now.day, 8);
  await DriftMedicationRepository(db).saveAll([
    Medication(id: 'demo-m1', petId: 'canela', name: 'Numelvi', instructions: '1 tableta cada 24 hrs por 3 semanas', everyHours: 24, days: 21, startAt: start),
    Medication(id: 'demo-m2', petId: 'canela', name: 'Kiroftal ciproxyn', instructions: '2 gotas en el ojo derecho cada 12 hrs', everyHours: 12, days: 7, startAt: start),
  ]);
  final care = DriftCareRepository(db);
  await care.saveRoutine(Routine(id: 'demo-r1', petId: 'canela', name: 'Baño', everyDays: 15, lastDoneAt: now.subtract(const Duration(days: 9))));
  await care.saveRoutine(Routine(id: 'demo-r2', petId: 'canela', name: 'Cortar uñas', everyDays: 21, lastDoneAt: now.subtract(const Duration(days: 30))));
  await care.saveFood(FoodStock(id: 'demo-f1', petId: 'canela', brand: 'Pro Plan', bagKg: 15, gramsPerDay: 320, openedOn: today.subtract(const Duration(days: 20))));
  await care.saveExpense(Expense(id: 'demo-x1', petId: 'canela', date: today.subtract(const Duration(days: 2)), amount: 250, category: ExpenseCategory.vet, note: 'Consulta'));
  await care.saveExpense(Expense(id: 'demo-x2', petId: 'canela', date: today.subtract(const Duration(days: 5)), amount: 480.5, category: ExpenseCategory.food));
  await health.logEvent(LogEventInput(
    petId: 'mango',
    type: EventType.illness,
    title: 'Conjuntivitis leve',
    occurredAt: today.subtract(const Duration(days: 75)),
    clinic: 'Clínica Patitas',
    notes: 'Gotas Tobradex 7 días. Se recuperó.',
  ));
}
