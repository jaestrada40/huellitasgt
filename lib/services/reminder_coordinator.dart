import '../domain/reminder_plan.dart';
import '../domain/repositories.dart';
import 'app_prefs.dart';
import 'reminder_scheduler.dart';

class ReminderCoordinator {
  ReminderCoordinator({
    required PetRepository pets,
    required TreatmentRepository treatments,
    required ReminderScheduler scheduler,
    required AppPrefs prefs,
    required DateTime Function() now,
  })  : _pets = pets,
        _treatments = treatments,
        _scheduler = scheduler,
        _prefs = prefs,
        _now = now;

  final PetRepository _pets;
  final TreatmentRepository _treatments;
  final ReminderScheduler _scheduler;
  final AppPrefs _prefs;
  final DateTime Function() _now;

  /// Recalcula y reprograma todos los avisos. Llamar al abrir la app y tras
  /// cualquier cambio en mascotas, tratamientos o ajustes de recordatorio.
  Future<void> sync() async {
    final pets = await _pets.all();
    final names = {for (final p in pets) if (!p.archived) p.id: p.name};
    final plan = planReminders(
      treatments: await _treatments.active(),
      petNames: names,
      now: _now(),
      hour: _prefs.reminderHour,
      minute: _prefs.reminderMinute,
    );
    try {
      await _scheduler.replaceAll(plan);
    } catch (_) {
      // Los avisos son «lo mejor posible»: sin permiso del teléfono (o con un
      // fallo del plugin) la app debe seguir guardando datos sin interrumpirse.
      // Home y Ajustes ya avisan cuando las notificaciones están apagadas.
    }
  }
}
