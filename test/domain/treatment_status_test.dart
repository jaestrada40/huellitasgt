import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/domain/treatment_status.dart';

final today = DateTime.utc(2024, 10, 24);

Treatment tr(DateTime due, {bool active = true, String id = 't'}) => Treatment(
      id: id,
      petId: 'p1',
      type: EventType.vaccine,
      name: 'Antirrábica',
      intervalValue: 1,
      intervalUnit: IntervalUnit.years,
      nextDueDate: due,
      active: active,
    );

void main() {
  test('dueStatus', () {
    expect(dueStatus(DateTime.utc(2024, 10, 23), today), DueStatus.overdue);
    expect(dueStatus(DateTime.utc(2024, 10, 24), today), DueStatus.dueSoon);
    expect(dueStatus(DateTime.utc(2024, 10, 31), today), DueStatus.dueSoon);
    expect(dueStatus(DateTime.utc(2024, 11, 1), today), DueStatus.upcoming);
  });

  test('dueLabel', () {
    expect(dueLabel(DateTime.utc(2024, 10, 21), today), 'Atrasada · hace 3 días');
    expect(dueLabel(DateTime.utc(2024, 10, 23), today), 'Atrasada · hace 1 día');
    expect(dueLabel(DateTime.utc(2024, 10, 24), today), 'Hoy');
    expect(dueLabel(DateTime.utc(2024, 10, 25), today), 'Vence en 1 día');
    expect(dueLabel(DateTime.utc(2024, 10, 29), today), 'Vence en 5 días');
    expect(dueLabel(DateTime.utc(2024, 11, 5), today), 'En 12 días');
  });

  group('percentUpToDate', () {
    test('sin tratamientos es 100 (no divide entre cero)', () {
      expect(percentUpToDate(const [], today), 100);
    });
    test('un atrasado de tres es 67', () {
      final list = [
        tr(DateTime.utc(2024, 10, 1), id: 'a'),
        tr(DateTime.utc(2024, 11, 1), id: 'b'),
        tr(DateTime.utc(2025, 1, 1), id: 'c'),
      ];
      expect(percentUpToDate(list, today), 67);
    });
    test('ignora inactivos', () {
      final list = [tr(DateTime.utc(2024, 10, 1), active: false)];
      expect(percentUpToDate(list, today), 100);
    });
    test('todos atrasados es 0', () {
      expect(percentUpToDate([tr(DateTime.utc(2024, 10, 1))], today), 0);
    });
  });
}
