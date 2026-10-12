import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/enums.dart';
import '../ui/carnet/carnet_screen.dart';
import '../ui/events/event_detail_screen.dart';
import '../ui/events/event_form_screen.dart';
import '../ui/history/history_screen.dart';
import '../ui/home/home_screen.dart';
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
          builder: (_, _) => const OnboardingScreen(),
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
          builder: (_, s) {
            final type = s.uri.queryParameters['type'];
            return EventFormScreen(
              petId: s.uri.queryParameters['petId'],
              initialType: type == null ? null : EventType.values.byName(type),
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

  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Historial'),
            NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Mascotas'),
            NavigationDestination(icon: Icon(Icons.tune), label: 'Ajustes'),
          ],
        ),
      );
}
