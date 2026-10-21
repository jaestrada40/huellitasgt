import '../domain/care_logic.dart';
import '../domain/medication_logic.dart';
import '../domain/reminder_plan.dart';
import '../domain/repositories.dart';
import 'app_prefs.dart';
import 'reminder_scheduler.dart';

class ReminderCoordinator {
  ReminderCoordinator({
    required PetRepository pets,
    required TreatmentRepository treatments,
    required MedicationRepository medications,
    required CareRepository care,
    required ReminderScheduler scheduler,
    required AppPrefs prefs,
    required DateTime Function() now,
  })  : _pets = pets,
        _treatments = treatments,
        _medications = medications,
        _care = care,
        _scheduler = scheduler,
        _prefs = prefs,
        _now = now;

  final PetRepository _pets;
  final TreatmentRepository _treatments;
  final MedicationRepository _medications;
  final CareRepository _care;
  final ReminderScheduler _scheduler;
  final AppPrefs _prefs;
  final DateTime Function() _now;

  static const _maxPending = 60;

  /// Recalcula y reprograma todos los avisos. Llamar al abrir la app y tras
  /// cualquier cambio en mascotas, tratamientos o ajustes de recordatorio.
  Future<void> sync() async {
    final pets = await _pets.all();
    final names = {for (final p in pets) if (!p.archived) p.id: p.name};
    final now = _now();
    // Vacunas y fechas primero (son pocas); las dosis de medicina llenan el
    // resto de los 60 avisos que iOS permite tener pendientes.
    final fixed = [
      ...planReminders(
        treatments: await _treatments.active(),
        petNames: names,
        now: now,
        hour: _prefs.reminderHour,
        minute: _prefs.reminderMinute,
      ),
      ...planDateReminders(
        pets: pets,
        foods: await _care.foods(),
        now: now,
        hour: _prefs.reminderHour,
        minute: _prefs.reminderMinute,
      ),
    ];
    final meds = planMedicationReminders(
      meds: await _medications.all(),
      logs: await _medications.logs(),
      petNames: names,
      now: now,
      max: (_maxPending - fixed.length).clamp(0, _maxPending),
    );
    final plan = [...fixed, ...meds]..sort((a, b) => a.fireAt.compareTo(b.fireAt));
    try {
      await _scheduler.replaceAll(plan);
    } catch (_) {
      // Los avisos son «lo mejor posible»: sin permiso del teléfono (o con un
      // fallo del plugin) la app debe seguir guardando datos sin interrumpirse.
      // Home y Ajustes ya avisan cuando las notificaciones están apagadas.
    }
  }
}
