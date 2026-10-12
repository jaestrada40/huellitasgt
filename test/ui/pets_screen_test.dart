import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/pets/pets_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  testWidgets('lista mascotas con edad y pendientes; sin pendientes dice Al día', (tester) async {
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftPetRepository(env.db).save(samplePet(id: 'p2', name: 'Misi'));
      await DriftTreatmentRepository(env.db).save(sampleTreatment(nextDue: DateTime.utc(2024, 10, 21)));
    });
    await pumpScreen(tester, env, const PetsScreen());

    expect(find.text('Toby'), findsOneWidget);
    expect(find.text('Perro · Golden Retriever · 3 años'), findsNWidgets(2));
    expect(find.text('1 pendiente'), findsOneWidget);
    expect(find.text('Al día'), findsOneWidget);
    await unmount(tester);
  });
}
