import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class EventDetail {
  const EventDetail(this.event, this.attachments, this.treatment, this.pet);
  final HealthEvent event;
  final List<Attachment> attachments;
  final Treatment? treatment;
  final Pet? pet;
}

final eventDetailProvider =
    FutureProvider.autoDispose.family<EventDetail?, String>((ref, id) async {
  final events = ref.read(eventRepoProvider);
  final event = await events.get(id);
  if (event == null) return null;
  final attachments = await events.attachmentsFor(id);
  final treatment = event.treatmentId == null
      ? null
      : await ref.read(treatmentRepoProvider).get(event.treatmentId!);
  final pet = await ref.read(petRepoProvider).get(event.petId);
  return EventDetail(event, attachments, treatment, pet);
});

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar este registro?'),
        content: const Text('También se borrarán sus fotos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    final paths = await ref.read(eventRepoProvider).delete(eventId);
    final store = ref.read(attachmentStoreProvider);
    for (final p in paths) {
      await store.delete(p);
    }
    if (context.mounted) context.pop();
  }

  void _openPhoto(BuildContext context, WidgetRef ref, Attachment a) {
    final file = ref.read(attachmentStoreProvider).fileFor(a.relativePath);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: InteractiveViewer(child: Image.file(file)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(eventDetailProvider(eventId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            key: const Key('deleteEventButton'),
            icon: const Icon(Icons.delete_outline, color: AppColors.coral),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('No se pudo cargar el registro')),
        data: (d) {
          if (d == null) return const Center(child: Text('Este registro ya no existe'));
          final e = d.event;
          Widget row(String label, String? value) => value == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.inkSoft))),
                    Expanded(child: Text(value)),
                  ]),
                );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(children: [
                  Icon(iconForType(e.type), color: AppColors.primary, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(e.type.label, style: const TextStyle(color: AppColors.inkSoft)),
                    ]),
                  ),
                ]),
              ),
              AppCard(
                child: Column(children: [
                  row('Mascota', d.pet?.name),
                  row('Fecha', fmtDateTime(e.occurredAt)),
                  row('Producto', e.product),
                  row('Lote', e.lot),
                  row('Veterinario', e.vetName),
                  row('Clínica', e.clinic),
                  row('Peso', e.weightKg == null ? null : '${e.weightKg} kg'),
                  row('Notas', e.notes),
                ]),
              ),
              if (d.treatment != null && d.treatment!.active)
                AppCard(
                  color: AppColors.mint,
                  child: Text('Próxima dosis: ${fmtDay(d.treatment!.nextDueDate)}'),
                ),
              if (d.attachments.isNotEmpty) ...[
                const SectionHeader('Comprobante y carnet'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final a in d.attachments)
                    GestureDetector(
                      onTap: () => _openPhoto(context, ref, a),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          ref.read(attachmentStoreProvider).fileFor(a.relativePath),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(width: 96, height: 96, child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }
}
