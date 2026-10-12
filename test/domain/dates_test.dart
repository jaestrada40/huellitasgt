import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/dates.dart';
import 'package:huellitas/domain/enums.dart';

DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  group('addInterval', () {
    test('suma días y semanas', () {
      expect(addInterval(d(2024, 10, 24), 10, IntervalUnit.days), d(2024, 11, 3));
      expect(addInterval(d(2024, 10, 24), 2, IntervalUnit.weeks), d(2024, 11, 7));
    });
    test('suma meses', () {
      expect(addInterval(d(2024, 10, 24), 1, IntervalUnit.months), d(2024, 11, 24));
      expect(addInterval(d(2024, 11, 30), 3, IntervalUnit.months), d(2025, 2, 28));
    });
    test('ajusta fin de mes', () {
      expect(addInterval(d(2025, 1, 31), 1, IntervalUnit.months), d(2025, 2, 28));
      expect(addInterval(d(2024, 1, 31), 1, IntervalUnit.months), d(2024, 2, 29));
    });
    test('suma años y ajusta el 29 de febrero', () {
      expect(addInterval(d(2024, 10, 24), 1, IntervalUnit.years), d(2025, 10, 24));
      expect(addInterval(d(2024, 2, 29), 1, IntervalUnit.years), d(2025, 2, 28));
    });
    test('ignora la hora de la fecha de origen', () {
      expect(addInterval(DateTime(2024, 10, 24, 23, 59), 1, IntervalUnit.days), d(2024, 10, 25));
    });
  });

  group('daysUntil', () {
    test('mismo día, mañana y hace 3 días', () {
      expect(daysUntil(d(2024, 10, 24), d(2024, 10, 24)), 0);
      expect(daysUntil(d(2024, 10, 25), d(2024, 10, 24)), 1);
      expect(daysUntil(d(2024, 10, 21), d(2024, 10, 24)), -3);
    });
    test('ignora la hora de "hoy"', () {
      expect(daysUntil(d(2024, 10, 25), DateTime(2024, 10, 24, 23, 59)), 1);
    });
  });

  test('EventType.canRecur solo para vacuna, desparasitación y antipulgas', () {
    expect(EventType.vaccine.canRecur, isTrue);
    expect(EventType.deworming.canRecur, isTrue);
    expect(EventType.fleaTick.canRecur, isTrue);
    expect(EventType.illness.canRecur, isFalse);
    expect(EventType.checkup.canRecur, isFalse);
  });
}
