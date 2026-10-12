import 'package:huellitas/domain/reminder_plan.dart';
import 'package:huellitas/services/reminder_scheduler.dart';

class FakeScheduler implements ReminderScheduler {
  List<PlannedReminder> last = const [];
  int syncCount = 0;
  bool permission = true;
  Object? failWith;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (failWith != null) throw failWith!;
    last = reminders;
    syncCount++;
  }

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<bool> requestPermission() async {
    permission = true;
    return true;
  }
}
