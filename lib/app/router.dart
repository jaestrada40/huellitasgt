import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/enums.dart';
import '../ui/events/event_detail_screen.dart';
import '../ui/events/event_form_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/pets/pet_form_screen.dart';
import '../ui/pets/pets_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Pantalla provisional; cada tarea de UI reemplaza la suya por la real.
class _Stub extends StatelessWidget {
  const _Stub(this.title);
  final String title;
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Text(title)));
}

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
              GoRoute(path: '/history', builder: (_, _) => const _Stub('Historial')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/pets', builder: (_, _) => const PetsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/settings', builder: (_, _) => const _Stub('Ajustes')),
            ]),
          ],
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
