import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/dates.dart';
import '../format.dart';
import '../pets/lost_pet_sheet.dart';
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
    ref.read(homeFilterProvider.notifier).select(null);
    await ref.read(reminderCoordinatorProvider).sync();
    if (context.mounted) context.go('/pets');
  }

  Future<void> _memorial(BuildContext context, WidgetRef ref, Pet pet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Honrar la memoria de ${pet.name}'),
        content: const Text(
            'Dejará de generar avisos y se apagan sus vacunas y medicinas. Su historial y sus fotos se conservan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(petRepoProvider).save(pet.withMemorial(dateOnly(ref.read(clockProvider)())));
    final treatments = ref.read(treatmentRepoProvider);
    for (final t in await treatments.active()) {
      if (t.petId == pet.id) await treatments.save(t.copyWith(active: false));
    }
    final meds = ref.read(medicationRepoProvider);
    for (final m in await meds.all()) {
      if (m.petId == pet.id && m.active) await meds.setActive(m.id, false);
    }
    await ref.read(reminderCoordinatorProvider).sync();
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

    DateTime? nextVaccine;
    for (final t in treatments.where((t) => t.type == EventType.vaccine)) {
      if (nextVaccine == null || t.nextDueDate.isBefore(nextVaccine)) nextVaccine = t.nextDueDate;
    }
    DateTime? lastOf(EventType type) =>
        events.where((e) => e.type == type).map((e) => e.occurredAt).fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

    final rows = <(IconData, String, String, VoidCallback?)>[
      if (pet.birthDate != null)
        (Icons.cake_outlined, 'Nacimiento', '${fmtDay(pet.birthDate!)} · ${ageLong(pet.birthDate!, now)}', null),
      (Icons.monitor_weight_outlined, 'Peso', lastWeight == null ? 'Registrar' : ref.watch(weightUnitProvider).format(lastWeight.kg),
          () => context.push('/pets/${pet.id}/weight')),
      if (pet.microchip != null)
        (Icons.memory_outlined, 'Microchip', pet.microchip!, () => Clipboard.setData(ClipboardData(text: pet.microchip!))),
      if (pet.sex != null) (Icons.pets_outlined, 'Sexo', pet.sex == PetSex.male ? 'Macho' : 'Hembra', null),
      if (pet.neutered) (Icons.check_circle_outline, 'Esterilizado', 'Sí', null),
      if (pet.allergiesNotes != null) (Icons.warning_amber_rounded, 'Alergias', pet.allergiesNotes!, null),
      if (pet.vetName != null) (Icons.medical_services_outlined, 'Veterinario', pet.vetName!, null),
      if (pet.vetClinic != null)
        (Icons.local_hospital_outlined, 'Clínica', pet.vetClinic!, () => ref.read(openUriProvider)(Uri.https(
            'www.google.com', '/maps/search/', {'api': '1', 'query': pet.vetClinic!}))),
      if (pet.vetPhone != null)
        (Icons.phone_outlined, 'Llamar', pet.vetPhone!, () => ref.read(openUriProvider)(Uri(scheme: 'tel', path: pet.vetPhone!))),
      if (pet.adoptionDate != null)
        (Icons.home_outlined, 'Llegó a casa', fmtDay(pet.adoptionDate!), null),
    ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(children: [
            PetPhoto(pet: pet, height: 300),
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 8,
              child: Row(children: [
                RoundIconButton(icon: Icons.chevron_left_rounded, tooltip: 'Atrás', onTap: () => context.pop()),
                const Spacer(),
                Material(
                  color: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => context.push('/pets/${pet.id}/edit'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                        SizedBox(width: 6),
                        Text('Editar', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            Container(
              margin: const EdgeInsets.only(top: 272),
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pet.name, style: AppText.h1),
              Text('${speciesLabel(pet.species)}${pet.breed == null ? '' : ' · ${pet.breed}'}',
                  style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
              if (pet.inMemoriam)
                AppCard(
                  color: AppColors.peach,
                  child: Row(children: [
                    const Icon(Icons.favorite_rounded, color: AppColors.orangeText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('En memoria desde ${fmtDay(pet.memorialDate!)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.orangeText)),
                    ),
                  ]),
                ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(children: [
                  _StatCard(type: EventType.vaccine, label: 'Próxima vacuna', date: nextVaccine),
                  const SizedBox(width: 12),
                  _StatCard(type: EventType.deworming, label: 'Últ. desparasitación', date: lastOf(EventType.deworming)),
                  const SizedBox(width: 12),
                  _StatCard(type: EventType.fleaTick, label: 'Últ. antipulgas', date: lastOf(EventType.fleaTick)),
                ]),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(),
                    InkWell(
                      onTap: rows[i].$4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(children: [
                          Icon(rows[i].$1, color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Text(rows[i].$2, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(rows[i].$3,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ),
              const SectionHeader('Registros recientes'),
              if (events.isEmpty) const AppCard(child: Text('Aún no hay registros.', style: AppText.body)),
              for (final e in events.take(4))
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap: () => context.push('/events/${e.id}'),
                  child: Row(children: [
                    TypeIcon(e.type, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.title, style: AppText.cardTitle),
                        Text(fmtDay(e.occurredAt), style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
                  ]),
                ),
              const SizedBox(height: 4),
              _LinkCard(Icons.badge_outlined, 'Carnet de vacunación', () => context.push('/pets/${pet.id}/carnet')),
              if (!pet.inMemoriam) ...[
                _LinkCard(Icons.medication_outlined, 'Medicinas y recetas', () => context.push('/pets/${pet.id}/meds')),
                _LinkCard(Icons.checklist_rounded, 'Rutinas (paseo, baño, uñas)', () => context.push('/pets/${pet.id}/routines')),
                _LinkCard(Icons.restaurant_outlined, 'Comida', () => context.push('/pets/${pet.id}/food')),
                _LinkCard(Icons.savings_outlined, 'Gastos', () => context.push('/pets/${pet.id}/expenses')),
                _LinkCard(Icons.campaign_outlined, 'Cartel de mascota perdida', () => showLostPetSheet(context, pet)),
              ],
              Center(
                child: Wrap(alignment: WrapAlignment.center, children: [
                  if (!pet.inMemoriam)
                    TextButton(
                      key: const Key('memorialButton'),
                      onPressed: () => _memorial(context, ref, pet),
                      child: const Text('En memoria'),
                    ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: AppColors.coral),
                    onPressed: () => _archive(context, ref, pet),
                    child: const Text('Archivar mascota'),
                  ),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.type, required this.label, required this.date});
  final EventType type;
  final String label;
  final DateTime? date;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 144,
        child: AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TypeIcon(type, size: 36),
            const SizedBox(height: 8),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            Text(date == null ? '—' : fmtDay(date!),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ]),
        ),
      );
}

class _LinkCard extends StatelessWidget {
  const _LinkCard(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppText.cardTitle)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
        ]),
      );
}
