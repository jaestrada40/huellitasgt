import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/prescription_parser.dart';

// Lo que Vision devuelve, línea por línea, para la receta de Koko.
const koko = '''
VET-PRO
HOSPITAL VETERINARIO
E-MAIL: hospitalveterinario.vetpro@gmail.com
TELEFONOS: 7965-3347 y 5732-4808
KM. 47 CARRETERA A CIUDAD VIEJA CASA # 1 LA ANTIGUA GUATEMALA
CONSULTA NUMERO: 8182
PACIENTE: KOKO ESTRADA
FECHA: 19/10/2026 15:46
MEDICAMENTOS
- NUMELVI 31,6 LBS DOSIS: DAR 1 TABLETA CADA 24 HRS POR 3 SEMANAS ()
- CLORFENAMINA 8MG DOSIS: 1 TAB CADA 24 HORAS DURANTE 5 DIAS ()
- KIROFTAL CIPROXYN DOSIS: 2 GOTAS EN EL OJO DERECHO CADA 12 HRS DURANTE 7
DIAS, ESPERAR UN MINUTO Y APLICAR "TEAR" ()
- TEARS LAGRIMAS DOSIS: 2 GOTAS EN CADA OJO CADA 12 HRS DURANTE 10 DIAS ()
PROGRAMA DE VACUNAS
''';

void main() {
  test('receta de Koko: fecha, paciente y los 4 medicamentos', () {
    final r = parsePrescription(koko);
    expect(r.date, DateTime(2026, 10, 19));
    expect(r.patient, 'KOKO ESTRADA');
    expect(r.meds.map((m) => m.name), ['Numelvi', 'Clorfenamina 8mg', 'Kiroftal ciproxyn', 'Tears lagrimas']);
    expect(r.meds[0].instructions, 'Dar 1 tableta cada 24 hrs por 3 semanas');
    expect(r.meds[1].instructions, '1 tab cada 24 horas durante 5 dias');
    // La indicación partida en dos líneas se junta.
    expect(r.meds[2].instructions,
        '2 gotas en el ojo derecho cada 12 hrs durante 7 dias, esperar un minuto y aplicar "tear"');
    expect(r.meds[3].instructions, '2 gotas en cada ojo cada 12 hrs durante 10 dias');
  });

  test('paciente y fecha en la misma línea', () {
    final r = parsePrescription('PACIENTE: KOKO ESTRADA FECHA: 19/10/2026 15:46\nMEDICAMENTOS\n- X DOSIS: 1 TAB CADA 8 HRS POR 2 DIAS');
    expect(r.patient, 'KOKO ESTRADA');
    expect(r.date, DateTime(2026, 10, 19));
    expect(r.meds.single.name, 'X');
  });

  test('el OCR confunde DOSIS (DOS1S) y aun así separa nombre e indicación', () {
    final r = parsePrescription('MEDICAMENTOS\n- AMOXICILINA 250MG DOS1S: 1 TAB CADA 12 HRS POR 7 DIAS');
    expect(r.meds.single.name, 'Amoxicilina 250mg');
    expect(r.meds.single.instructions, '1 tab cada 12 hrs por 7 dias');
  });

  test('sin la palabra DOSIS el renglón queda como indicación para que la persona lo corrija', () {
    final r = parsePrescription('MEDICAMENTOS\n- Dar medio comprimido con la comida');
    expect(r.meds.single.name, isEmpty);
    expect(r.meds.single.instructions, 'Dar medio comprimido con la comida');
  });

  test('texto sin medicamentos ni fecha devuelve vacío sin fallar', () {
    final r = parsePrescription('hola\nmundo');
    expect(r.meds.map((m) => m.instructions), ['Hola mundo']); // sin encabezado todo se toma como un renglón
    expect(r.date, isNull);
    expect(parsePrescription('').meds, isEmpty);
  });

  test('fecha imposible se ignora', () {
    expect(parsePrescription('FECHA: 45/13/2026').date, isNull);
  });

  test('un paréntesis suelto que el OCR deja al final no queda en la indicación', () {
    final r = parsePrescription('MEDICAMENTOS\n- CLORFENAMINA 8MG DOSIS: 1 TAB CADA 24 HORAS DURANTE 5 DIAS (');
    expect(r.meds.single.instructions, '1 tab cada 24 horas durante 5 dias');
  });
}
