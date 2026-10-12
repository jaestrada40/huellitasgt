import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/events/event_detail_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db).save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 29)));
      await DriftEventRepository(env.db)
          .save(sampleEvent(notes: 'Sin reacciones', treatmentId: 't1'), const []);
    });
    await pumpScreen(tester, env, const EventDetailScreen(eventId: 'e1'));
    return env;
  }

  testWidgets('muestra el detalle del evento', (tester) async {
    await setup(tester);
    expect(find.text('Antirrábica'), findsWidgets);
    expect(find.text('Sin reacciones'), findsOneWidget);
    expect(find.text('Dra. Carmen Morales'), findsOneWidget);
    expect(find.text('Toby'), findsOneWidget);
    expect(find.text('VACUNA'), findsOneWidget);
    expect(find.text('29 oct 2024'), findsOneWidget); // próxima fecha
    expect(find.text('Vence en 5 días'), findsOneWidget);
    expect(find.text('Cada 1 año'), findsOneWidget);
    expect(find.text('3 días antes'), findsOneWidget);
    expect(find.text('Sin fotos del carnet o recibo.'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Marcar como hecha mueve la próxima fecha desde hoy y reprograma avisos', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.text('Marcar como hecha'));
    await tester.pumpAndSettle();
    final t = await runDb(tester, () => DriftTreatmentRepository(env.db).get('t1'));
    expect(t!.nextDueDate, DateTime.utc(2025, 10, 24));
    expect(env.scheduler.syncCount, greaterThan(0));
    await unmount(tester);
  });

  testWidgets('eliminar pide confirmación, borra el evento y regresa', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.byKey(const Key('deleteEventButton')));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar este registro?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    final e = await runDb(tester, () => DriftEventRepository(env.db).get('e1'));
    expect(e, isNull);
    expect(find.text('open'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('cancelar la confirmación no borra', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.byKey(const Key('deleteEventButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    final e = await runDb(tester, () => DriftEventRepository(env.db).get('e1'));
    expect(e, isNotNull);
    await unmount(tester);
  });
}
