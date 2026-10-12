import 'models.dart';
import 'treatment_status.dart';

const int backupReminderDays = 30;

class HomeItem {
  const HomeItem(this.treatment, this.status, this.label);
  final Treatment treatment;
  final DueStatus status;
  final String label;
}

List<HomeItem> homeItems(Iterable<Treatment> treatments, DateTime today) {
  final list = treatments.where((t) => t.active).toList()
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  return [
    for (final t in list)
      HomeItem(t, dueStatus(t.nextDueDate, today), dueLabel(t.nextDueDate, today)),
  ];
}

bool needsBackupReminder({
  required DateTime? lastBackup,
  required DateTime now,
  required bool hasData,
}) {
  if (!hasData) return false;
  if (lastBackup == null) return true;
  return now.difference(lastBackup).inDays >= backupReminderDays;
}
