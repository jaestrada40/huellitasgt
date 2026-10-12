import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/database.dart';
import 'data/drift_repositories.dart';
import 'dev/demo_seed.dart';
import 'services/app_prefs.dart';
import 'services/local_notifications_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');

  final docs = await getApplicationDocumentsDirectory();
  final db = AppDatabase.file(File(p.join(docs.path, 'huellitas.sqlite')));
  final prefs = await AppPrefs.load();
  final scheduler = LocalNotificationsScheduler();
  await scheduler.init();

  if (kSeedDemo) await seedDemo(db, prefs);

  final hasPets = (await DriftPetRepository(db).all()).any((p) => !p.archived);

  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      docsDirProvider.overrideWithValue(docs),
      prefsProvider.overrideWithValue(prefs),
      schedulerProvider.overrideWithValue(scheduler),
    ],
    child: HuellitasApp(
      initialLocation: hasPets ? '/home' : '/onboarding',
      tour: kSeedDemo && kTour ? kTourRoutes : null,
    ),
  ));
}
