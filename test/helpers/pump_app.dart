import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:huellitas/app/providers.dart';
import 'package:huellitas/data/database.dart';
import 'package:huellitas/services/app_prefs.dart';
import 'package:huellitas/services/pin_store.dart';
import 'package:huellitas/ui/theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class InMemorySecrets implements SecretStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

class TestEnv {
  TestEnv({
    required this.db,
    required this.scheduler,
    required this.prefs,
    required this.docs,
    required this.now,
    required this.secrets,
  });

  final AppDatabase db;
  final FakeScheduler scheduler;
  final AppPrefs prefs;
  final Directory docs;
  final DateTime now;
  final InMemorySecrets secrets;
  final List<String> shared = [];
  File? pickedBackup;
  int _ids = 0;

  /// Agregar aquí los overrides de providers que se creen en tareas posteriores.
  List<Override> get overrides => [
        databaseProvider.overrideWithValue(db),
        docsDirProvider.overrideWithValue(docs),
        prefsProvider.overrideWithValue(prefs),
        schedulerProvider.overrideWithValue(scheduler),
        secretStoreProvider.overrideWithValue(secrets),
        clockProvider.overrideWithValue(() => now),
        idGeneratorProvider.overrideWithValue(() => 'id${_ids++}'),
        shareFileProvider.overrideWithValue((path) async => shared.add(path)),
        biometricAuthProvider.overrideWithValue(() async => false),
        pickBackupFileProvider.overrideWithValue(() async => pickedBackup),
      ];
}

Future<TestEnv> createEnv({DateTime? now}) async {
  SharedPreferences.setMockInitialValues({});
  await initializeDateFormatting('es_MX');
  return TestEnv(
    db: AppDatabase.memory(),
    scheduler: FakeScheduler(),
    prefs: await AppPrefs.load(),
    docs: Directory.systemTemp.createTempSync('huellitas_test_'),
    now: now ?? DateTime(2024, 10, 24, 10),
    secrets: InMemorySecrets(),
  );
}

/// Abre [screen] en la ruta /screen, encima de una pantalla con un botón
/// «open». Cualquier ruta desconocida muestra `NAV:ruta` para poder
/// comprobar la navegación.
Future<void> pumpScreen(WidgetTester tester, TestEnv env, Widget screen) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (c, _) => Scaffold(
          body: Center(child: TextButton(onPressed: () => c.push('/screen'), child: const Text('open'))),
        ),
      ),
      GoRoute(path: '/screen', builder: (_, _) => screen),
    ],
    errorBuilder: (_, state) => Scaffold(body: Center(child: Text('NAV:${state.uri}'))),
  );
  await tester.pumpWidget(ProviderScope(
    overrides: env.overrides,
    child: MaterialApp.router(
      routerConfig: router,
      theme: buildTheme(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
    await env.db.close();
  });
}

/// Desmonta el árbol dentro del cuerpo de la prueba. Drift deja un
/// `Timer.run` al cancelar sus streams y Flutter revisa los temporizadores
/// pendientes antes de ejecutar los `addTearDown`; llamar al final de toda
/// prueba cuya pantalla escuche streams.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

/// Para sembrar o consultar la BD dentro de un testWidgets sin que el reloj
/// falso de Flutter bloquee las operaciones asíncronas.
Future<T> runDb<T>(WidgetTester tester, Future<T> Function() f) async =>
    (await tester.runAsync(f)) as T;
