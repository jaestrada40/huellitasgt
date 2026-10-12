import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/treatment_status.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.petId});
  final String petId;

  Future<void> _archive(BuildContext context, WidgetRef ref, Pet pet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Archivar a ${pet.name}?'),
        content: const Text('Dejará de aparecer y de generar avisos. Su historial se conserva en los respaldos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Archivar')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(petRepoProvider).archive(pet.id);
    ref.read(selectedPetIdProvider.notifier).select(null);
    await ref.read(reminderCoordinatorProvider).sync();
    if (context.mounted) context.go('/pets');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final pet = pets.where((p) => p.id == petId).firstOrNull;
    if (pet == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final now = ref.watch(clockProvider)();
    final treatments = (ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[])
        .where((t) => t.petId == petId)
        .toList();
    final events = ref.watch(eventsForPetProvider(petId)).asData?.value ?? const <HealthEvent>[];
    final weights = ref.watch(weightsForPetProvider(petId)).asData?.value ?? const <WeightEntry>[];
    final lastWeight = weights.firstOrNull;

    HealthEvent? lastFor(Treatment t) => events.where((e) => e.treatmentId == t.id).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/pets/${pet.id}/edit')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: PetAvatar(pet: pet, size: 96)),
          const SizedBox(height: 12),
          Center(child: Text(pet.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
          Center(
            child: Text(
              [
                pet.breed ?? speciesLabel(pet.species),
                if (pet.sex != null) (pet.sex == PetSex.male ? 'Macho' : 'Hembra'),
                if (pet.neutered) 'Esterilizado',
              ].join(' • '),
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Edad', style: TextStyle(color: AppColors.inkSoft)),
                  Text(pet.birthDate == null ? '-' : ageLabel(pet.birthDate!, now),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                onTap: () => context.push('/pets/${pet.id}/weight'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Peso', style: TextStyle(color: AppColors.inkSoft)),
                  Text(lastWeight == null ? 'Registrar' : '${lastWeight.kg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ]),
              ),
            ),
          ]),
          if (pet.microchip != null)
            AppCard(
              child: Row(children: [
                const Icon(Icons.tag, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(child: Text('Microchip ${pet.microchip}')),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: pet.microchip!)),
                ),
              ]),
            ),
          const SectionHeader('Estatus de protección'),
          if (treatments.isEmpty)
            const AppCard(child: Text('Aún no hay vacunas ni tratamientos con repetición.')),
          for (final t in treatments)
            AppCard(
              child: Row(children: [
                Icon(iconForType(t.type), color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      lastFor(t) == null ? t.type.label : 'Última: ${fmtDay(lastFor(t)!.occurredAt)}',
                      style: const TextStyle(color: AppColors.inkSoft),
                    ),
                  ]),
                ),
                StatusChip.forDue(dueStatus(t.nextDueDate, now), dueLabel(t.nextDueDate, now)),
              ]),
            ),
          if (pet.allergiesNotes != null) ...[
            const SectionHeader('Alergias y condiciones'),
            AppCard(child: Text(pet.allergiesNotes!)),
          ],
          if (pet.vetName != null || pet.vetClinic != null || pet.vetPhone != null) ...[
            const SectionHeader('Veterinario'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (pet.vetName != null) Text(pet.vetName!),
                if (pet.vetClinic != null) Text(pet.vetClinic!, style: const TextStyle(color: AppColors.inkSoft)),
                if (pet.vetPhone != null) Text(pet.vetPhone!, style: const TextStyle(color: AppColors.inkSoft)),
              ]),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              ref.read(selectedPetIdProvider.notifier).select(pet.id);
              context.go('/history');
            },
            icon: const Icon(Icons.history_edu),
            label: const Text('Ver historial completo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/pets/${pet.id}/carnet'),
            icon: const Icon(Icons.badge),
            label: const Text('Carnet de vacunación'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.coral),
            onPressed: () => _archive(context, ref, pet),
            child: const Text('Archivar mascota'),
          ),
        ],
      ),
    );
  }
}
