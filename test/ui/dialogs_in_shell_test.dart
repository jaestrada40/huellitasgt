import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/app/app.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('cerrar el diálogo de Privacidad deja Ajustes visible (no pantalla negra)', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv();
    await tester.pumpWidget(ProviderScope(
      overrides: env.overrides,
      child: const HuellitasApp(initialLocation: '/settings'),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Privacidad'));
    await tester.tap(find.text('Privacidad'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar'), findsNothing);
    expect(find.text('Notificaciones'), findsOneWidget);

    await unmount(tester);
    addTearDown(env.db.close);
  });

  testWidgets('elegir los días de anticipación cierra el diálogo y conserva Ajustes', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final env = await createEnv();
    await tester.pumpWidget(ProviderScope(
      overrides: env.overrides,
      child: const HuellitasApp(initialLocation: '/settings'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avisar con anticipación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7 días antes'));
    await tester.pumpAndSettle();

    expect(env.prefs.reminderDaysBefore, 7);
    expect(find.text('Hora del aviso'), findsOneWidget); // la hoja sigue abierta y Ajustes intacta

    await unmount(tester);
    addTearDown(env.db.close);
  });
}
