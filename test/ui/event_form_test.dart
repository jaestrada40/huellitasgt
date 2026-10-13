import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/events/event_form_screen.dart';

import '../helpers/io_helpers.dart';
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

  testWidgets('guardar y agregar otra vacuna: dos registros separados, el formulario sigue abierto', (tester) async {
    final env = await setup(tester);
    Future<void> tapAddAnother() async {
      await tester.ensureVisible(find.byKey(const Key('saveAndAddAnother')));
      await tester.tap(find.byKey(const Key('saveAndAddAnother')));
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byKey(const Key('eventTitleField')), 'Múltiple');
    await tester.enterText(find.widgetWithText(TextFormField, 'Veterinario o clínica (opcional)'), 'Dr. Chete');
    await tester.ensureVisible(find.text('Cada 1 año'));
    await tester.tap(find.text('Cada 1 año'));
    await tester.pump();
    await tapAddAnother();

    // Sigue en el formulario, con lo propio de cada vacuna en blanco.
    expect(find.text('open'), findsNothing);
    expect(find.text('Guardada: Múltiple. Agrega la siguiente.'), findsOneWidget);
    final title = tester.widget<TextFormField>(find.byKey(const Key('eventTitleField')));
    expect(title.controller!.text, isEmpty);
    expect(find.text('Dr. Chete'), findsOneWidget); // el veterinario se conserva

    await tester.enterText(find.byKey(const Key('eventTitleField')), 'Antirrábica');
    await tester.ensureVisible(find.text('Cada 1 año'));
    await tester.tap(find.text('Cada 1 año'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events.map((e) => e.title).toSet(), {'Múltiple', 'Antirrábica'});
    expect(events.every((e) => e.vetName == 'Dr. Chete'), isTrue);
    final treatments = await runDb(tester, () => DriftTreatmentRepository(env.db).active());
    expect(treatments.map((t) => t.name).toSet(), {'Múltiple', 'Antirrábica'}); // cada una con su recordatorio
    expect(find.text('open'), findsOneWidget); // el último «Guardar» sí cierra
    await unmount(tester);
  });

  testWidgets('quitar una foto adjunta antes de guardar: desaparece y se borra el archivo', (tester) async {
    final env = await setup(tester);
    env.pickedPhoto = (await tester.runAsync(() => writePng(env.docs, 'toma.png')))!;

    await tester.ensureVisible(find.text('Adjuntar foto del carnet o recibo'));
    await tester.tap(find.text('Adjuntar foto del carnet o recibo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galería'));
    await settleIo(tester);
    await tester.pumpAndSettle();

    final stored = env.docs.listSync(recursive: true).whereType<File>().where((f) => f.path.contains('attachments')).toList();
    expect(stored, hasLength(1));
    expect(find.byKey(const Key('removeAttachment_0')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('removeAttachment_0')));
    await tester.tap(find.byKey(const Key('removeAttachment_0')));
    await settleIo(tester);

    expect(find.byKey(const Key('removeAttachment_0')), findsNothing);
    expect(stored.single.existsSync(), isFalse);
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
