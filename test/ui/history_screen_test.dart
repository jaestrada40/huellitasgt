import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/data/drift_repositories.dart';
import 'package:huellitas/domain/enums.dart';
import 'package:huellitas/ui/history/history_screen.dart';

import '../helpers/pump_app.dart';
import '../helpers/samples.dart';

void main() {
  testWidgets('filtra por búsqueda y por tipo, y permite restablecer', (tester) async {
    final env = await createEnv();
    await runDb(tester, () async {
      await DriftPetRepository(env.db).save(samplePet());
      final events = DriftEventRepository(env.db);
      await events.save(sampleEvent(id: 'a', title: 'Antirrábica', occurredAt: DateTime(2024, 10, 15)), const []);
      await events.save(
          sampleEvent(id: 'b', type: EventType.deworming, title: 'Desparasitación interna', occurredAt: DateTime(2024, 8, 10)),
          const []);
      await events.save(
          sampleEvent(id: 'c', type: EventType.checkup, title: 'Consulta dental', occurredAt: DateTime(2024, 8, 2)),
          const []);
    });
    await pumpScreen(tester, env, const HistoryScreen());

    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Consulta dental'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('historySearch')), 'rabi');
    await tester.pumpAndSettle();
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Consulta dental'), findsNothing);

    await tester.enterText(find.byKey(const Key('historySearch')), '');
    await tester.ensureVisible(find.text('Consultas'));
    await tester.tap(find.text('Consultas'));
    await tester.pumpAndSettle();
    expect(find.text('Consulta dental'), findsOneWidget);
    expect(find.text('Antirrábica'), findsNothing);

    await tester.enterText(find.byKey(const Key('historySearch')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Sin coincidencias'), findsOneWidget);

    await tester.tap(find.text('Restablecer filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Antirrábica'), findsOneWidget);
    expect(find.text('Consulta dental'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('sin registros muestra el estado vacío', (tester) async {
    final env = await createEnv();
    await runDb(tester, () => DriftPetRepository(env.db).save(samplePet()));
    await pumpScreen(tester, env, const HistoryScreen());
    expect(find.text('Aún no hay registros'), findsOneWidget);
    await unmount(tester);
  });
}
