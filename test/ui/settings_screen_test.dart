import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/ui/settings/settings_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  // Pantalla alta: Ajustes es una lista perezosa y debe construir todo.
  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('muestra las secciones y que aún no hay respaldo', (tester) async {
    tallScreen(tester);
    final env = await createEnv();
    await pumpScreen(tester, env, const SettingsScreen());
    expect(find.text('Bloquear con Face ID / huella'), findsOneWidget);
    expect(find.text('Hora del aviso'), findsOneWidget);
    expect(find.text('Exportar respaldo'), findsOneWidget);
    expect(find.text('Importar respaldo'), findsOneWidget);
    expect(find.text('Aún no has hecho un respaldo'), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(find.textContaining('sesión'), findsNothing);
    await unmount(tester);
  });

  testWidgets('con respaldo previo muestra la fecha', (tester) async {
    tallScreen(tester);
    final env = await createEnv();
    await env.prefs.setLastBackupAt(DateTime(2024, 10, 2, 12));
    await pumpScreen(tester, env, const SettingsScreen());
    expect(find.textContaining('Último respaldo'), findsOneWidget);
    await unmount(tester);
  });
}
