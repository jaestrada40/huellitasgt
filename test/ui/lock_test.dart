import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/pin_store.dart';
import 'package:huellitas/ui/settings/lock_gate.dart';
import 'package:huellitas/ui/settings/lock_screen.dart';
import 'package:huellitas/ui/settings/pin_setup_screen.dart';

import '../helpers/pump_app.dart';

Future<void> enter(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(Key('pin_$d')));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('LockScreen: PIN incorrecto muestra error; correcto desbloquea', (tester) async {
    final env = await createEnv();
    await PinStore(env.secrets).setPin('1234');
    var unlocked = 0;
    await pumpScreen(tester, env, LockScreen(onUnlocked: () => unlocked++));

    await enter(tester, '9999');
    expect(find.text('PIN incorrecto'), findsOneWidget);
    expect(unlocked, 0);

    await enter(tester, '1234');
    expect(unlocked, 1);
    await unmount(tester);
  });

  testWidgets('LockGate con bloqueo activo oculta el contenido hasta ingresar el PIN', (tester) async {
    final env = await createEnv();
    await PinStore(env.secrets).setPin('1234');
    await env.prefs.setLockEnabled(true);
    await pumpScreen(tester, env, const LockGate(child: Scaffold(body: Text('contenido'))));

    expect(find.byKey(const Key('pin_1')), findsOneWidget);
    await enter(tester, '1234');
    expect(find.byKey(const Key('pin_1')), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('LockGate con bloqueo desactivado no muestra el teclado', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const LockGate(child: Scaffold(body: Text('contenido'))));
    expect(find.byKey(const Key('pin_1')), findsNothing);
    expect(find.text('contenido'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('PinSetupScreen: PINes distintos reinician; iguales lo guardan', (tester) async {
    final env = await createEnv();
    await pumpScreen(tester, env, const PinSetupScreen());

    expect(find.text('Elige un PIN de 4 dígitos'), findsOneWidget);
    await enter(tester, '1234');
    expect(find.text('Confirma tu PIN'), findsOneWidget);
    await enter(tester, '4321');
    expect(find.text('Los PIN no coinciden'), findsOneWidget);
    expect(await PinStore(env.secrets).hasPin, isFalse);

    await enter(tester, '1234');
    await enter(tester, '1234');
    expect(await PinStore(env.secrets).hasPin, isTrue);
    expect(find.text('open'), findsOneWidget);
    await unmount(tester);
  });
}
