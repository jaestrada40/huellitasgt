import 'dates.dart';
import 'enums.dart';
import 'models.dart';
import 'repositories.dart';

class NewAttachment {
  const NewAttachment({required this.relativePath, required this.kind, this.label});
  final String relativePath;
  final AttachmentKind kind;
  final String? label;
}

class LogEventInput {
  const LogEventInput({
    required this.petId,
    required this.type,
    required this.title,
    required this.occurredAt,
    this.product,
    this.lot,
    this.vetName,
    this.clinic,
    this.notes,
    this.weightKg,
    this.intervalValue,
    this.intervalUnit,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
    this.attachments = const [],
  });

  final String petId;
  final EventType type;
  final String title;
  final DateTime occurredAt;
  final String? product;
  final String? lot;
  final String? vetName;
  final String? clinic;
  final String? notes;
  final double? weightKg;
  final int? intervalValue;
  final IntervalUnit? intervalUnit;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final List<NewAttachment> attachments;
}

class HealthService {
  HealthService({
    required EventRepository events,
    required TreatmentRepository treatments,
    required WeightRepository weights,
    required DateTime Function() now,
    required String Function() newId,
  })  : _events = events,
        _treatments = treatments,
        _weights = weights,
        _now = now,
        _newId = newId;

  final EventRepository _events;
  final TreatmentRepository _treatments;
  final WeightRepository _weights;
  final DateTime Function() _now;
  final String Function() _newId;

  String? _clean(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  Future<HealthEvent> logEvent(LogEventInput i) async {
    final title = i.title.trim();
    if (title.isEmpty) {
      throw ArgumentError.value(i.title, 'title', 'no puede estar vacío');
    }
    final value = i.intervalValue;
    if (value != null && (value < 1 || i.intervalUnit == null)) {
      throw ArgumentError.value(value, 'intervalValue', 'frecuencia inválida');
    }

    String? treatmentId;
    if (value != null && i.type.canRecur) {
      final name = _clean(i.product) ?? title;
      final next = addInterval(i.occurredAt, value, i.intervalUnit!);
      final existing = await _treatments.find(i.petId, i.type, name);
      final Treatment t;
      if (existing == null) {
        t = Treatment(
          id: _newId(),
          petId: i.petId,
          type: i.type,
          name: name,
          intervalValue: value,
          intervalUnit: i.intervalUnit!,
          nextDueDate: next,
          reminderDaysBefore: i.reminderDaysBefore,
          reminderEnabled: i.reminderEnabled,
        );
      } else {
        // Un evento más viejo (captura retroactiva) no debe atrasar la fecha.
        final keep = existing.nextDueDate.isAfter(next) && existing.active;
        t = existing.copyWith(
          intervalValue: value,
          intervalUnit: i.intervalUnit,
          nextDueDate: keep ? existing.nextDueDate : next,
          reminderDaysBefore: i.reminderDaysBefore,
          reminderEnabled: i.reminderEnabled,
          active: true,
        );
      }
      await _treatments.save(t);
      treatmentId = t.id;
    }

    final event = HealthEvent(
      id: _newId(),
      petId: i.petId,
      treatmentId: treatmentId,
      type: i.type,
      title: title,
      occurredAt: i.occurredAt,
      product: _clean(i.product),
      lot: _clean(i.lot),
      vetName: _clean(i.vetName),
      clinic: _clean(i.clinic),
      notes: _clean(i.notes),
      weightKg: i.weightKg,
      createdAt: _now(),
    );
    final attachments = [
      for (final a in i.attachments)
        Attachment(
          id: _newId(),
          eventId: event.id,
          relativePath: a.relativePath,
          kind: a.kind,
          label: a.label,
        ),
    ];
    await _events.save(event, attachments);

    if (i.weightKg != null) {
      await _weights.save(WeightEntry(
        id: _newId(),
        petId: i.petId,
        date: dateOnly(i.occurredAt),
        kg: i.weightKg!,
        note: title,
      ));
    }
    return event;
  }

  Future<HealthEvent> markDone(String treatmentId) async {
    final t = await _treatments.get(treatmentId);
    if (t == null) throw StateError('Tratamiento no encontrado: $treatmentId');
    return logEvent(LogEventInput(
      petId: t.petId,
      type: t.type,
      title: t.name,
      product: t.name,
      occurredAt: _now(),
      intervalValue: t.intervalValue,
      intervalUnit: t.intervalUnit,
      reminderEnabled: t.reminderEnabled,
      reminderDaysBefore: t.reminderDaysBefore,
    ));
  }
}
