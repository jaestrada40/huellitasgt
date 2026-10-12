import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/age.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/treatment_status.dart';
import '../format.dart';
import '../share_helpers.dart';
import '../theme.dart';
import '../widgets.dart';

class CarnetScreen extends ConsumerWidget {
  const CarnetScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = (ref.watch(petsProvider).asData?.value ?? const <Pet>[])
        .where((p) => p.id == petId)
        .firstOrNull;
    if (pet == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }
    final now = ref.watch(clockProvider)();
    final vaccines = (ref.watch(eventsForPetProvider(petId)).asData?.value ?? const <HealthEvent>[])
        .where((e) => e.type == EventType.vaccine)
        .toList();
    final treatments = {
      for (final t in ref.watch(activeTreatmentsProvider).asData?.value ?? const <Treatment>[]) t.id: t,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Carnet de vacunación')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            color: AppColors.mint,
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(child: Text('Resumen generado por ti a partir de tus registros')),
            ]),
          ),
          AppCard(
            child: Row(children: [
              PetAvatar(pet: pet, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pet.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    [
                      pet.breed ?? speciesLabel(pet.species),
                      if (pet.birthDate != null) ageLabel(pet.birthDate!, now),
                    ].join(' • '),
                    style: const TextStyle(color: AppColors.inkSoft),
                  ),
                  if (pet.microchip != null)
                    Text('Microchip ${pet.microchip}', style: const TextStyle(color: AppColors.inkSoft)),
                ]),
              ),
            ]),
          ),
          const SectionHeader('Historial de vacunas'),
          if (vaccines.isEmpty) const AppCard(child: Text('Aún no hay vacunas registradas')),
          for (final e in vaccines) _VaccineTile(event: e, treatment: treatments[e.treatmentId], now: now),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const Key('carnetPdf'),
            onPressed: () async {
              final bytes = await ref.read(pdfExporterProvider).carnet(
                    pet: pet,
                    vaccines: vaccines,
                    treatmentsById: treatments,
                    generatedAt: now,
                  );
              await sharePdf(ref, bytes, 'carnet-${pet.name}.pdf');
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Descargar PDF'),
          ),
        ],
      ),
    );
  }
}

class _VaccineTile extends StatelessWidget {
  const _VaccineTile({required this.event, required this.treatment, required this.now});
  final HealthEvent event;
  final Treatment? treatment;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = treatment;
    final vet = [event.vetName, event.clinic].whereType<String>().join(' | ');
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700))),
          if (t != null && t.active) StatusChip.forDue(dueStatus(t.nextDueDate, now), dueLabel(t.nextDueDate, now)),
        ]),
        Text('Aplicada: ${fmtDay(event.occurredAt)}', style: const TextStyle(color: AppColors.inkSoft)),
        if (event.lot != null) Text('Lote ${event.lot}', style: const TextStyle(color: AppColors.inkSoft)),
        if (vet.isNotEmpty) Text(vet, style: const TextStyle(color: AppColors.inkSoft)),
        if (t != null && t.active)
          Text('Próxima: ${fmtDay(t.nextDueDate)}', style: const TextStyle(color: AppColors.inkSoft)),
      ]),
    );
  }
}
