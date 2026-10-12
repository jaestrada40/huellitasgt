import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/app/app.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('el shell muestra las 4 pestañas y navega', (tester) async {
    final env = await createEnv();
    await tester.pumpWidget(ProviderScope(
      overrides: env.overrides,
      child: const HuellitasApp(initialLocation: '/home', bundledFont: false),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Inicio', 'Historial', 'Mascotas', 'Ajustes']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await unmount(tester);
    addTearDown(env.db.close);
  });
}
