import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/home/home_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  testWidgets('sin mascotas invita a agregar la primera', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const HomeScreen());
    expect(find.text('Agrega tu primera mascota'), findsOneWidget);
    await tester.tap(find.text('Agrega tu primera mascota'));
    await tester.pumpAndSettle();
    expect(find.text('NAV:/pets/new?first=1'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('mascota sin tratamientos: saludo con nombre y sin recordatorios', (tester) async {
    final env = await createEnv();
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await env.prefs.setUserName('Javier');
    await pumpScreen(tester, env, const HomeScreen());
    expect(find.text('Hola, Javier'), findsOneWidget);
    expect(find.text('jueves, 24 de octubre'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.textContaining('Aún no hay recordatorios'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('tratamiento atrasado: se ve y "Marcar como hecha" lo mueve y reprograma avisos', (tester) async {
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db)
          .save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 21)));
    });
    await pumpScreen(tester, env, const HomeScreen());

    expect(find.text('Atrasada 3 días'), findsOneWidget);
    expect(find.text('1 pendiente'), findsOneWidget);
    expect(find.text('Toby · 21 oct 2024'), findsOneWidget);

    await tester.tap(find.text('Marcar como hecha').first);
    await tester.pumpAndSettle();

    final t = await runDb(tester, () => DriftTreatmentRepository(env.db).get('t1'));
    expect(t!.nextDueDate, DateTime.utc(2025, 10, 24));
    final events = await runDb(tester, () => DriftEventRepository(env.db).watchForPet('p1').first);
    expect(events.length, 1);
    expect(env.scheduler.syncCount, greaterThan(0));
    await unmount(tester);
  });
}
