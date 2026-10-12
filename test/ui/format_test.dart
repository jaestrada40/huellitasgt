import 'package:flutter_test/flutter_test.dart';
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
}
