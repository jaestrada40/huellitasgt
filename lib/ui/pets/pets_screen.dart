import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/home_logic.dart';
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
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(children: [
              const Expanded(child: Text('Mascotas', style: AppText.h1)),
              Material(
                color: AppColors.mint,
                shape: const CircleBorder(),
                child: IconButton(
                  key: const Key('addPetButton'),
                  tooltip: 'Agregar mascota',
                  onPressed: () => context.push('/pets/new'),
                  icon: const Icon(Icons.add_rounded, color: AppColors.mintInk),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            for (final pet in pets)
              _PetCard(
                pet: pet,
                pending: homeSections(treatments.where((t) => t.petId == pet.id), now).pending.length,
                now: now,
              ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends ConsumerWidget {
  const _PetCard({required this.pet, required this.pending, required this.now});
  final Pet pet;
  final int pending;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = [
      speciesLabel(pet.species),
      ?pet.breed,
      if (pet.birthDate != null) ageLong(pet.birthDate!, now),
    ].join(' · ');
    return AppCard(
      onTap: () {
        ref.read(selectedPetIdProvider.notifier).select(pet.id);
        context.push('/pets/${pet.id}');
      },
      child: Row(children: [
        PetAvatar(pet: pet, size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(detail, style: AppText.body),
            const SizedBox(height: 8),
            pet.inMemoriam
                ? const StatusChip('En memoria', StatusKind.ok)
                : pending > 0
                ? StatusChip('$pending ${pending == 1 ? 'pendiente' : 'pendientes'}', StatusKind.soon)
                : const StatusChip('Al día', StatusKind.ok),
          ]),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
      ]),
    );
  }
}
