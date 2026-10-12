import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/enums.dart';

String fmtDay(DateTime d) => DateFormat('d MMM y', 'es_MX').format(d);

String fmtDateTime(DateTime d) => DateFormat("d MMM y · HH:mm 'hrs'", 'es_MX').format(d);

IconData iconForType(EventType t) => switch (t) {
      EventType.vaccine => Icons.vaccines,
      EventType.deworming => Icons.medication,
      EventType.fleaTick => Icons.pest_control,
      EventType.illness => Icons.thermostat,
      EventType.checkup => Icons.medical_services,
    };

String speciesLabel(PetSpecies s) => switch (s) {
      PetSpecies.dog => 'Perro',
      PetSpecies.cat => 'Gato',
      PetSpecies.other => 'Otra mascota',
    };

/// «domingo, 11 de octubre»
String fmtLongDate(DateTime d) => DateFormat("EEEE, d 'de' MMMM", 'es_MX').format(d);

/// «9 oct»
String fmtShortDay(DateTime d) => DateFormat('d MMM', 'es_MX').format(d).replaceAll('.', '');

String greeting(String? name) => (name == null || name.isEmpty) ? 'Hola' : 'Hola, $name';

String frequencyLabel(int value, IntervalUnit unit) {
  final one = value == 1;
  final word = switch (unit) {
    IntervalUnit.days => one ? 'día' : 'días',
    IntervalUnit.weeks => one ? 'semana' : 'semanas',
    IntervalUnit.months => one ? 'mes' : 'meses',
    IntervalUnit.years => one ? 'año' : 'años',
  };
  return 'Cada $value $word';
}
