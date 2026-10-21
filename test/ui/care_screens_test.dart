import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/models.dart';
import 'package:huellitas/domain/weight_unit.dart';
import 'package:huellitas/ui/care/expenses_screen.dart';
import 'package:huellitas/ui/care/food_screen.dart';
import 'package:huellitas/ui/care/routines_screen.dart';
import 'package:huellitas/ui/profile/profile_screen.dart';

import '../helpers/io_helpers.dart';
import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv(); // hoy = 24 oct 2024
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, screen);
    return env;
  }

  Future<void> saveSheet(WidgetTester tester) async {
    await tester.tap(find.text('Guardar'));
    await settleIo(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('gastos: agregar suma al total del mes', (tester) async {
    await setup(tester, const ExpensesScreen(petId: 'p1'));
    await tester.tap(find.byKey(const Key('newExpense')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expenseAmount')), '150.50');
    await saveSheet(tester);
    await tester.tap(find.byKey(const Key('newExpense')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expenseAmount')), '49,50');
    await tester.tap(find.text('Comida'));
    await saveSheet(tester);

    expect(tester.widget<Text>(find.byKey(const Key('monthTotal'))).data, 'Q 200.00');
    expect(find.text('Q 150.50'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('gastos: un monto vacío no guarda', (tester) async {
    await setup(tester, const ExpensesScreen(petId: 'p1'));
    await tester.tap(find.byKey(const Key('newExpense')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un monto válido'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('rutinas: sugerencia, guardar y «Hecho hoy»', (tester) async {
    await setup(tester, const RoutinesScreen(petId: 'p1'));
    await tester.tap(find.byKey(const Key('newRoutine')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Baño'));
    await tester.pump();
    await saveSheet(tester);

    expect(find.text('Cada 15 días'), findsOneWidget);
    expect(find.text('Aún sin registro'), findsOneWidget);
    await tester.tap(find.byKey(const Key('routineDone_id0')));
    await settleIo(tester);
    expect(find.text('Hecho hoy'), findsWidgets); // el chip de estado y el botón
    expect(find.text('Aún sin registro'), findsNothing);
    await unmount(tester);
  });

  testWidgets('comida: calcula cuándo se acaba y programa el aviso', (tester) async {
    final env = await setup(tester, const FoodScreen(petId: 'p1'));
    await tester.tap(find.byKey(const Key('newFood')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('foodBrand')), 'Pro Plan');
    await tester.enterText(find.byKey(const Key('foodKg')), '15');
    await tester.enterText(find.byKey(const Key('foodGrams')), '300');
    await saveSheet(tester);

    expect(find.textContaining('Quedan 50 días'), findsOneWidget);
    expect(env.scheduler.last.where((r) => r.title == 'Comida de Toby'), hasLength(1));
    await unmount(tester);
  });

  testWidgets('comida en libras: se escribe y se muestra en libras, y se guarda en kg', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv();
    await env.prefs.setWeightUnit(WeightUnit.lb);
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const FoodScreen(petId: 'p1'));

    await tester.tap(find.byKey(const Key('newFood')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('foodBrand')), 'Pro Plan');
    await tester.enterText(find.byKey(const Key('foodKg')), '40');
    await tester.enterText(find.byKey(const Key('foodGrams')), '300');
    await saveSheet(tester);

    expect(find.textContaining('40.0 lb · 300 g al día'), findsOneWidget);
    final food = (await runDb(tester, () => DriftCareRepository(env.db).foods())).single;
    expect(food.bagKg, closeTo(18.14, 0.01));
    expect(find.textContaining('Quedan 60 días'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('perfil: llamar al veterinario abre tel: y la clínica abre el mapa', (tester) async {
    final env = await setup(tester, const ProfileScreen(petId: 'p1'));
    await tester.ensureVisible(find.text('5555555555'));
    await tester.tap(find.text('5555555555'));
    await tester.tap(find.text('Vet Narvarte'));
    await tester.pump();
    expect(env.opened.first.toString(), 'tel:5555555555');
    expect(env.opened.last.host, 'www.google.com');
    expect(env.opened.last.queryParameters['query'], 'Vet Narvarte');
    await unmount(tester);
  });

  testWidgets('perfil: «En memoria» apaga vacunas y medicinas y quita los avisos', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftTreatmentRepository(env.db).save(sampleTreatment());
      await DriftMedicationRepository(env.db).saveAll([
        Medication(id: 'm1', petId: 'p1', name: 'Numelvi', everyHours: 24, days: 5, startAt: DateTime(2024, 10, 25, 9)),
      ]);
    });
    await pumpScreen(tester, env, const ProfileScreen(petId: 'p1'));
    await tester.ensureVisible(find.byKey(const Key('memorialButton')));
    await tester.tap(find.byKey(const Key('memorialButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await settleIo(tester);
    await tester.pumpAndSettle();

    final pet = await runDb(tester, () => DriftPetRepository(env.db).get('p1'));
    expect(pet!.inMemoriam, isTrue);
    expect(await runDb(tester, () => DriftTreatmentRepository(env.db).active()), isEmpty);
    expect((await runDb(tester, () => DriftMedicationRepository(env.db).all())).single.active, isFalse);
    expect(env.scheduler.last, isEmpty);
    expect(find.textContaining('En memoria desde'), findsOneWidget);
    expect(find.text('Cartel de mascota perdida'), findsNothing);
    await unmount(tester);
  });
}
