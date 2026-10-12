import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs(this._p);
  final SharedPreferences _p;

  static Future<AppPrefs> load() async => AppPrefs(await SharedPreferences.getInstance());

  bool get lockEnabled => _p.getBool('lockEnabled') ?? false;
  Future<void> setLockEnabled(bool v) => _p.setBool('lockEnabled', v);

  int get reminderHour => _p.getInt('reminderHour') ?? 9;
  int get reminderMinute => _p.getInt('reminderMinute') ?? 0;
  Future<void> setReminderTime(int hour, int minute) async {
    await _p.setInt('reminderHour', hour);
    await _p.setInt('reminderMinute', minute);
  }

  int get reminderDaysBefore => _p.getInt('reminderDaysBefore') ?? 3;
  Future<void> setReminderDaysBefore(int d) => _p.setInt('reminderDaysBefore', d);

  DateTime? get lastBackupAt {
    final ms = _p.getInt('lastBackupAt');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastBackupAt(DateTime d) => _p.setInt('lastBackupAt', d.millisecondsSinceEpoch);
}
