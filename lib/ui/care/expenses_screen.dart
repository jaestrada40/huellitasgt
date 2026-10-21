import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/care_logic.dart';
import '../../domain/dates.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key, required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final expenses = ref.watch(expensesForPetProvider(petId)).asData?.value ?? const <Expense>[];
    final byCategory = totalsByCategory(expenses.where((e) => e.date.year == now.year && e.date.month == now.month));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('newExpense'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _ExpenseSheet(petId: petId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar gasto'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          children: [
            const BackHeader('Gastos'),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Este mes', style: AppText.caps.copyWith(color: AppColors.inkSoft)),
                Text(money(monthTotal(expenses, now.year, now.month)),
                    key: const Key('monthTotal'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink)),
                for (final e in byCategory.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Expanded(child: Text(e.key.label, style: AppText.body)),
                      Text(money(e.value), style: AppText.bodyStrong),
                    ]),
                  ),
              ]),
            ),
            const SectionHeader('Registros'),
            if (expenses.isEmpty) const AppCard(child: Text('Aún no hay gastos.', style: AppText.body)),
            for (final e in expenses)
              Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppColors.coral,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => ref.read(careRepoProvider).deleteExpense(e.id),
                child: AppCard(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.category.label, style: AppText.cardTitle),
                        Text([fmtDay(e.date), if (e.note != null) e.note!].join(' · '), style: AppText.body),
                      ]),
                    ),
                    Text(money(e.amount), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSheet extends ConsumerStatefulWidget {
  const _ExpenseSheet({required this.petId});
  final String petId;

  @override
  ConsumerState<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<_ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = ref.read(clockProvider)();
  ExpenseCategory _category = ExpenseCategory.vet;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_amount.text.trim().replaceAll(',', '.'));

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
    await ref.read(careRepoProvider).saveExpense(Expense(
          id: ref.read(idGeneratorProvider)(),
          petId: widget.petId,
          date: dateOnly(_date),
          amount: _value!,
          category: _category,
          note: note.isEmpty ? null : note,
        ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Agregar gasto', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('expenseAmount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto', prefixText: 'Q '),
              validator: (v) => (_value == null || _value! <= 0 || _value! > 1000000) ? 'Escribe un monto válido' : null,
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final c in ExpenseCategory.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ]),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha'),
              subtitle: Text(fmtDay(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            TextFormField(controller: _note, decoration: const InputDecoration(labelText: 'Nota (opcional)')),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Guardar')),
          ]),
        ),
      );
}
