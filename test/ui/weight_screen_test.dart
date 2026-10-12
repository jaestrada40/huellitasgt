import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/ui/profile/weight_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      final weights = DriftWeightRepository(env.db);
      await weights.save(WeightEntry(id: 'w1', petId: 'p1', date: DateTime.utc(2024, 10, 1), kg: 28.5));
      await weights.save(WeightEntry(id: 'w2', petId: 'p1', date: DateTime.utc(2024, 8, 3), kg: 28.2));
    });
    await pumpScreen(tester, env, const WeightScreen(petId: 'p1'));
    return env;
  }

  testWidgets('muestra peso actual y variación; no muestra rango ideal', (tester) async {
    await setup(tester);
    expect(find.text('28.5 kg'), findsWidgets);
    expect(find.textContaining('+0.3 kg vs mes pasado'), findsOneWidget);
    expect(find.textContaining('Rango ideal'), findsNothing);
    expect(find.textContaining('Óptimo'), findsNothing);
    await unmount(tester);
  });

  testWidgets('registrar peso valida y guarda con coma decimal', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.text('Registrar peso'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('weightField')), '0');
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un peso válido'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('weightField')), '29,1');
    await tester.tap(find.text('Guardar peso'));
    await tester.pumpAndSettle();

    final list = await runDb(tester, () => DriftWeightRepository(env.db).watchForPet('p1').first);
    expect(list.first.kg, 29.1);
    expect(list.length, 3);
    await unmount(tester);
  });
}
