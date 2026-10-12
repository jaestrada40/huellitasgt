import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/history_logic.dart';
import '../../domain/models.dart';
import '../format.dart';
import '../share_helpers.dart';
import '../theme.dart';
import '../widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  EventType? _type;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
        _type = null;
        _query = '';
        _search.clear();
      });

  Future<void> _export(Pet pet, List<HealthEvent> events) async {
    final bytes = await ref.read(pdfExporterProvider).history(
          pet: pet,
          events: events,
          generatedAt: ref.read(clockProvider)(),
        );
    await sharePdf(ref, bytes, 'historial-${pet.name}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final pet = ref.watch(currentPetProvider);
    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        body: const Center(child: Text('Agrega una mascota para ver su historial')),
      );
    }
    final all = ref.watch(eventsForPetProvider(pet.id)).asData?.value ?? const <HealthEvent>[];
    final shown = filterEvents(all, type: _type, query: _query);
    final groups = groupByMonth(shown);
    final monthFmt = DateFormat('MMMM y', 'es_MX');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            key: const Key('exportHistoryPdf'),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _export(pet, all),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pets.length > 1)
            Wrap(spacing: 8, children: [
              for (final p in pets)
                ChoiceChip(
                  label: Text(p.name),
                  selected: p.id == pet.id,
                  onSelected: (_) => ref.read(selectedPetIdProvider.notifier).select(p.id),
                ),
            ]),
          const SizedBox(height: 8),
          TextField(
            key: const Key('historySearch'),
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar en el historial'),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: const Text('Todo'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
              ),
              for (final t in EventType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.pluralLabel),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
            ]),
          ),
          if (all.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Aún no hay registros')))
          else if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.search_off, size: 48, color: AppColors.inkFaint),
                const SizedBox(height: 8),
                const Text('Sin coincidencias'),
                const SizedBox(height: 12),
                FilledButton.tonal(onPressed: _reset, child: const Text('Restablecer filtros')),
              ]),
            )
          else
            for (final g in groups) ...[
              SectionHeader(toBeginningOfSentenceCase(monthFmt.format(DateTime(g.year, g.month))) ?? ''),
              for (final e in g.events) _EventTile(event: e),
            ],
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final HealthEvent event;

  @override
  Widget build(BuildContext context) {
    final vet = [event.vetName, event.clinic].whereType<String>().join(' | ');
    return AppCard(
      onTap: () => context.push('/events/${event.id}'),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(iconForType(event.type), color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(fmtDateTime(event.occurredAt), style: const TextStyle(color: AppColors.inkSoft)),
            if (vet.isNotEmpty) Text(vet, style: const TextStyle(color: AppColors.inkSoft)),
            if (event.notes != null) Text(event.notes!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}
