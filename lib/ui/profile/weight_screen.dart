import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../../domain/weight_logic.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key, required this.petId});
  final String petId;

  Future<void> _add(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddWeightSheet(petId: petId),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(weightsForPetProvider(petId)).asData?.value ??
        const <WeightEntry>[];
    final now = ref.watch(clockProvider)();
    final trend = weightTrend(entries, now);
    final delta = trend?.deltaVsMonthAgo;
    final unit = ref.watch(weightUnitProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar peso'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            const BackHeader('Peso'),
            AppCard(
              child: trend == null
                  ? const Text('Aún no hay registros de peso.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Peso actual',
                          style: TextStyle(color: AppColors.inkSoft),
                        ),
                        Text(
                          unit.format(trend.current),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (delta != null)
                          Text(
                            '${delta >= 0 ? '+' : ''}${unit.fromKg(delta).toStringAsFixed(1)} ${unit.symbol} vs mes pasado',
                            style: const TextStyle(color: AppColors.inkSoft),
                          ),
                      ],
                    ),
            ),
            if (entries.length >= 2)
              AppCard(
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CustomPaint(painter: _WeightChartPainter(entries)),
                ),
              ),
            const SectionHeader('Registros'),
            for (final e in entries)
              Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppColors.coral,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ref.read(weightRepoProvider).delete(e.id),
                child: AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.scale, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              unit.format(e.kg),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              [
                                fmtDay(e.date),
                                if (e.note != null) e.note!,
                              ].join(' · '),
                              style: const TextStyle(color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(List<WeightEntry> entries)
    : points = ([...entries]..sort((a, b) => a.date.compareTo(b.date)));
  final List<WeightEntry> points;

  @override
  void paint(Canvas canvas, Size size) {
    final minKg = points.map((p) => p.kg).reduce((a, b) => a < b ? a : b);
    final maxKg = points.map((p) => p.kg).reduce((a, b) => a > b ? a : b);
    final range = (maxKg - minKg) == 0 ? 1.0 : (maxKg - minKg);
    final t0 = points.first.date.millisecondsSinceEpoch;
    final span = (points.last.date.millisecondsSinceEpoch - t0).clamp(
      1,
      1 << 62,
    );

    Offset at(WeightEntry p) => Offset(
      (p.date.millisecondsSinceEpoch - t0) / span * (size.width - 16) + 8,
      size.height - 16 - (p.kg - minKg) / range * (size.height - 32),
    );

    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(at(p).dx, at(p).dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = AppColors.primary;
    for (final p in points) {
      canvas.drawCircle(at(p), 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) => old.points != points;
}

class _AddWeightSheet extends ConsumerStatefulWidget {
  const _AddWeightSheet({required this.petId});
  final String petId;

  @override
  ConsumerState<_AddWeightSheet> createState() => _AddWeightSheetState();
}

class _AddWeightSheetState extends ConsumerState<_AddWeightSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kg = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = ref.read(clockProvider)();

  @override
  void dispose() {
    _kg.dispose();
    _note.dispose();
    super.dispose();
  }

  /// El valor escrito, convertido a kg (así se guarda).
  double? get _parsed {
    final v = double.tryParse(_kg.text.trim().replaceAll(',', '.'));
    return v == null ? null : ref.read(weightUnitProvider).toKg(v);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: ref.read(clockProvider)(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    await ref
        .read(weightRepoProvider)
        .save(
          WeightEntry(
            id: ref.read(idGeneratorProvider)(),
            petId: widget.petId,
            date: dateOnly(_date),
            kg: _parsed!,
            note: note.isEmpty ? null : note,
          ),
        );
    if (mounted) {
      Navigator.of(context).pop(); // hoja modal, no es una ruta de go_router
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      16,
      16,
      16 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Agregar peso', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('weightField'),
            controller: _kg,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso',
              suffixIcon: WeightUnitToggle(),
              suffixIconConstraints: BoxConstraints(),
            ),
            validator: (v) {
              final w = _parsed;
              return (w == null || w <= 0 || w >= 300)
                  ? 'Escribe un peso válido'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha'),
            subtitle: Text(fmtDay(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          TextFormField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Nota (opcional)'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Guardar peso')),
        ],
      ),
    ),
  );
}
