import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/format.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  test('fecha larga del saludo', () {
    expect(fmtLongDate(DateTime(2026, 10, 11)), 'domingo, 11 de octubre');
  });

  test('día corto sin año y mes corto', () {
    expect(fmtShortDay(DateTime(2026, 10, 9)), '9 oct');
  });

  test('saludo con y sin nombre', () {
    expect(greeting('Javier'), 'Hola, Javier');
    expect(greeting(null), 'Hola');
  });

  test('frecuencia en palabras', () {
    expect(frequencyLabel(1, IntervalUnit.months), 'Cada 1 mes');
    expect(frequencyLabel(3, IntervalUnit.months), 'Cada 3 meses');
    expect(frequencyLabel(1, IntervalUnit.years), 'Cada 1 año');
    expect(frequencyLabel(2, IntervalUnit.weeks), 'Cada 2 semanas');
    expect(frequencyLabel(10, IntervalUnit.days), 'Cada 10 días');
  });
}
