import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/settings/lock_gate.dart';
import '../ui/theme.dart';
import 'providers.dart';
import 'router.dart';

class HuellitasApp extends ConsumerStatefulWidget {
  const HuellitasApp({super.key, required this.initialLocation, this.bundledFont = true});
  final String initialLocation;
  final bool bundledFont;

  @override
  ConsumerState<HuellitasApp> createState() => _HuellitasAppState();
}

class _HuellitasAppState extends ConsumerState<HuellitasApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void initState() {
    super.initState();
    // Reprograma los avisos cada vez que se abre la app.
    Future.microtask(() => ref.read(reminderCoordinatorProvider).sync());
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Huellitas',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(bundledFont: widget.bundledFont),
        routerConfig: _router,
        builder: (context, child) => LockGate(child: child ?? const SizedBox.shrink()),
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      );
}
