import 'package:shared_preferences/shared_preferences.dart';

import '../domain/weight_unit.dart';

class AppPrefs {
  AppPrefs(this._p);
  final SharedPreferences _p;

  static Future<AppPrefs> load() async => AppPrefs(await SharedPreferences.getInstance());

  String? get userName => _p.getString('userName');
  Future<void> setUserName(String name) {
    final t = name.trim();
    return t.isEmpty ? _p.remove('userName') : _p.setString('userName', t);
  }

  /// Teléfono de contacto para la ficha de mascota perdida.
  String? get ownerPhone => _p.getString('ownerPhone');
  Future<void> setOwnerPhone(String phone) {
    final t = phone.trim();
    return t.isEmpty ? _p.remove('ownerPhone') : _p.setString('ownerPhone', t);
  }

  WeightUnit get weightUnit =>
      _p.getString('weightUnit') == 'lb' ? WeightUnit.lb : WeightUnit.kg;
  Future<void> setWeightUnit(WeightUnit u) => _p.setString('weightUnit', u.name);

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
