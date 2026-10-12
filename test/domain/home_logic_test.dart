import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/enums.dart';
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
    expect(items.first.label, 'Atrasada 3 días');
    expect(items.last.label, 'Vence en 12 días');
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

  group('homeSections', () {
    test('toca pronto: atrasados y hasta 30 días; el resto está al día', () {
      final s = homeSections([
        sampleTreatment(id: 'a', nextDue: DateTime.utc(2024, 10, 21)), // atrasada
        sampleTreatment(id: 'b', nextDue: DateTime.utc(2024, 11, 23)), // 30 días
        sampleTreatment(id: 'c', nextDue: DateTime.utc(2024, 11, 24)), // 31 días
        sampleTreatment(id: 'x', nextDue: DateTime.utc(2024, 10, 1), active: false),
      ], today);
      expect(s.pending.map((i) => i.treatment.id), ['a', 'b']);
      expect(s.upToDate.map((t) => t.id), ['c']);
    });

    test('countByType cuenta por tipo', () {
      final list = [
        sampleTreatment(id: 'a'),
        sampleTreatment(id: 'b', type: EventType.deworming, name: 'Drontal'),
        sampleTreatment(id: 'c', type: EventType.deworming, name: 'Otro'),
      ];
      expect(countByType(list, EventType.deworming), 2);
      expect(countByType(list, EventType.fleaTick), 0);
    });
  });

  group('appliedThisMonth', () {
    test('cuenta vacunas, desparasitaciones y antipulgas del mes en curso', () {
      final events = [
        sampleEvent(id: 'a', occurredAt: DateTime(2024, 10, 3)),
        sampleEvent(id: 'b', type: EventType.deworming, occurredAt: DateTime(2024, 10, 20)),
        sampleEvent(id: 'c', type: EventType.checkup, occurredAt: DateTime(2024, 10, 5)),
        sampleEvent(id: 'd', occurredAt: DateTime(2024, 9, 30)),
        sampleEvent(id: 'e', occurredAt: DateTime(2023, 10, 5)),
      ];
      expect(appliedThisMonth(events, DateTime(2024, 10, 24)), 2);
    });
  });
}
