import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/profile/profile_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    // Pantalla alta: el perfil es una lista perezosa y debe construir todo.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db).save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 21)));
    });
    await pumpScreen(tester, env, const ProfileScreen(petId: 'p1'));
    return env;
  }

  testWidgets('muestra datos de la mascota y el estado de protección', (tester) async {
    await setup(tester);
    expect(find.text('Toby'), findsWidgets);
    expect(find.text('3a 4m'), findsOneWidget);
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Atrasada · hace 3 días'), findsOneWidget);
    expect(find.text('Dra. Carmen Morales'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('archivar pide confirmación y oculta a la mascota', (tester) async {
    final env = await setup(tester);
    await tester.ensureVisible(find.text('Archivar mascota'));
    await tester.tap(find.text('Archivar mascota'));
    await tester.pumpAndSettle();
    expect(find.text('¿Archivar a Toby?'), findsOneWidget);

    await tester.tap(find.text('Archivar'));
    await tester.pumpAndSettle();

    final visible = await runDb(tester, () => DriftPetRepository(env.db).watchAll().first);
    expect(visible, isEmpty);
    expect(find.text('NAV:/pets'), findsOneWidget);
    expect(env.scheduler.syncCount, greaterThan(0));
    await unmount(tester);
  });
}
