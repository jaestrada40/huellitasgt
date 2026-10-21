/// Por debajo de esta seguridad promedio del lector (letra a mano, foto borrosa)
/// no se llena nada: es mejor que la persona escriba que adivinar una dosis.
const double kMinOcrConfidence = 0.6;

class ParsedMedication {
  const ParsedMedication({required this.name, required this.instructions});
  final String name;
  final String instructions;
}

class ParsedPrescription {
  const ParsedPrescription({this.meds = const [], this.date, this.patient});
  final List<ParsedMedication> meds;
  final DateTime? date;
  final String? patient;
}

final _bullet = RegExp(r'^[-•·*–—]+\s*');
// «DOSIS», aceptando los errores típicos del OCR (DOS1S, D0SIS).
final _dosis = RegExp(r'd[o0]s[i1l]s\s*:?', caseSensitive: false);
final _stop = RegExp(r'programa\s+de\s+vacunas|firma|m[eé]dico\s+veterinario', caseSensitive: false);

String _sentence(String s) {
  final t = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

String _cleanName(String s) {
  var t = s
      .replaceAll(_bullet, '')
      .replaceAll(RegExp(r'\(\s*\)'), '')
      // El peso de la mascota que algunas recetas ponen junto al nombre.
      .replaceAll(RegExp(r'\b\d+(?:[.,]\d+)?\s*(?:lbs?|libras?|kgs?)\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'[:\-\s()]+$'), '');
  return _sentence(t);
}

String _cleanInstructions(String s) {
  final t = s.replaceAll(RegExp(r'\(\s*\)'), '').replaceAll(RegExp(r'[\s,;.:()]+$'), '');
  return _sentence(t);
}

/// Convierte el texto que leyó el OCR de una receta en medicamentos.
/// Entiende el formato «NOMBRE DOSIS: indicación» con un medicamento por
/// viñeta, que puede partirse en varias líneas. Es lo mejor posible: la persona
/// siempre revisa el resultado antes de guardar.
ParsedPrescription parsePrescription(String raw) {
  final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  DateTime? date;
  String? patient;
  for (final l in lines) {
    final d = RegExp(r'fecha\s*:?\s*(\d{1,2})/(\d{1,2})/(\d{4})', caseSensitive: false).firstMatch(l);
    if (d != null && date == null) {
      final day = int.parse(d.group(1)!), month = int.parse(d.group(2)!), year = int.parse(d.group(3)!);
      final candidate = DateTime(year, month, day);
      if (candidate.month == month && candidate.day == day) date = candidate;
    }
    final p = RegExp(r'paciente\s*:?\s*(.+?)(?=\s+fecha\b|$)', caseSensitive: false).firstMatch(l);
    if (p != null && patient == null) patient = p.group(1)!.trim();
  }

  final header = lines.indexWhere((l) => RegExp(r'medicamentos', caseSensitive: false).hasMatch(l));
  final entries = <String>[];
  for (final l in lines.skip(header + 1)) {
    final hasDosis = _dosis.hasMatch(l);
    if (!hasDosis && _stop.hasMatch(l)) break;
    if (RegExp(r'^[-–—_=\s]+$').hasMatch(l)) continue; // rayas decorativas
    if (hasDosis || _bullet.hasMatch(l) || entries.isEmpty) {
      entries.add(l);
    } else {
      entries[entries.length - 1] = '${entries.last} $l';
    }
  }

  final meds = <ParsedMedication>[];
  for (final e in entries) {
    final m = _dosis.firstMatch(e);
    final name = _cleanName(m == null ? '' : e.substring(0, m.start));
    final instructions = _cleanInstructions(m == null ? e.replaceAll(_bullet, '') : e.substring(m.end));
    if (name.isEmpty && instructions.isEmpty) continue;
    meds.add(ParsedMedication(name: name, instructions: instructions));
  }
  return ParsedPrescription(meds: meds, date: date, patient: patient);
}
