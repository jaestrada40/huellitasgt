import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/services/pdf_exporter.dart';

import '../helpers/samples.dart';

bool isPdf(Uint8List b) => String.fromCharCodes(b.take(4)) == '%PDF';

void main() {
  const exporter = PdfExporter();
  final at = DateTime(2024, 10, 24);

  test('historial con acentos genera un PDF', () async {
    final bytes = await exporter.history(
      pet: samplePet(name: 'Ñandú'),
      events: [
        sampleEvent(title: 'Desparasitación interna', notes: 'Sin reacción gastrointestinal'),
        sampleEvent(id: 'e2', type: EventType.checkup, title: 'Consulta de rutina'),
      ],
      generatedAt: at,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('historial sin eventos también genera PDF', () async {
    final bytes = await exporter.history(pet: samplePet(), events: const [], generatedAt: at);
    expect(isPdf(bytes), isTrue);
  });

  test('carnet con y sin tratamiento asociado genera PDF', () async {
    final bytes = await exporter.carnet(
      pet: samplePet(),
      vaccines: [sampleEvent(treatmentId: 't1'), sampleEvent(id: 'e2', title: 'Giardia')],
      treatmentsById: {'t1': sampleTreatment()},
      generatedAt: at,
    );
    expect(isPdf(bytes), isTrue);
  });
}
