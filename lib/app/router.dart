import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/enums.dart';
import '../ui/carnet/carnet_screen.dart';
import '../ui/events/event_detail_screen.dart';
import '../ui/events/event_form_screen.dart';
import '../ui/history/history_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/theme.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/profile/weight_screen.dart';
import '../ui/settings/pin_setup_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/pets/pet_form_screen.dart';
import '../ui/pets/pets_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({required String initialLocation}) => GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/onboarding',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => OnboardingScreen(replay: s.uri.queryParameters['replay'] == '1'),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/pets', builder: (_, _) => const PetsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
            ]),
          ],
        ),
        GoRoute(
          path: '/settings/pin',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, _) => const PinSetupScreen(),
        ),
        GoRoute(
          path: '/events/new',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (_, s) {
            final type = s.uri.queryParameters['type'];
            return MaterialPage(
              fullscreenDialog: true, // se abre como hoja desde abajo
              key: s.pageKey,
              child: EventFormScreen(
                petId: s.uri.queryParameters['petId'],
                initialType: type == null ? null : EventType.values.byName(type),
              ),
            );
          },
        ),
        GoRoute(
          path: '/events/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => EventDetailScreen(eventId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/pets/new',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => PetFormScreen(first: s.uri.queryParameters['first'] == '1'),
        ),
        GoRoute(
          path: '/pets/:id/edit',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => PetFormScreen(petId: s.pathParameters['id']),
        ),
        GoRoute(
          path: '/pets/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => ProfileScreen(petId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/pets/:id/carnet',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => CarnetScreen(petId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/pets/:id/weight',
          parentNavigatorKey: rootNavigatorKey,
          builder: (_, s) => WeightScreen(petId: s.pathParameters['id']!),
        ),
      ],
    );

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    (Icons.schedule_outlined, Icons.schedule_rounded, 'Historial'),
    (Icons.pets_outlined, Icons.pets, 'Mascotas'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: InkResponse(
                      onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          i == shell.currentIndex ? _tabs[i].$2 : _tabs[i].$1,
                          size: 24,
                          color: i == shell.currentIndex ? AppColors.primary : AppColors.inkSoft,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tabs[i].$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: i == shell.currentIndex ? AppColors.primary : AppColors.inkSoft,
                          ),
                        ),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
}
