import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/settings/lock_gate.dart';
import '../ui/theme.dart';
import 'providers.dart';
import 'router.dart';

class HuellitasApp extends ConsumerStatefulWidget {
  const HuellitasApp({super.key, required this.initialLocation, this.tour});
  final String initialLocation;

  /// Solo desarrollo: rutas que se visitan solas, una cada 7 s.
  final List<String>? tour;

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
    final tour = widget.tour;
    if (tour != null) {
      var i = 0;
      _tourTimer = Timer.periodic(const Duration(seconds: 7), (_) {
        _router.go(tour[i % tour.length]);
        i++;
      });
    }
  }

  Timer? _tourTimer;

  @override
  void dispose() {
    _tourTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Huellitas',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
        builder: (context, child) => LockGate(child: child ?? const SizedBox.shrink()),
        locale: const Locale('es', 'MX'),
        supportedLocales: const [Locale('es', 'MX')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      );
}
