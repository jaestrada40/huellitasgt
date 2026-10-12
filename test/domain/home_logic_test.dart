import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/home_logic.dart';
import 'package:huellitas/domain/treatment_status.dart';

import '../helpers/samples.dart';

void main() {
  final today = DateTime.utc(2024, 10, 24);

  test('homeItems ordena por fecha, excluye inactivos y calcula estado y texto', () {
    final items = homeItems([
      sampleTreatment(id: 'b', nextDue: DateTime.utc(2024, 11, 5)),
      sampleTreatment(id: 'a', nextDue: DateTime.utc(2024, 10, 21)),
      sampleTreatment(id: 'x', nextDue: DateTime.utc(2024, 10, 1), active: false),
    ], today);
    expect(items.map((i) => i.treatment.id), ['a', 'b']);
    expect(items.first.status, DueStatus.overdue);
    expect(items.first.label, 'Atrasada · hace 3 días');
    expect(items.last.label, 'En 12 días');
  });

  group('needsBackupReminder', () {
    final now = DateTime(2024, 10, 24);
    test('sin datos no avisa', () {
      expect(needsBackupReminder(lastBackup: null, now: now, hasData: false), isFalse);
    });
    test('con datos y sin respaldo avisa', () {
      expect(needsBackupReminder(lastBackup: null, now: now, hasData: true), isTrue);
    });
    test('29 días no avisa, 30 sí', () {
      expect(needsBackupReminder(lastBackup: now.subtract(const Duration(days: 29)), now: now, hasData: true), isFalse);
      expect(needsBackupReminder(lastBackup: now.subtract(const Duration(days: 30)), now: now, hasData: true), isTrue);
    });
  });
}
