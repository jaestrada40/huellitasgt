import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/care_logic.dart';
import '../../domain/dates.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final foods = ref.watch(foodsForPetProvider(petId)).asData?.value ?? const <FoodStock>[];
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newFood'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _FoodSheet(petId: petId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar comida'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            const BackHeader('Comida'),
            if (foods.isEmpty)
              const AppCard(
                child: Text('Anota la bolsa que tienes y cuánto come por día: Huellitas calcula cuándo se acaba y te avisa 5 días antes.',
                    style: AppText.body),
              ),
            for (final f in foods)
              Dismissible(
                key: ValueKey(f.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppColors.coral,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await ref.read(careRepoProvider).deleteFood(f.id);
                  await ref.read(reminderCoordinatorProvider).sync();
                },
                child: _FoodCard(food: f, now: now),
              ),
          ],
        ),
      ),
    );
  }
}

class _FoodCard extends ConsumerWidget {
  const _FoodCard({required this.food, required this.now});
  final FoodStock food;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = foodDaysLeft(food, now);
    final total = (food.bagKg * 1000 / food.gramsPerDay).floor();
    return AppCard(
      ring: left <= foodReminderDaysBefore ? AppColors.coral : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(food.brand, style: AppText.cardTitle),
        Text('${ref.watch(weightUnitProvider).format(food.bagKg)} · ${food.gramsPerDay} g al día', style: AppText.body),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total <= 0 ? 0 : (left / total).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.muted,
            color: left <= foodReminderDaysBefore ? AppColors.coral : AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          left <= 0 ? 'Se acabó (${fmtDay(foodRunsOutOn(food))})' : 'Quedan $left ${left == 1 ? 'día' : 'días'} · se acaba el ${fmtDay(foodRunsOutOn(food))}',
          style: AppText.bodyStrong,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: Key('restock_${food.id}'),
            onPressed: () async {
              await ref.read(careRepoProvider).saveFood(FoodStock(
                    id: food.id,
                    petId: food.petId,
                    brand: food.brand,
                    bagKg: food.bagKg,
                    gramsPerDay: food.gramsPerDay,
                    openedOn: dateOnly(now),
                  ));
              await ref.read(reminderCoordinatorProvider).sync();
            },
            child: const Text('Abrí una bolsa nueva'),
          ),
        ),
      ]),
    );
  }
}

class _FoodSheet extends ConsumerStatefulWidget {
  const _FoodSheet({required this.petId});
  final String petId;

  @override
  ConsumerState<_FoodSheet> createState() => _FoodSheetState();
}

class _FoodSheetState extends ConsumerState<_FoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _kg = TextEditingController();
  final _grams = TextEditingController();

  @override
  void dispose() {
    for (final c in [_brand, _kg, _grams]) {
      c.dispose();
    }
    super.dispose();
  }

  /// El valor escrito, convertido a kg (así se guarda).
  double? get _kgValue {
    final v = double.tryParse(_kg.text.trim().replaceAll(',', '.'));
    return v == null ? null : ref.read(weightUnitProvider).toKg(v);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(careRepoProvider).saveFood(FoodStock(
          id: ref.read(idGeneratorProvider)(),
          petId: widget.petId,
          brand: _brand.text.trim(),
          bagKg: _kgValue!,
          gramsPerDay: int.parse(_grams.text.trim()),
          openedOn: dateOnly(ref.read(clockProvider)()),
        ));
    await ref.read(reminderCoordinatorProvider).sync();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Agregar comida', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('foodBrand'),
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Marca'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe la marca' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('foodKg'),
              controller: _kg,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Tamaño de la bolsa',
                suffixIcon: WeightUnitToggle(),
                suffixIconConstraints: BoxConstraints(),
              ),
              validator: (v) => (_kgValue == null || _kgValue! <= 0 || _kgValue! > 100) ? 'Escribe un peso válido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('foodGrams'),
              controller: _grams,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gramos por día'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                return (n == null || n < 1 || n > 5000) ? 'Escribe los gramos' : null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
          ]),
        ),
      );
}
