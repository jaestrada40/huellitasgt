import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/app/app.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('el shell muestra las 4 pestañas y navega', (tester) async {
    final env = await createEnv();
    await tester.pumpWidget(ProviderScope(
      overrides: env.overrides,
      child: const HuellitasApp(initialLocation: '/home'),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Inicio', 'Historial', 'Mascotas', 'Ajustes']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Historial').last);
    await tester.pumpAndSettle();
    expect(find.text('Agrega una mascota para ver su historial'), findsOneWidget);

    await unmount(tester);
    addTearDown(env.db.close);
  });
}
