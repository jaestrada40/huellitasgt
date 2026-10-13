import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../services/attachment_store.dart' show AttachmentException;
import '../../domain/treatment_status.dart';
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

  Future<void> _markDone(BuildContext context, WidgetRef ref, Treatment t) async {
    await ref.read(healthServiceProvider).markDone(t.id);
    await ref.read(reminderCoordinatorProvider).sync();
    if (context.mounted) context.pop();
  }

  void _openPhoto(BuildContext context, WidgetRef ref, Attachment a) {
    final file = ref.read(attachmentStoreProvider).fileFor(a.relativePath);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: InteractiveViewer(child: Image.file(file))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              key: const Key('deletePhotoButton'),
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              onPressed: () async {
                final ok = await _confirmDeletePhoto(dialogContext);
                if (ok != true) return;
                await _removePhoto(ref, a);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Eliminar foto'),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
          ]),
        ]),
      ),
    );
  }

  Future<bool?> _confirmDeletePhoto(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('¿Eliminar esta foto?'),
          content: const Text('Se borrará de tu teléfono. Esta acción no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
          ],
        ),
      );

  Future<void> _removePhoto(WidgetRef ref, Attachment a) async {
    final path = await ref.read(eventRepoProvider).removeAttachment(a.id);
    if (path != null) await ref.read(attachmentStoreProvider).delete(path);
    ref.invalidate(eventDetailProvider(eventId));
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref, ImageSource source) async {
    final picked = await ref.read(pickPhotoProvider)(source);
    if (picked == null) return;
    try {
      final rel = await ref.read(attachmentStoreProvider).importImage(picked);
      await ref.read(eventRepoProvider).addAttachment(Attachment(
            id: ref.read(idGeneratorProvider)(),
            eventId: eventId,
            relativePath: rel,
            kind: AttachmentKind.image,
            label: 'Comprobante',
          ));
      ref.invalidate(eventDetailProvider(eventId));
    } on AttachmentException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _chooseSource(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addPhoto(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addPhoto(context, ref, ImageSource.gallery);
              },
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(eventDetailProvider(eventId));
    final now = ref.watch(clockProvider)();
    return Scaffold(
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('No se pudo cargar el registro')),
          data: (d) {
            if (d == null) return const Center(child: Text('Este registro ya no existe'));
            final e = d.event;
            final t = (d.treatment != null && d.treatment!.active) ? d.treatment : null;
            final status = t == null ? null : dueStatus(t.nextDueDate, now);
            final (nextBg, nextFg) = switch (status) {
              DueStatus.overdue => (AppColors.coral.withValues(alpha: 0.15), AppColors.coral),
              DueStatus.upcoming => (AppColors.mint, AppColors.mintInk),
              _ => (AppColors.peach, AppColors.orangeText),
            };
            final rows = <(String, String)>[
              ('Fecha aplicada', fmtDay(e.occurredAt)),
              if (t != null) ('Frecuencia', frequencyLabel(t.intervalValue, t.intervalUnit)),
              if (e.product != null && e.product != e.title) ('Producto', e.product!),
              if (e.lot != null) ('Lote', e.lot!),
              if (e.vetName != null) ('Veterinario', e.vetName!),
              if (e.clinic != null) ('Clínica', e.clinic!),
              if (e.weightKg != null) ('Peso', ref.watch(weightUnitProvider).format(e.weightKg!)),
              if (t != null)
                ('Recordatorio', t.reminderEnabled ? '${t.reminderDaysBefore} ${t.reminderDaysBefore == 1 ? 'día' : 'días'} antes' : 'Desactivado'),
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28),
                    label: const Text('Atrás', style: TextStyle(fontSize: 16)),
                  ),
                ),
                Center(child: TypeIcon(e.type, size: 56)),
                const SizedBox(height: 12),
                Text(e.type.label.toUpperCase(), textAlign: TextAlign.center, style: AppText.caps),
                const SizedBox(height: 4),
                Text(e.title, textAlign: TextAlign.center, style: AppText.title),
                const SizedBox(height: 8),
                if (d.pet != null)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    PetAvatar(pet: d.pet!, size: 24),
                    const SizedBox(width: 8),
                    Text(d.pet!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ]),
                const SizedBox(height: 16),
                if (t != null)
                  AppCard(
                    color: nextBg,
                    child: Row(children: [
                      Icon(Icons.calendar_month_outlined, color: nextFg, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('PRÓXIMA FECHA', style: AppText.caps.copyWith(color: nextFg)),
                          Text(fmtDay(t.nextDueDate),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        ]),
                      ),
                      Text(dueLabel(t.nextDueDate, now), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: nextFg)),
                    ]),
                  ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(children: [
                          Text(rows[i].$1, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(rows[i].$2,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ),
                        ]),
                      ),
                    ],
                  ]),
                ),
                if (e.notes != null) ...[
                  const SectionHeader('Notas'),
                  AppCard(child: Text(e.notes!, style: const TextStyle(fontSize: 16, color: AppColors.ink))),
                ],
                const SectionHeader('Documentos'),
                if (d.attachments.isEmpty)
                  const AppCard(
                    child: Row(children: [
                      Icon(Icons.folder_open_outlined, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(child: Text('Sin fotos del carnet o recibo.', style: AppText.body)),
                    ]),
                  )
                else
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final a in d.attachments)
                      GestureDetector(
                        onTap: () => _openPhoto(context, ref, a),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('addDocumentPhoto'),
                  onPressed: () => _chooseSource(context, ref),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Agregar foto'),
                ),
                const SizedBox(height: 16),
                if (t != null)
                  FilledButton.icon(
                    onPressed: () => _markDone(context, ref, t),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Marcar como hecha'),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('deleteEventButton'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.coral.withValues(alpha: 0.15),
                    foregroundColor: AppColors.coral,
                  ),
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar registro'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
