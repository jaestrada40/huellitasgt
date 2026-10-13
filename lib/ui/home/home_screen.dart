import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/home_logic.dart';
import '../../domain/models.dart';
import '../../domain/treatment_status.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsProvider);
    if (petsAsync.asData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pets = petsAsync.asData!.value;
    if (pets.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.pets, size: 56, color: AppColors.primary),
                const SizedBox(height: 12),
                const Text('Aún no tienes mascotas'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/pets/new?first=1'),
                  child: const Text('Agrega tu primera mascota'),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final filter = ref.watch(homeFilterProvider);
    final selected = pets.where((p) => p.id == filter).firstOrNull;
    final names = {for (final p in pets) p.id: p.name};
    final all = (ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[])
        .where((t) => names.containsKey(t.petId) && (selected == null || t.petId == selected.id))
        .toList();
    final events = <HealthEvent>[
      for (final p in pets)
        if (selected == null || p.id == selected.id)
          ...(ref.watch(eventsForPetProvider(p.id)).asData?.value ?? const <HealthEvent>[]),
    ];
    final sections = homeSections(all, now);
    final notificationsOk = ref.watch(notificationsAllowedProvider).asData?.value ?? true;
    final remindBackup = needsBackupReminder(
      lastBackup: ref.watch(prefsProvider).lastBackupAt,
      now: now,
      hasData: events.isNotEmpty,
    );
    final pending = sections.pending.length;

    return Scaffold(
      floatingActionButton: _Fab(
        onTap: () => context.push('/events/new?petId=${(selected ?? pets.first).id}'),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
          children: [
            Text(fmtLongDate(now), style: AppText.bodyStrong),
            Text(greeting(ref.watch(prefsProvider).userName), style: AppText.h1),
            const SizedBox(height: 16),
            _PetFilter(pets: pets, selectedId: selected?.id),
            const SizedBox(height: 24),
            if (!notificationsOk)
              AppCard(
                color: AppColors.peach,
                child: Row(children: [
                  const Expanded(child: Text('Los avisos están desactivados. Actívalos para que Huellitas te recuerde.')),
                  TextButton(
                    onPressed: () async {
                      await ref.read(schedulerProvider).requestPermission();
                      ref.invalidate(notificationsAllowedProvider);
                      await ref.read(reminderCoordinatorProvider).sync();
                    },
                    child: const Text('Activar'),
                  ),
                ]),
              ),
            if (remindBackup)
              AppCard(
                color: AppColors.mint,
                onTap: () => context.go('/settings'),
                child: const Text('Haz un respaldo para no perder el historial si cambias de teléfono.'),
              ),
            Row(children: [
              const Expanded(child: Text('Lo que toca pronto', style: AppText.h2)),
              if (pending > 0) Text('$pending ${pending == 1 ? 'pendiente' : 'pendientes'}', style: AppText.bodyStrong),
            ]),
            const SizedBox(height: 12),
            if (sections.pending.isEmpty)
              const AppCard(
                child: Text('Aún no hay recordatorios. Registra una vacuna o desparasitación con frecuencia y aquí verás cuándo toca la siguiente.',
                    style: AppText.body),
              ),
            for (final item in sections.pending) _ReminderCard(item: item, petName: names[item.treatment.petId] ?? ''),
            const SectionHeader('Al día'),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: AppColors.greenBg, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: AppColors.greenInk, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '${sections.upToDate.length} ${sections.upToDate.length == 1 ? 'tratamiento' : 'tratamientos'}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    Text('vigentes · ${appliedThisMonth(events, now)} aplicados este mes', style: AppText.body),
                  ]),
                ),
              ]),
            ),
            Row(children: [
              for (final t in const [EventType.vaccine, EventType.deworming, EventType.fleaTick]) ...[
                Expanded(child: _StatCard(type: t, count: countByType(sections.upToDate, t))),
                if (t != EventType.fleaTick) const SizedBox(width: 12),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -4)],
        ),
        child: IconButton(
          key: const Key('newEventFab'),
          tooltip: 'Nuevo evento',
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 30),
        ),
      );
}

class _PetFilter extends ConsumerWidget {
  const _PetFilter({required this.pets, required this.selectedId});
  final List<Pet> pets;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget item({required Widget circle, required String label, required bool selected, required VoidCallback onTap}) =>
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 64,
            child: Column(children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? const [
                          BoxShadow(color: AppColors.canvas, spreadRadius: 2),
                          BoxShadow(color: AppColors.primary, spreadRadius: 5),
                        ]
                      : null,
                ),
                child: circle,
              ),
              const SizedBox(height: 10),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.inkSoft,
                  )),
            ]),
          ),
        );

    return SizedBox(
      height: 112,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.all(6),
        children: [
          item(
            circle: Container(
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.pets, color: AppColors.mintInk, size: 28),
            ),
            label: 'Todas',
            selected: selectedId == null,
            onTap: () => ref.read(homeFilterProvider.notifier).select(null),
          ),
          for (final p in pets) ...[
            const SizedBox(width: 16),
            item(
              circle: PetAvatar(pet: p, size: 64),
              label: p.name,
              selected: p.id == selectedId,
              onTap: () => ref.read(homeFilterProvider.notifier).select(p.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.item, required this.petName});
  final HomeItem item;
  final String petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = item.treatment;
    final overdue = item.status == DueStatus.overdue;
    final today = item.label == 'Hoy';
    final strong = overdue || today;
    final chipKind = overdue ? StatusKind.overdue : (today ? StatusKind.today : StatusKind.soon);
    return AppCard(
      ring: overdue ? AppColors.coral : null,
      onTap: () => context.push('/pets/${t.petId}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TypeIcon(t.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, style: AppText.cardTitle),
              Text('$petName · ${fmtDay(t.nextDueDate)}', style: AppText.body),
              // Debajo del título: al lado le quitaba ancho y partía palabras.
              const SizedBox(height: 6),
              StatusChip(item.label, chipKind),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 43,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(43),
              backgroundColor: strong ? AppColors.primary : AppColors.mint,
              foregroundColor: strong ? AppColors.onPrimary : AppColors.mintInk,
            ),
            onPressed: () async {
              await ref.read(healthServiceProvider).markDone(t.id);
              await ref.read(reminderCoordinatorProvider).sync();
            },
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text('Marcar como hecha'),
          ),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.type, required this.count});
  final EventType type;
  final int count;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(12),
        margin: EdgeInsets.zero,
        child: Column(children: [
          TypeIcon(type, size: 40),
          const SizedBox(height: 4),
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
          Text(type.pluralLabel, style: AppText.label, textAlign: TextAlign.center),
        ]),
      );
}
