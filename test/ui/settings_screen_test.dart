import 'package:flutter/material.dart';
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
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Bloquear con Face ID / huella'), findsOneWidget);
    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.text('Respaldo'), findsOneWidget);
    expect(find.text('Exportar historial'), findsOneWidget);
    expect(find.text('Ver bienvenida otra vez'), findsOneWidget);
    expect(find.text('Huellitas 1.0 · Hecho con cariño en México'), findsOneWidget);
    expect(find.text('Aún no has hecho un respaldo'), findsOneWidget);
    expect(find.textContaining('Compartir con familia'), findsNothing);
    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(find.textContaining('sesión'), findsNothing);
    await unmount(tester);
  });

  testWidgets('el nombre se muestra en el perfil y se edita al tocarlo', (tester) async {
    tallScreen(tester);
    final env = await createEnv();
    await env.prefs.setUserName('Javier');
    await pumpScreen(tester, env, const SettingsScreen());
    expect(find.text('Javier'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);

    await tester.tap(find.text('Javier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('userNameField')), 'Ana');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(env.prefs.userName, 'Ana');
    expect(find.text('Ana'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('las hojas de Respaldo y Notificaciones muestran sus opciones', (tester) async {
    tallScreen(tester);
    final env = await createEnv();
    await pumpScreen(tester, env, const SettingsScreen());

    await tester.tap(find.text('Respaldo'));
    await tester.pumpAndSettle();
    expect(find.text('Exportar respaldo'), findsOneWidget);
    expect(find.text('Importar respaldo'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // cierra la hoja
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notificaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Hora del aviso'), findsOneWidget);
    expect(find.text('Avisar con anticipación'), findsOneWidget);
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
