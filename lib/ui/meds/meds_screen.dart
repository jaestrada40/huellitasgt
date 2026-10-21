import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/medication_logic.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../pick_date_time.dart';
import '../theme.dart';
import '../widgets.dart';
import 'dose_tile.dart';

class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final pet = (ref.watch(petsProvider).asData?.value ?? const <Pet>[]).where((p) => p.id == petId).firstOrNull;
    final meds = (ref.watch(medicationsProvider).asData?.value ?? const <Medication>[])
        .where((m) => m.petId == petId)
        .toList();
    final logs = ref.watch(doseLogsProvider).asData?.value ?? const <DoseLog>[];
    final pending = pendingDoses(meds, logs, now);
    final running = [for (final m in meds) if (m.active && !isFinished(m, logs, now)) m];
    final past = [for (final m in meds) if (!m.active || isFinished(m, logs, now)) m];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newPrescription'),
        onPressed: () => context.push('/pets/$petId/prescription'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva receta'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            BackHeader('Medicinas${pet == null ? '' : ' de ${pet.name}'}'),
            const SectionHeader('Por dar'),
            if (pending.isEmpty) const AppCard(child: Text('No hay medicinas pendientes.', style: AppText.body)),
            for (final d in pending) DoseTile(dose: d),
            const SectionHeader('En curso'),
            if (running.isEmpty)
              const AppCard(
                child: Text('Sin tratamientos en curso. Toca «Nueva receta» para agregar uno, con o sin foto de la receta.',
                    style: AppText.body),
              ),
            for (final m in running) _MedCard(med: m, logs: logs, now: now),
            if (past.isNotEmpty) ...[
              const SectionHeader('Terminados'),
              for (final m in past) _MedCard(med: m, logs: logs, now: now, done: true),
            ],
          ],
        ),
      ),
    );
  }
}

class _MedCard extends ConsumerWidget {
  const _MedCard({required this.med, required this.logs, required this.now, this.done = false});
  final Medication med;
  final Iterable<DoseLog> logs;
  final DateTime now;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doses = dosesOf(med, logs);
    final given = doses.where((d) => d.given).length;
    final next = doses.where((d) => !d.given && d.at.isAfter(now)).firstOrNull;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(med.name, style: AppText.cardTitle),
        if (med.instructions != null) Text(med.instructions!, style: AppText.body),
        const SizedBox(height: 4),
        Text(
          'Cada ${med.everyHours} h durante ${med.days} ${med.days == 1 ? 'día' : 'días'} · desde ${fmtDateTime(med.startAt)}',
          style: AppText.body,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: given / doses.length,
            minHeight: 8,
            backgroundColor: AppColors.muted,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$given de ${doses.length} dosis dadas'
          '${!done && next != null ? ' · próxima: ${fmtShortDay(next.at)} ${fmtHour(next.at)}' : ''}',
          style: AppText.bodyStrong,
        ),
        Wrap(spacing: 4, runSpacing: 0, crossAxisAlignment: WrapCrossAlignment.center, children: [
          if (med.eventId != null)
            TextButton.icon(
              onPressed: () => context.push('/events/${med.eventId}'),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: const Text('Ver receta'),
            ),
          if (!done)
            TextButton(
              key: Key('editMed_${med.id}'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _EditScheduleSheet(med: med, givenDoses: given),
              ),
              child: const Text('Editar horario'),
            ),
          if (!done)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              onPressed: () async {
                await ref.read(medicationRepoProvider).setActive(med.id, false);
                await ref.read(reminderCoordinatorProvider).sync();
              },
              child: const Text('Terminar'),
            ),
        ]),
      ]),
    );
  }
}

/// Cambia cada cuántas horas, por cuántos días y a qué hora empieza.
/// Las dosis ya marcadas se conservan por número de dosis; si ya hay dadas se avisa.
class _EditScheduleSheet extends ConsumerStatefulWidget {
  const _EditScheduleSheet({required this.med, required this.givenDoses});
  final Medication med;
  final int givenDoses;

  @override
  ConsumerState<_EditScheduleSheet> createState() => _EditScheduleSheetState();
}

class _EditScheduleSheetState extends ConsumerState<_EditScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _every = TextEditingController(text: '${widget.med.everyHours}');
  late final _days = TextEditingController(text: '${widget.med.days}');
  late DateTime _start = widget.med.startAt;

  @override
  void dispose() {
    _every.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final v = await ref.read(pickDateTimeProvider)(context, _start);
    if (v != null) setState(() => _start = v);
  }

  String? _number(String? v, int max) {
    final n = int.tryParse((v ?? '').trim());
    return (n == null || n < 1 || n > max) ? '1 a $max' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(medicationRepoProvider).saveAll([
      widget.med.copyWith(
        everyHours: int.parse(_every.text.trim()),
        days: int.parse(_days.text.trim()),
        startAt: _start,
      ),
    ]);
    await ref.read(reminderCoordinatorProvider).sync();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Horario de ${widget.med.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: TextFormField(
                  key: const Key('editEvery'),
                  controller: _every,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cada (horas)'),
                  validator: (v) => _number(v, 168),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('editDays'),
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Durante (días)'),
                  validator: (v) => _number(v, 365),
                ),
              ),
            ]),
            ListTile(
              key: const Key('editStart'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Primera dosis'),
              subtitle: Text(fmtDateTime(_start)),
              trailing: const Icon(Icons.alarm_outlined),
              onTap: _pickStart,
            ),
            if (widget.givenDoses > 0)
              Text(
                'Las dosis que ya marcaste se conservan; las demás siguen el nuevo horario.',
                style: AppText.body,
              ),
            const SizedBox(height: 16),
            FilledButton(key: const Key('saveSchedule'), onPressed: _save, child: const Text('Guardar horario')),
          ]),
        ),
      );
}
