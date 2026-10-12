import '../domain/reminder_plan.dart';

abstract class ReminderScheduler {
  /// Cancela todo lo programado y programa [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);
  Future<bool> hasPermission();
  Future<bool> requestPermission();
}
