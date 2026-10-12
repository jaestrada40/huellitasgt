import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/domain/weight_logic.dart';

WeightEntry w(String id, DateTime d, double kg) => WeightEntry(id: id, petId: 'p1', date: d, kg: kg);

void main() {
  final today = DateTime.utc(2024, 10, 24);

  test('sin registros es nulo', () {
    expect(weightTrend(const [], today), isNull);
  });

  test('un solo registro: peso actual y sin variación', () {
    final t = weightTrend([w('a', DateTime.utc(2024, 10, 1), 28.5)], today)!;
    expect(t.current, 28.5);
    expect(t.deltaVsMonthAgo, isNull);
  });

  test('variación frente al último registro de hace 30 días o más', () {
    final t = weightTrend([
      w('a', DateTime.utc(2024, 10, 1), 28.5),
      w('b', DateTime.utc(2024, 8, 3), 28.2),
      w('c', DateTime.utc(2024, 6, 10), 27.9),
    ], today)!;
    expect(t.current, 28.5);
    expect(t.deltaVsMonthAgo, closeTo(0.3, 0.0001));
  });

  test('si todos los registros son recientes no hay variación', () {
    final t = weightTrend([
      w('a', DateTime.utc(2024, 10, 20), 28.5),
      w('b', DateTime.utc(2024, 10, 10), 28.2),
    ], today)!;
    expect(t.deltaVsMonthAgo, isNull);
  });

  test('no depende del orden de entrada', () {
    final t = weightTrend([
      w('c', DateTime.utc(2024, 6, 10), 27.9),
      w('a', DateTime.utc(2024, 10, 1), 28.5),
    ], today)!;
    expect(t.current, 28.5);
    expect(t.deltaVsMonthAgo, closeTo(0.6, 0.0001));
  });
}
