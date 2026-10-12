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
