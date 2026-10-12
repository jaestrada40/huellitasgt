import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/pets/pet_form_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('sin nombre muestra el error y no guarda', (tester) async {
    tall(tester);
    final env = await createEnv();
    await pumpScreen(tester, env, const PetFormScreen(first: true));

    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe el nombre'), findsOneWidget);
    final pets = await runDb(tester, () => DriftPetRepository(env.db).all());
    expect(pets, isEmpty);
    await unmount(tester);
  });

  testWidgets('guarda una gata con peso, guarda tu nombre, programa avisos y va a Inicio', (tester) async {
    tall(tester);
    final env = await createEnv();
    await pumpScreen(tester, env, const PetFormScreen(first: true));
    expect(find.text('Agrega tu primera mascota'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('userNameField')), '  Javier ');
    await tester.enterText(find.byKey(const Key('petNameField')), '  Misi ');
    await tester.enterText(find.byKey(const Key('petWeightField')), '4,2');
    await tester.tap(find.text('Gato'));
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final pets = await runDb(tester, () => DriftPetRepository(env.db).all());
    expect(pets.single.name, 'Misi');
    expect(pets.single.species, PetSpecies.cat);
    final weights = await runDb(tester, () => DriftWeightRepository(env.db).watchForPet(pets.single.id).first);
    expect(weights.single.kg, 4.2);
    expect(env.prefs.userName, 'Javier');
    expect(env.scheduler.syncCount, greaterThan(0));
    expect(find.text('NAV:/home'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('peso inválido muestra error y no guarda', (tester) async {
    tall(tester);
    final env = await createEnv();
    await pumpScreen(tester, env, const PetFormScreen(first: true));
    await tester.enterText(find.byKey(const Key('petNameField')), 'Misi');
    await tester.enterText(find.byKey(const Key('petWeightField')), 'abc');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un peso válido'), findsOneWidget);
    final pets = await runDb(tester, () => DriftPetRepository(env.db).all());
    expect(pets, isEmpty);
    await unmount(tester);
  });
}
