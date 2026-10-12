import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/ui/events/event_detail_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  Future<TestEnv> setup(WidgetTester tester) async {
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      await DriftEventRepository(env.db).save(sampleEvent(notes: 'Sin reacciones'), const []);
    });
    await pumpScreen(tester, env, const EventDetailScreen(eventId: 'e1'));
    return env;
  }

  testWidgets('muestra el detalle del evento', (tester) async {
    await setup(tester);
    expect(find.text('Antirrábica'), findsWidgets);
    expect(find.text('Sin reacciones'), findsOneWidget);
    expect(find.text('Dra. Carmen Morales'), findsOneWidget);
    expect(find.text('Toby'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('eliminar pide confirmación, borra el evento y regresa', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.byKey(const Key('deleteEventButton')));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar este registro?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    final e = await runDb(tester, () => DriftEventRepository(env.db).get('e1'));
    expect(e, isNull);
    expect(find.text('open'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('cancelar la confirmación no borra', (tester) async {
    final env = await setup(tester);
    await tester.tap(find.byKey(const Key('deleteEventButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    final e = await runDb(tester, () => DriftEventRepository(env.db).get('e1'));
    expect(e, isNotNull);
    await unmount(tester);
  });
}
