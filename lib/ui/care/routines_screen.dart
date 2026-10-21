import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/care_logic.dart';
import '../../domain/models.dart';
import '../theme.dart';
import '../widgets.dart';

const _suggestions = [('Paseo', 1), ('Baño', 15), ('Cortar uñas', 21), ('Cepillado', 3), ('Limpiar oídos', 14)];

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final routines = ref.watch(routinesForPetProvider(petId)).asData?.value ?? const <Routine>[];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newRoutine'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _RoutineSheet(petId: petId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva rutina'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            const BackHeader('Rutinas'),
            if (routines.isEmpty)
              const AppCard(
                child: Text('Anota cada cuánto debes pasear, bañar o cortar las uñas, y aquí verás cuándo toca.',
                    style: AppText.body),
              ),
            for (final r in routines)
              Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppColors.coral,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ref.read(careRepoProvider).deleteRoutine(r.id),
                child: _RoutineCard(routine: r, now: now),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine, required this.now});
  final Routine routine;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final since = daysSinceDone(routine, now);
    final due = routineIsDue(routine, now);
    final last = since == null
        ? 'Aún sin registro'
        : since == 0
            ? 'Hecho hoy'
            : 'Hace $since ${since == 1 ? 'día' : 'días'}';
    return AppCard(
      ring: due ? AppColors.coral : null,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(routine.name, style: AppText.cardTitle),
            Text('Cada ${routine.everyDays} ${routine.everyDays == 1 ? 'día' : 'días'}', style: AppText.body),
            const SizedBox(height: 6),
            StatusChip(last, due ? StatusKind.overdue : StatusKind.ok),
          ]),
        ),
        FilledButton(
          key: Key('routineDone_${routine.id}'),
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => ref.read(careRepoProvider).saveRoutine(Routine(
                id: routine.id,
                petId: routine.petId,
                name: routine.name,
                everyDays: routine.everyDays,
                lastDoneAt: now,
              )),
          child: const Text('Hecho hoy'),
        ),
      ]),
    );
  }
}

class _RoutineSheet extends ConsumerStatefulWidget {
  const _RoutineSheet({required this.petId});
  final String petId;

  @override
  ConsumerState<_RoutineSheet> createState() => _RoutineSheetState();
}

class _RoutineSheetState extends ConsumerState<_RoutineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _days = TextEditingController(text: '7');

  @override
  void dispose() {
    _name.dispose();
    _days.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(careRepoProvider).saveRoutine(Routine(
          id: ref.read(idGeneratorProvider)(),
          petId: widget.petId,
          name: _name.text.trim(),
          everyDays: int.parse(_days.text.trim()),
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Nueva rutina', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s.$1),
                  onPressed: () => setState(() {
                    _name.text = s.$1;
                    _days.text = '${s.$2}';
                  }),
                ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('routineName'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('routineDays'),
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cada cuántos días'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n < 1 || n > 365) ? '1 a 365' : null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
          ]),
        ),
      );
}
