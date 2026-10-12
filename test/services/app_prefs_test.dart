import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('valores por defecto', () async {
    final p = await AppPrefs.load();
    expect(p.lockEnabled, isFalse);
    expect(p.reminderHour, 9);
    expect(p.reminderMinute, 0);
    expect(p.reminderDaysBefore, 3);
    expect(p.lastBackupAt, isNull);
  });

  test('guarda y lee', () async {
    final p = await AppPrefs.load();
    await p.setLockEnabled(true);
    await p.setReminderTime(18, 30);
    await p.setReminderDaysBefore(7);
    await p.setLastBackupAt(DateTime(2024, 10, 2, 12));
    expect(p.lockEnabled, isTrue);
    expect(p.reminderHour, 18);
    expect(p.reminderMinute, 30);
    expect(p.reminderDaysBefore, 7);
    expect(p.lastBackupAt, DateTime(2024, 10, 2, 12));
  });
}
