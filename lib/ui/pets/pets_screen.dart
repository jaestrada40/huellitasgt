import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class PetsScreen extends ConsumerWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final treatments = ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[];
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: const Text('Mascotas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(Icons.lock, size: 16, color: AppColors.primary),
              label: Text('${pets.length} ${pets.length == 1 ? 'compañero' : 'compañeros'} · 100% local'),
            ),
          ),
          const SizedBox(height: 8),
          for (final pet in pets)
            _PetCard(
              pet: pet,
              overdue: treatments.where((t) => t.petId == pet.id && daysUntil(t.nextDueDate, now) < 0).length,
              now: now,
            ),
          AppCard(
            onTap: () => context.push('/pets/new'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.add, color: AppColors.primary), SizedBox(width: 8), Text('Agregar mascota')],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends ConsumerWidget {
  const _PetCard({required this.pet, required this.overdue, required this.now});
  final Pet pet;
  final int overdue;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = [
      pet.breed ?? speciesLabel(pet.species),
      if (pet.birthDate != null) ageLabel(pet.birthDate!, now),
    ].join(' • ');
    return AppCard(
      onTap: () {
        ref.read(selectedPetIdProvider.notifier).select(pet.id);
        context.push('/pets/${pet.id}');
      },
      child: Row(children: [
        PetAvatar(pet: pet, size: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pet.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(detail, style: const TextStyle(color: AppColors.inkSoft)),
          ]),
        ),
        overdue > 0
            ? StatusChip('$overdue ${overdue == 1 ? 'atrasada' : 'atrasadas'}', StatusKind.overdue)
            : const StatusChip('Al día', StatusKind.ok),
      ]),
    );
  }
}
