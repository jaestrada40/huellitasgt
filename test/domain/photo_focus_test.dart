import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/photo_focus.dart';

void main() {
  test('sin sobrante no se mueve', () {
    expect(nextFocus(0.3, 50, 0), 0.3);
  });

  test('arrastrar la mitad del sobrante recorre todo el rango', () {
    // sobrante 100 px: el borde a borde son 50 px por cada lado.
    expect(nextFocus(0, -50, 100), 1);
    expect(nextFocus(0, 50, 100), -1);
    expect(nextFocus(0, 25, 100), -0.5);
  });

  test('no pasa de los extremos', () {
    expect(nextFocus(0.9, -500, 100), 1);
    expect(nextFocus(-0.9, 500, 100), -1);
  });
}
