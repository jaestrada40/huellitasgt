import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/carnet/carnet_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  testWidgets('lista solo vacunas, con aviso de que lo genera el usuario y sin textos oficiales', (tester) async {
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db).save(sampleTreatment());
      final events = DriftEventRepository(env.db);
      await events.save(sampleEvent(id: 'v', title: 'Antirrábica', treatmentId: 't1'), const []);
      await events.save(
          sampleEvent(id: 'd', type: EventType.deworming, title: 'Desparasitación interna'), const []);
    });
    await pumpScreen(tester, env, const CarnetScreen(petId: 'p1'));

    expect(find.text('Carnet de vacunación'), findsWidgets);
    expect(find.text('Resumen generado por ti a partir de tus registros'), findsOneWidget);
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Desparasitación interna'), findsNothing);
    expect(find.textContaining('Oficial'), findsNothing);
    expect(find.textContaining('SENASICA'), findsNothing);
    expect(find.textContaining('Folio'), findsNothing);
    await unmount(tester);
  });

  testWidgets('sin vacunas muestra el estado vacío', (tester) async {
    final env = await createEnv();
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const CarnetScreen(petId: 'p1'));
    expect(find.text('Aún no hay vacunas registradas'), findsOneWidget);
    await unmount(tester);
  });
}
