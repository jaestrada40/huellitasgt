import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/weight_unit.dart';

void main() {
  test('kg no cambia', () {
    expect(WeightUnit.kg.fromKg(28), 28);
    expect(WeightUnit.kg.toKg(28), 28);
    expect(WeightUnit.kg.format(28), '28.0 kg');
  });

  test('kg a libras', () {
    expect(WeightUnit.lb.format(28), '61.7 lb');
    expect(WeightUnit.lb.fromKg(1), closeTo(2.2046, 1e-4));
  });

  test('libras a kg y de vuelta no pierde el valor mostrado', () {
    for (final lb in [66.0, 10.5, 0.5, 120.0]) {
      final kg = WeightUnit.lb.toKg(lb);
      expect(WeightUnit.lb.format(kg), '${lb.toStringAsFixed(1)} lb');
    }
  });
}
