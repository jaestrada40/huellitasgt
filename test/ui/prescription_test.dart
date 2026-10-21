import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/ui/meds/meds_screen.dart';
import 'package:huellitas/ui/meds/prescription_screen.dart';

import '../helpers/io_helpers.dart';
import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv(); // hoy = 24 oct 2024, 10:00
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const PrescriptionScreen(petId: 'p1'));
    return env;
  }

  /// Pone la foto y espera a que se guarde y a que termine la lectura (el aviso).
  Future<void> pickPhoto(WidgetTester tester, TestEnv env) async {
    env.pickedPhoto = (await tester.runAsync(() => writePng(env.docs, 'receta.png')))!;
    await tester.tap(find.byKey(const Key('addPrescriptionPhoto')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galería'));
    await settleUntil(tester, find.byKey(const Key('prescriptionNotice')));
  }

  Future<void> save(WidgetTester tester, {bool closes = true}) async {
    await tester.ensureVisible(find.byKey(const Key('savePrescription')));
    await tester.tap(find.byKey(const Key('savePrescription')));
    if (closes) {
      await settleUntil(tester, find.text('open')); // se guardó y volvió a la pantalla anterior
    } else {
      await settleIo(tester);
    }
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

  testWidgets('al escribir o dictar la indicación se llenan las horas y los días', (tester) async {
    await setup(tester);
    await tester.enterText(find.byKey(const Key('medInstructions_0')), 'Dar 1 tableta cada 24 hrs por 3 semanas');
    await tester.pump();
    expect(text(tester, 'medEvery_0'), '24');
    expect(text(tester, 'medDays_0'), '21');

    // Lo escrito a mano ya no se pisa.
    await tester.enterText(find.byKey(const Key('medDays_0')), '10');
    await tester.enterText(find.byKey(const Key('medInstructions_0')), 'Dar 1 tableta cada 12 hrs por 3 semanas');
    await tester.pump();
    expect(text(tester, 'medEvery_0'), '12'); // se llenó sola: sigue a la indicación
    expect(text(tester, 'medDays_0'), '10'); // la persona la escribió: no se pisa
    await unmount(tester);
  });

  testWidgets('sin foto: guarda la receta, los medicamentos y programa las dosis', (tester) async {
    final env = await setup(tester);
    await tester.enterText(find.byKey(const Key('medName_0')), 'Clorfenamina 8 mg');
    await tester.enterText(find.byKey(const Key('medInstructions_0')), '1 tab cada 24 horas durante 5 días');
    await tester.pump();
    await save(tester);

    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events.single.title, 'Receta');
    expect(events.single.notes, 'Clorfenamina 8 mg: 1 tab cada 24 horas durante 5 días');
    final atts = await runDb(tester, () => DriftEventRepository(env.db).attachmentsFor(events.single.id));
    expect(atts, isEmpty);

    final meds = await runDb(tester, () => DriftMedicationRepository(env.db).all());
    expect(meds.single.name, 'Clorfenamina 8 mg');
    expect((meds.single.everyHours, meds.single.days), (24, 5));
    expect(meds.single.eventId, events.single.id);
    expect(meds.single.startAt, DateTime(2024, 10, 24, 11)); // próxima hora en punto
    expect(env.scheduler.last.where((r) => r.treatmentId == meds.single.id), hasLength(5));
    expect(find.text('open'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('con foto: queda adjunta al registro de la receta', (tester) async {
    final env = await setup(tester);
    await pickPhoto(tester, env);
    expect(find.byKey(const Key('removePrescriptionPhoto')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('medName_0')), 'Numelvi');
    await tester.enterText(find.byKey(const Key('medEvery_0')), '24');
    await tester.enterText(find.byKey(const Key('medDays_0')), '21');
    await save(tester);

    final e = (await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first)).single;
    final atts = await runDb(tester, () => DriftEventRepository(env.db).attachmentsFor(e.id));
    expect(atts.single.kind, AttachmentKind.image);
    expect(atts.single.label, 'Receta');
    await unmount(tester);
  });

  testWidgets('quitar la foto la borra y se puede guardar igual', (tester) async {
    final env = await setup(tester);
    await pickPhoto(tester, env);
    await tester.tap(find.byKey(const Key('removePrescriptionPhoto')));
    await settleIo(tester);
    expect(find.byKey(const Key('addPrescriptionPhoto')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('sin nombre o con horario inválido no guarda', (tester) async {
    final env = await setup(tester);
    await save(tester, closes: false);
    expect(find.text('Escribe el nombre'), findsOneWidget);
    expect(find.text('1 a 168'), findsOneWidget);
    expect(find.text('1 a 365'), findsOneWidget);
    expect(await runDb(tester, () => DriftMedicationRepository(env.db).all()), isEmpty);
    await unmount(tester);
  });

  testWidgets('varios medicamentos: la receta de Koko genera todas sus dosis', (tester) async {
    final env = await setup(tester);
    Future<void> fill(int i, String name, String instr) async {
      await tester.enterText(find.byKey(Key('medName_$i')), name);
      await tester.enterText(find.byKey(Key('medInstructions_$i')), instr);
      await tester.pump();
    }

    await fill(0, 'Numelvi', 'DAR 1 TABLETA CADA 24 HRS POR 3 SEMANAS');
    for (final (i, n, t) in [
      (1, 'Clorfenamina 8 mg', '1 TAB CADA 24 HORAS DURANTE 5 DIAS'),
      (2, 'Kiroftal ciproxyn', '2 GOTAS EN EL OJO DERECHO CADA 12 HRS DURANTE 7 DIAS'),
      (3, 'Tears lágrimas', '2 GOTAS EN CADA OJO CADA 12 HRS DURANTE 10 DIAS'),
    ]) {
      await tester.ensureVisible(find.byKey(const Key('addMedication')));
      await tester.tap(find.byKey(const Key('addMedication')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(Key('medName_$i')));
      await fill(i, n, t);
    }
    await save(tester);

    final meds = await runDb(tester, () => DriftMedicationRepository(env.db).all());
    expect(meds.map((m) => m.name), unorderedEquals(['Numelvi', 'Clorfenamina 8 mg', 'Kiroftal ciproxyn', 'Tears lágrimas']));
    // 21 + 5 + 14 + 20 = 60 dosis y el cumpleaños: se respeta el tope de 60 avisos de iOS.
    expect(meds.map((m) => m.days), unorderedEquals([21, 5, 7, 10]));
    expect(env.scheduler.last, hasLength(60));
    expect(env.scheduler.last.map((r) => r.treatmentId), contains('p1')); // el cumpleaños no se desplaza
    await unmount(tester);
  });

  testWidgets('pantalla de medicinas: marcar una dosis la quita de los avisos', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftMedicationRepository(env.db).saveAll([
        Medication(
          id: 'm1',
          petId: 'p1',
          name: 'Numelvi',
          everyHours: 24,
          days: 3,
          startAt: DateTime(2024, 10, 24, 12),
        ),
      ]);
    });
    await pumpScreen(tester, env, const MedsScreen(petId: 'p1'));
    await settleUntil(tester, find.textContaining('dosis dadas')); // los datos llegan por streams
    expect(find.text('Numelvi'), findsWidgets);
    expect(find.textContaining('0 de 3 dosis dadas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dose_m1_0')));
    await settleUntil(tester, find.textContaining('1 de 3 dosis dadas'));
    expect(find.textContaining('1 de 3 dosis dadas'), findsOneWidget);
    expect(env.scheduler.last.where((r) => r.treatmentId == 'm1'), hasLength(2));
    await unmount(tester);
  });

  const koko = '''
PACIENTE: KOKO ESTRADA
FECHA: 19/10/2026 15:46
MEDICAMENTOS
- NUMELVI 31,6 LBS DOSIS: DAR 1 TABLETA CADA 24 HRS POR 3 SEMANAS ()
- CLORFENAMINA 8MG DOSIS: 1 TAB CADA 24 HORAS DURANTE 5 DIAS ()
- KIROFTAL CIPROXYN DOSIS: 2 GOTAS EN EL OJO DERECHO CADA 12 HRS DURANTE 7
DIAS, ESPERAR UN MINUTO Y APLICAR "TEAR" ()
- TEARS LAGRIMAS DOSIS: 2 GOTAS EN CADA OJO CADA 12 HRS DURANTE 10 DIAS ()
PROGRAMA DE VACUNAS
''';

  testWidgets('al poner la foto se lee la receta: medicamentos, horarios y fecha se llenan solos', (tester) async {
    final env = await setup(tester);
    env.recognizedText = koko;
    await pickPhoto(tester, env);

    expect(find.byKey(const Key('prescriptionNotice')), findsOneWidget);
    expect(find.textContaining('Leí 4 medicamentos'), findsOneWidget);
    expect(text(tester, 'medName_0'), 'Numelvi');
    expect(text(tester, 'medName_3'), 'Tears lagrimas');
    expect(text(tester, 'medEvery_2'), '12');
    expect(text(tester, 'medDays_2'), '7');
    expect(find.text('19 oct 2026'), findsOneWidget); // fecha de la receta
    // Primera dosis 11:00 (la próxima hora): cada 12 h son 11:00 y 23:00.
    expect(tester.widget<Text>(find.byKey(const Key('medSchedule_2'))).data, startsWith('Horarios: 11:00 · 23:00 (2 al día)'));
    await save(tester);
    final meds = await runDb(tester, () => DriftMedicationRepository(env.db).all());
    expect(meds, hasLength(4));
    expect(meds.map((m) => m.days), unorderedEquals([21, 5, 7, 10]));
    await unmount(tester);
  });

  testWidgets('si la receta es de otra mascota se avisa', (tester) async {
    final env = await setup(tester);
    env.recognizedText = koko; // samplePet se llama Toby
    await pickPhoto(tester, env);
    expect(find.textContaining('la receta dice paciente «KOKO ESTRADA», no Toby'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('si no se puede leer la foto se avisa y se escribe a mano', (tester) async {
    final env = await setup(tester);
    env.recognizedText = null;
    await pickPhoto(tester, env);
    expect(find.textContaining('No pude leer la foto en este teléfono'), findsOneWidget);
    expect(text(tester, 'medName_0'), isEmpty);
    expect(find.byKey(const Key('rereadPrescription')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('lo ya escrito no se pierde al leer la foto: lo leído se agrega debajo', (tester) async {
    final env = await setup(tester);
    await tester.enterText(find.byKey(const Key('medName_0')), 'Vitaminas');
    env.recognizedText = koko;
    await pickPhoto(tester, env);
    expect(text(tester, 'medName_0'), 'Vitaminas');
    expect(text(tester, 'medName_1'), 'Numelvi');
    await unmount(tester);
  });

  testWidgets('letra a mano (poca seguridad del lector): no llena nada y pide escribirla', (tester) async {
    final env = await setup(tester);
    env.recognizedText = koko; // aunque el texto se parezca, con poca seguridad no se confía
    env.recognizedConfidence = 0.35;
    await pickPhoto(tester, env);
    expect(find.textContaining('mejor escribe los medicamentos tú'), findsOneWidget);
    expect(text(tester, 'medName_0'), isEmpty);
    expect(find.byKey(const Key('medName_1')), findsNothing);
    // La foto se guardó igual.
    expect(find.byKey(const Key('removePrescriptionPhoto')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('texto que no tiene el formato de receta: mismo aviso, sin llenar', (tester) async {
    final env = await setup(tester);
    env.recognizedText = 'Dr. Pérez\nreposo 3 días\nvolver en una semana';
    await pickPhoto(tester, env);
    expect(find.textContaining('mejor escribe los medicamentos tú'), findsOneWidget);
    expect(text(tester, 'medName_0'), isEmpty);
    await unmount(tester);
  });

  testWidgets('impresa pero sin horas o días legibles: llena y avisa cuál completar', (tester) async {
    final env = await setup(tester);
    env.recognizedText = 'MEDICAMENTOS\n- OMEPRAZOL DOSIS: MEDIA CAPSULA CON LA COMIDA';
    await pickPhoto(tester, env);
    expect(text(tester, 'medName_0'), 'Omeprazol');
    expect(text(tester, 'medEvery_0'), isEmpty);
    expect(find.textContaining('En Omeprazol no pude leer cada cuántas horas'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('cada medicamento puede tener su propia hora de primera dosis', (tester) async {
    final env = await setup(tester);
    await tester.enterText(find.byKey(const Key('medName_0')), 'Pastilla');
    await tester.enterText(find.byKey(const Key('medEvery_0')), '24');
    await tester.enterText(find.byKey(const Key('medDays_0')), '3');
    await tester.ensureVisible(find.byKey(const Key('addMedication')));
    await tester.tap(find.byKey(const Key('addMedication')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('medName_1')));
    await tester.enterText(find.byKey(const Key('medName_1')), 'Gotas');
    await tester.enterText(find.byKey(const Key('medEvery_1')), '12');
    await tester.enterText(find.byKey(const Key('medDays_1')), '2');

    // Las gotas empiezan a otra hora (5:30 de la tarde): se elige en su propia tarjeta.
    env.pickedDateTime = DateTime(2024, 10, 25, 17, 30);
    await tester.ensureVisible(find.byKey(const Key('medStart_1')));
    await tester.tap(find.byKey(const Key('medStart_1')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('medSchedule_1'))).data, startsWith('Horarios: 05:30 · 17:30'));
    expect(find.textContaining('Primera dosis: 25 oct 17:30'), findsOneWidget);
    expect(find.textContaining('Primera dosis: 24 oct 11:00'), findsOneWidget); // la otra no cambió

    await save(tester);
    final meds = await runDb(tester, () => DriftMedicationRepository(env.db).all());
    final byName = {for (final m in meds) m.name: m};
    expect(byName['Pastilla']!.startAt, DateTime(2024, 10, 24, 11));
    expect(byName['Gotas']!.startAt, DateTime(2024, 10, 25, 17, 30));
    await unmount(tester);
  });

  testWidgets('editar el horario de un medicamento guardado reprograma los avisos', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv(); // hoy = 24 oct 2024, 10:00
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftMedicationRepository(env.db).saveAll([
        Medication(id: 'm1', petId: 'p1', name: 'Gotas', everyHours: 24, days: 3, startAt: DateTime(2024, 10, 25, 9)),
      ]);
    });
    await pumpScreen(tester, env, const MedsScreen(petId: 'p1'));
    await settleUntil(tester, find.textContaining('dosis dadas')); // los datos llegan por streams
    await tester.tap(find.byKey(const Key('editMed_m1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editEvery')), '12');
    await tester.enterText(find.byKey(const Key('editDays')), '2');
    env.pickedDateTime = DateTime(2024, 10, 25, 7, 45);
    await tester.tap(find.byKey(const Key('editStart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveSchedule')));
    // Espera a que el guardado (E/S real) llegue a la base y a que se reprogramen los avisos.
    for (var i = 0; i < 100 && env.scheduler.last.where((r) => r.treatmentId == 'm1').length != 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final m = (await runDb(tester, () => DriftMedicationRepository(env.db).all())).single;
    expect((m.everyHours, m.days), (12, 2));
    expect(m.startAt, DateTime(2024, 10, 25, 7, 45)); // la hora cambió
    expect(env.scheduler.last.where((r) => r.treatmentId == 'm1').map((r) => r.fireAt), [
      DateTime(2024, 10, 25, 7, 45),
      DateTime(2024, 10, 25, 19, 45),
      DateTime(2024, 10, 26, 7, 45),
      DateTime(2024, 10, 26, 19, 45),
    ]);
    await unmount(tester);
  });

  testWidgets('editar con un horario inválido no guarda', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftMedicationRepository(env.db).saveAll([
        Medication(id: 'm1', petId: 'p1', name: 'Gotas', everyHours: 24, days: 3, startAt: DateTime(2024, 10, 25, 9)),
      ]);
    });
    await pumpScreen(tester, env, const MedsScreen(petId: 'p1'));
    await settleUntil(tester, find.textContaining('dosis dadas')); // los datos llegan por streams
    await tester.tap(find.byKey(const Key('editMed_m1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editEvery')), '0');
    await tester.tap(find.byKey(const Key('saveSchedule')));
    await tester.pumpAndSettle();
    expect(find.text('1 a 168'), findsOneWidget);
    expect((await runDb(tester, () => DriftMedicationRepository(env.db).all())).single.everyHours, 24);
    await unmount(tester);
  });

  testWidgets('en un teléfono angosto con letra grande los botones de la tarjeta se ven completos', (tester) async {
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftEventRepository(env.db).save(sampleEvent(id: 'e1'), const []);
      await DriftMedicationRepository(env.db).saveAll([
        Medication(id: 'm1', petId: 'p1', eventId: 'e1', name: 'Clorfenamina 8mg', everyHours: 24, days: 5, startAt: DateTime(2024, 10, 24, 21)),
      ]);
    });
    await pumpScreen(tester, env, const MedsScreen(petId: 'p1'));
    await settleUntil(tester, find.textContaining('dosis dadas')); // los datos llegan por streams
    for (final label in ['Ver receta', 'Editar horario', 'Terminar']) {
      final r = tester.getRect(find.text(label));
      expect(r.right, lessThanOrEqualTo(375), reason: '«$label» se corta por la derecha');
    }
    await unmount(tester);
  });

  testWidgets('al guardar la receta se pide el permiso de avisos si faltaba', (tester) async {
    final env = await setup(tester);
    env.scheduler.permission = false;
    await tester.enterText(find.byKey(const Key('medName_0')), 'Numelvi');
    await tester.enterText(find.byKey(const Key('medEvery_0')), '24');
    await tester.enterText(find.byKey(const Key('medDays_0')), '3');
    await save(tester);
    expect(env.scheduler.permission, isTrue); // FakeScheduler la concede al pedirla
    expect(env.scheduler.last.where((r) => r.title == 'Medicina · Toby'), hasLength(3));
    await unmount(tester);
  });

  testWidgets('pantalla de medicinas: «Por dar» muestra la próxima dosis de cada medicamento', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftMedicationRepository(env.db).saveAll([
        Medication(id: 'm1', petId: 'p1', name: 'Numelvi', everyHours: 24, days: 3, startAt: DateTime(2024, 10, 26, 7)),
      ]);
    });
    await pumpScreen(tester, env, const MedsScreen(petId: 'p1'));
    await settleUntil(tester, find.byKey(const Key('dose_m1_0')));
    expect(find.text('Por dar'), findsOneWidget);
    expect(find.text('26 oct'), findsOneWidget); // la primera dosis es dentro de dos días
    await unmount(tester);
  });

  testWidgets('pantalla de medicinas: sin tratamientos en curso dice que no hay pendientes', (tester) async {
    final env = await createEnv();
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const MedsScreen(petId: 'p1'));
    await settleIo(tester);
    expect(find.text('No hay medicinas pendientes.'), findsOneWidget);
    await unmount(tester);
  });
}
