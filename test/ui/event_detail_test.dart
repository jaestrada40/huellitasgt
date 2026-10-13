import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/events/event_detail_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

Future<File> _png(Directory dir, String name) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 20, 20), Paint()..color = Colors.green);
  final image = await recorder.endRecording().toImage(20, 20);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  return File('${dir.path}/$name')..writeAsBytesSync(bytes.buffer.asUint8List());
}

/// Los archivos y la BD usan E/S real, que el reloj falso no hace avanzar:
/// alterna tiempo real y cuadros hasta que se encadenan todos los pasos.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
}

void main() {
  Future<TestEnv> setup(WidgetTester tester, {bool withPhoto = false}) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv(); // hoy = 24 oct 2024
    if (withPhoto) {
      final photo = (await tester.runAsync(() => _png(env.docs, 'seed.png')))!;
      File('${env.docs.path}/attachments/a1.jpg')
        ..createSync(recursive: true)
        ..writeAsBytesSync(photo.readAsBytesSync());
    }
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db).save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 29)));
      await DriftEventRepository(env.db)
          .save(sampleEvent(notes: 'Sin reacciones', treatmentId: 't1'), [if (withPhoto) sampleAttachment()]);
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

  testWidgets('agregar foto a un registro guardado sin fotos', (tester) async {
    final env = await setup(tester);
    env.pickedPhoto = (await tester.runAsync(() => _png(env.docs, 'carnet.png')))!;

    await tester.ensureVisible(find.byKey(const Key('addDocumentPhoto')));
    await tester.tap(find.byKey(const Key('addDocumentPhoto')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galería'));
    await settleIo(tester);
    await tester.pumpAndSettle();

    final list = await runDb(tester, () => DriftEventRepository(env.db).attachmentsFor('e1'));
    expect(list, hasLength(1));
    expect(list.single.label, 'Comprobante');
    expect(env.docs.listSync(recursive: true).whereType<File>().any((f) => f.path.endsWith(list.single.relativePath)), isTrue);
    expect(find.text('Sin fotos del carnet o recibo.'), findsNothing);
    await unmount(tester);
  });

  testWidgets('cancelar el selector no agrega nada', (tester) async {
    final env = await setup(tester);
    env.pickedPhoto = null;
    await tester.ensureVisible(find.byKey(const Key('addDocumentPhoto')));
    await tester.tap(find.byKey(const Key('addDocumentPhoto')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cámara'));
    await tester.pumpAndSettle();
    final list = await runDb(tester, () => DriftEventRepository(env.db).attachmentsFor('e1'));
    expect(list, isEmpty);
    await unmount(tester);
  });

  testWidgets('eliminar una foto la quita del registro y borra el archivo', (tester) async {
    final env = await setup(tester, withPhoto: true);
    final stored = File('${env.docs.path}/attachments/a1.jpg');
    expect(stored.existsSync(), isTrue);

    await tester.ensureVisible(find.byType(Image).first);
    await tester.tap(find.byType(Image).first); // abre la foto
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('deletePhotoButton')));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar esta foto?'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await settleIo(tester);
    await tester.pumpAndSettle();

    final list = await runDb(tester, () => DriftEventRepository(env.db).attachmentsFor('e1'));
    expect(list, isEmpty);
    expect(stored.existsSync(), isFalse);
    expect(find.text('Sin fotos del carnet o recibo.'), findsOneWidget);
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
