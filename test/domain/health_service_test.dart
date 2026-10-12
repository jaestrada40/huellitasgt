import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/health_service.dart';

void main() {
  late AppDatabase db;
  late DriftTreatmentRepository treatments;
  late DriftEventRepository events;
  late DriftWeightRepository weights;
  late HealthService service;
  var n = 0;
  final now = DateTime(2024, 10, 24, 10);

  LogEventInput vaccine({
    String title = 'Antirrábica',
    DateTime? at,
    int? value = 1,
    IntervalUnit? unit = IntervalUnit.years,
    EventType type = EventType.vaccine,
    double? weightKg,
    List<NewAttachment> attachments = const [],
  }) =>
      LogEventInput(
        petId: 'p1',
        type: type,
        title: title,
        occurredAt: at ?? now,
        intervalValue: value,
        intervalUnit: unit,
        weightKg: weightKg,
        attachments: attachments,
      );

  setUp(() {
    n = 0;
    db = AppDatabase.memory();
    treatments = DriftTreatmentRepository(db);
    events = DriftEventRepository(db);
    weights = DriftWeightRepository(db);
    service = HealthService(
      events: events,
      treatments: treatments,
      weights: weights,
      now: () => now,
      newId: () => 'id${n++}',
    );
  });
  tearDown(() => db.close());

  test('vacuna con 1 año crea tratamiento con próxima fecha y enlaza el evento', () async {
    final e = await service.logEvent(vaccine());
    final t = (await treatments.active()).single;
    expect(t.nextDueDate, DateTime.utc(2025, 10, 24));
    expect(t.name, 'Antirrábica');
    expect(e.treatmentId, t.id);
    expect((await events.get(e.id))!.title, 'Antirrábica');
  });

  test('mismo producto con otras mayúsculas/espacios actualiza el mismo tratamiento', () async {
    await service.logEvent(vaccine(title: 'Antirrábica'));
    await service.logEvent(vaccine(title: '  antirrábica  ', at: DateTime(2025, 1, 10)));
    final all = await treatments.active();
    expect(all.length, 1);
    expect(all.single.nextDueDate, DateTime.utc(2026, 1, 10));
  });

  test('enfermedad o consulta con frecuencia NO crea tratamiento', () async {
    final e = await service.logEvent(vaccine(type: EventType.illness, title: 'Gastritis'));
    await service.logEvent(vaccine(type: EventType.checkup, title: 'Rutina'));
    expect(await treatments.active(), isEmpty);
    expect(e.treatmentId, isNull);
  });

  test('frecuencia 0, negativa o sin unidad se rechaza', () {
    expect(() => service.logEvent(vaccine(value: 0)), throwsArgumentError);
    expect(() => service.logEvent(vaccine(value: -1)), throwsArgumentError);
    expect(() => service.logEvent(vaccine(value: 1, unit: null)), throwsArgumentError);
  });

  test('título vacío o solo espacios se rechaza', () {
    expect(() => service.logEvent(vaccine(title: '   ')), throwsArgumentError);
  });

  test('evento sin frecuencia solo guarda el evento', () async {
    final e = await service.logEvent(vaccine(value: null, unit: null));
    expect(await treatments.active(), isEmpty);
    expect(e.treatmentId, isNull);
  });

  test('registrar un evento más viejo no atrasa la próxima fecha', () async {
    await service.logEvent(vaccine(at: DateTime(2024, 10, 24)));
    await service.logEvent(vaccine(at: DateTime(2023, 10, 20)));
    expect((await treatments.active()).single.nextDueDate, DateTime.utc(2025, 10, 24));
  });

  test('markDone crea evento de hoy y mueve la fecha desde hoy', () async {
    await service.logEvent(vaccine(at: DateTime(2023, 10, 21))); // próxima 2024-10-21: atrasada
    final t = (await treatments.active()).single;
    expect(t.nextDueDate, DateTime.utc(2024, 10, 21));

    final done = await service.markDone(t.id);
    expect(done.occurredAt, now);
    expect(done.treatmentId, t.id);
    expect((await treatments.get(t.id))!.nextDueDate, DateTime.utc(2025, 10, 24));
    expect((await events.watchForPet('p1').first).length, 2);
  });

  test('markDone con id inexistente lanza StateError', () {
    expect(() => service.markDone('nope'), throwsStateError);
  });

  test('un peso en el evento también crea un registro de peso', () async {
    await service.logEvent(vaccine(value: null, unit: null, weightKg: 28.5));
    final w = (await weights.watchForPet('p1').first).single;
    expect(w.kg, 28.5);
    expect(w.date, DateTime.utc(2024, 10, 24));
  });

  test('guarda los adjuntos del evento', () async {
    final e = await service.logEvent(vaccine(
      value: null,
      unit: null,
      attachments: const [
        NewAttachment(relativePath: 'attachments/x.jpg', kind: AttachmentKind.image, label: 'Carnet'),
      ],
    ));
    final list = await events.attachmentsFor(e.id);
    expect(list.single.relativePath, 'attachments/x.jpg');
  });
}
