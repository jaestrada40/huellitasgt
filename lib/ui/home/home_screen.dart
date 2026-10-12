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
    final pet = ref.watch(currentPetProvider);

    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inicio')),
        body: Center(
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
      );
    }

    final now = ref.watch(clockProvider)();
    final all = ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[];
    final mine = all.where((t) => t.petId == pet.id).toList();
    final events = ref.watch(eventsForPetProvider(pet.id)).asData?.value ?? const <HealthEvent>[];
    final items = homeItems(mine, now);
    final overdue = items.where((i) => i.status == DueStatus.overdue).length;
    final percent = percentUpToDate(mine, now);
    final notificationsOk = ref.watch(notificationsAllowedProvider).asData?.value ?? true;
    final remindBackup = needsBackupReminder(
      lastBackup: ref.watch(prefsProvider).lastBackupAt,
      now: now,
      hasData: events.isNotEmpty,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/new?petId=${pet.id}'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (pets.length > 1)
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in pets)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => ref.read(selectedPetIdProvider.notifier).select(p.id),
                        child: Column(children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: p.id == pet.id ? AppColors.primary : Colors.transparent, width: 2),
                            ),
                            child: PetAvatar(pet: p, size: 44),
                          ),
                          Text(p.name, style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          if (!notificationsOk)
            AppCard(
              stripe: AppColors.orange,
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
              stripe: AppColors.primary,
              onTap: () => context.go('/settings'),
              child: const Text('Haz un respaldo para no perder el historial si cambias de teléfono.'),
            ),
          AppCard(
            child: Row(children: [
              Icon(overdue == 0 ? Icons.verified : Icons.warning_amber_rounded,
                  color: overdue == 0 ? AppColors.primary : AppColors.coral, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Estado general', style: TextStyle(color: AppColors.inkSoft)),
                  Text(
                    overdue == 0 ? 'Todo bajo control' : (overdue == 1 ? '1 tarea atrasada' : '$overdue tareas atrasadas'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
              StatusChip('$percent% al día', overdue == 0 ? StatusKind.ok : StatusKind.overdue),
            ]),
          ),
          const SectionHeader('Lo que toca pronto'),
          if (items.isEmpty)
            const AppCard(
              child: Text('Aún no hay recordatorios. Registra una vacuna o desparasitación con frecuencia y aquí verás cuándo toca la siguiente.'),
            ),
          for (final item in items) _ReminderCard(item: item),
          if (events.isNotEmpty) ...[
            const SectionHeader('Registrado recientemente'),
            for (final e in events.take(2))
              AppCard(
                onTap: () => context.push('/events/${e.id}'),
                child: Row(children: [
                  Icon(iconForType(e.type), color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(fmtDay(e.occurredAt), style: const TextStyle(color: AppColors.inkSoft)),
                    ]),
                  ),
                ]),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.item});
  final HomeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = item.treatment;
    final stripe = switch (item.status) {
      DueStatus.overdue => AppColors.coral,
      DueStatus.dueSoon => AppColors.orange,
      DueStatus.upcoming => AppColors.primary,
    };
    return AppCard(
      stripe: stripe,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(iconForType(t.type), color: stripe),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(t.type.label, style: const TextStyle(color: AppColors.inkSoft)),
            ]),
          ),
          StatusChip.forDue(item.status, item.label),
        ]),
        const SizedBox(height: 8),
        Text('Fecha: ${fmtDay(t.nextDueDate)}', style: const TextStyle(color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () async {
            await ref.read(healthServiceProvider).markDone(t.id);
            await ref.read(reminderCoordinatorProvider).sync();
          },
          icon: const Icon(Icons.check),
          label: const Text('Marcar como hecha'),
        ),
      ]),
    );
  }
}
