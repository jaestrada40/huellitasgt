import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/pets/pet_form_screen.dart';

import '../helpers/io_helpers.dart';
import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

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

  Future<File> seedPetWithPhoto(WidgetTester tester, TestEnv env) async {
    final file = (await tester.runAsync(() => writePng(env.docs, 'attachments/k.jpg')))!;
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet(photoPath: 'attachments/k.jpg')));
    return file;
  }

  testWidgets('quitar foto y guardar: la mascota queda sin foto y se borra el archivo', (tester) async {
    tall(tester);
    final env = await createEnv();
    final file = await seedPetWithPhoto(tester, env);
    await pumpScreen(tester, env, const PetFormScreen(petId: 'p1'));
    await settleIo(tester);

    await tester.ensureVisible(find.byKey(const Key('removePhotoButton')));
    await tester.tap(find.byKey(const Key('removePhotoButton')));
    await tester.pump();
    expect(find.byKey(const Key('removePhotoButton')), findsNothing); // ya no hay foto que quitar

    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await settleIo(tester);

    final pet = await runDb(tester, () => DriftPetRepository(env.db).get('p1'));
    expect(pet!.photoPath, isNull);
    expect(file.existsSync(), isFalse);
    await unmount(tester);
  });

  testWidgets('quitar foto y cancelar: la foto original se conserva', (tester) async {
    tall(tester);
    final env = await createEnv();
    final file = await seedPetWithPhoto(tester, env);
    await pumpScreen(tester, env, const PetFormScreen(petId: 'p1'));
    await settleIo(tester);

    await tester.ensureVisible(find.byKey(const Key('removePhotoButton')));
    await tester.tap(find.byKey(const Key('removePhotoButton')));
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await settleIo(tester);

    final pet = await runDb(tester, () => DriftPetRepository(env.db).get('p1'));
    expect(pet!.photoPath, 'attachments/k.jpg');
    expect(file.existsSync(), isTrue);
    await unmount(tester);
  });

  testWidgets('al elegir una foto con el teclado abierto, el teclado se cierra antes de la hoja «Ajusta la foto»', (tester) async {
    tall(tester);
    // ¿Hay un campo de texto con el foco (o sea, el teclado abierto)?
    bool typing() =>
        FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    final env = await createEnv();
    env.pickedPhoto = (await tester.runAsync(() => writePng(env.docs, 'perro.png')))!;
    var typingWhenPickerOpened = true;
    env.onPickPhoto = () => typingWhenPickerOpened = typing();
    await pumpScreen(tester, env, const PetFormScreen(first: true));

    await tester.tap(find.byKey(const Key('petNameField')));
    await tester.pump();
    expect(typing(), isTrue); // teclado abierto

    await tester.tap(find.text('Elegir de la galería'));
    await settleUntil(tester, find.text('Ajusta la foto'));

    expect(find.text('Ajusta la foto'), findsOneWidget);
    expect(typingWhenPickerOpened, isFalse); // la galería se abre sin campo con foco
    expect(typing(), isFalse); // ningún campo con foco: el teclado se cerró
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    await unmount(tester);
  });
}
