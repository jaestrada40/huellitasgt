import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/pets/pet_form_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('sin nombre muestra el error y no guarda', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const PetFormScreen(first: true));

    await tester.ensureVisible(find.text('Guardar mascota'));
    await tester.tap(find.text('Guardar mascota'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el nombre'), findsOneWidget);
    final pets = await runDb(tester, () => DriftPetRepository(env.db).all());
    expect(pets, isEmpty);
  });

  testWidgets('guarda una gata, programa avisos y va a Inicio', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const PetFormScreen(first: true));

    await tester.enterText(find.byKey(const Key('petNameField')), '  Misi ');
    await tester.tap(find.text('Gato'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar mascota'));
    await tester.tap(find.text('Guardar mascota'));
    await tester.pumpAndSettle();

    final pets = await runDb(tester, () => DriftPetRepository(env.db).all());
    expect(pets.single.name, 'Misi');
    expect(pets.single.species, PetSpecies.cat);
    expect(env.scheduler.syncCount, greaterThan(0));
    expect(find.text('NAV:/home'), findsOneWidget);
  });
}
