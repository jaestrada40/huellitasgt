import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/events/event_form_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const EventFormScreen(petId: 'p1'));
    return env;
  }

  testWidgets('sin nombre muestra el error y no guarda', (tester) async {
    final env = await setup(tester);
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe el nombre'), findsOneWidget);
    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events, isEmpty);
    await unmount(tester);
  });

  testWidgets('vacuna con repetición de 1 año guarda evento y tratamiento y reprograma avisos', (tester) async {
    final env = await setup(tester);
    await tester.enterText(find.byKey(const Key('eventTitleField')), 'Antirrábica');
    await tester.ensureVisible(find.text('Cada 1 año'));
    await tester.tap(find.text('Cada 1 año'));
    await tester.pump();
    expect(find.text('PRÓXIMA FECHA'), findsOneWidget);
    expect(find.text('24 oct 2025'), findsOneWidget);

    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events.single.title, 'Antirrábica');
    final treatments = await runDb(tester, () => DriftTreatmentRepository(env.db).active());
    expect(treatments.single.nextDueDate, DateTime.utc(2025, 10, 24));
    expect(env.scheduler.syncCount, greaterThan(0));
    expect(find.text('open'), findsOneWidget); // volvió a la pantalla anterior
    await unmount(tester);
  });

  testWidgets('enfermedad no ofrece frecuencia de repetición', (tester) async {
    await setup(tester);
    expect(find.text('REPETIR'), findsOneWidget);
    await tester.ensureVisible(find.text('Enfermedades'));
    await tester.tap(find.text('Enfermedades'));
    await tester.pump();
    expect(find.text('REPETIR'), findsNothing);
    await unmount(tester);
  });

  testWidgets('peso inválido muestra error', (tester) async {
    await setup(tester);
    await tester.enterText(find.byKey(const Key('eventTitleField')), 'Consulta');
    await tester.enterText(find.byKey(const Key('eventWeightField')), 'abc');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un peso válido'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('"Listo" en el encabezado también guarda', (tester) async {
    final env = await setup(tester);
    await tester.enterText(find.byKey(const Key('eventTitleField')), 'Consulta de rutina');
    await tester.tap(find.text('Consultas'));
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events.single.title, 'Consulta de rutina');
    await unmount(tester);
  });
}
