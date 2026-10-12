import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/age.dart';
import 'package:huellitas/domain/text.dart';

void main() {
  final today = DateTime.utc(2024, 10, 24);
  test('ageLabel', () {
    expect(ageLabel(DateTime.utc(2021, 6, 12), today), '3a 4m');
    expect(ageLabel(DateTime.utc(2022, 10, 24), today), '2a');
    expect(ageLabel(DateTime.utc(2024, 8, 31), today), '1m');
    expect(ageLabel(DateTime.utc(2024, 10, 24), today), '0m');
    expect(ageLabel(DateTime.utc(2030, 1, 1), today), '0m');
  });
  test('normalizeName ignora mayúsculas y espacios', () {
    expect(normalizeName('  Antirrábica '), normalizeName('antirrábica'));
    expect(normalizeName('Drontal   Plus'), 'drontal plus');
  });
  test('foldText quita acentos', () {
    expect(foldText('Desparasitación Ñandú'), 'desparasitacion nandu');
  });
}
