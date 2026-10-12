import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/enums.dart';
import '../domain/models.dart';

// El PDF usa la fuente estándar (Latin-1): acentos y ñ funcionan; evitar
// símbolos como viñetas o guiones largos.
const _disclaimer =
    'Documento generado por la persona usuaria con Huellitas a partir de sus propios registros. '
    'No es un documento oficial ni sustituye el carnet del veterinario.';

class PdfExporter {
  const PdfExporter();

  static final _day = DateFormat('dd/MM/yyyy');

  String _petLine(Pet p) {
    final parts = <String>[
      switch (p.species) {
        PetSpecies.dog => 'Perro',
        PetSpecies.cat => 'Gato',
        PetSpecies.other => 'Otra mascota',
      },
      if (p.breed != null) p.breed!,
      if (p.birthDate != null) 'Nacimiento: ${_day.format(p.birthDate!)}',
      if (p.microchip != null) 'Microchip: ${p.microchip}',
    ];
    return parts.join(' - ');
  }

  String _vet(HealthEvent e) =>
      [e.vetName, e.clinic].whereType<String>().where((s) => s.isNotEmpty).join(' / ');

  pw.TextStyle get _small => const pw.TextStyle(fontSize: 8);

  Future<Uint8List> history({
    required Pet pet,
    required List<HealthEvent> events,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (_) => [
        pw.Header(
          level: 0,
          child: pw.Text('Historial de salud - ${pet.name}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text(_petLine(pet)),
        pw.SizedBox(height: 12),
        if (events.isEmpty)
          pw.Text('Sin registros.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Fecha', 'Tipo', 'Detalle', 'Veterinario'],
            data: [
              for (final e in events)
                [
                  _day.format(e.occurredAt),
                  e.type.label,
                  [e.title, if (e.lot != null) 'Lote ${e.lot}', if (e.notes != null) e.notes!].join(' - '),
                  _vet(e),
                ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 16),
        pw.Text('Generado el ${_day.format(generatedAt)}', style: _small),
        pw.Text(_disclaimer, style: _small),
      ],
    ));
    return doc.save();
  }

  Future<Uint8List> carnet({
    required Pet pet,
    required List<HealthEvent> vaccines,
    required Map<String, Treatment> treatmentsById,
    required DateTime generatedAt,
  }) async {
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      build: (_) => [
        pw.Header(
          level: 0,
          child: pw.Text('Carnet de vacunacion - ${pet.name}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text(_petLine(pet)),
        pw.SizedBox(height: 12),
        if (vaccines.isEmpty)
          pw.Text('Aun no hay vacunas registradas.')
        else
          pw.TableHelper.fromTextArray(
            headers: ['Vacuna', 'Aplicada', 'Lote', 'Proxima', 'Veterinario'],
            data: [
              for (final e in vaccines)
                [
                  e.title,
                  _day.format(e.occurredAt),
                  e.lot ?? '',
                  _next(treatmentsById[e.treatmentId]),
                  _vet(e),
                ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        pw.SizedBox(height: 16),
        pw.Text('Generado el ${_day.format(generatedAt)}', style: _small),
        pw.Text(_disclaimer, style: _small),
      ],
    ));
    return doc.save();
  }

  String _next(Treatment? t) => (t != null && t.active) ? _day.format(t.nextDueDate) : '';
}
