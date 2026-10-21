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

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    if (pets.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text('Agrega una mascota para ver su historial'),
          ),
        ),
      );
    }
    final names = {for (final p in pets) p.id: p.name};
    final all = <HealthEvent>[
      for (final p in pets)
        ...(ref.watch(eventsForPetProvider(p.id)).asData?.value ??
            const <HealthEvent>[]),
    ];
    final shown = filterEvents(all, type: _type, query: _query);
    final groups = groupByMonth(shown);
    final monthFmt = DateFormat("MMMM 'de' y", 'es_MX');

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Historial', style: AppText.h1),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  key: const Key('exportHistoryPdf'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.mintInk,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => exportHistoryPdf(context, ref),
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text(
                    'Exportar PDF',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('historySearch'),
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: AppColors.inkSoft),
                hintText: 'Buscar tratamiento, veterinario…',
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todo',
                    selected: _type == null,
                    onTap: () => setState(() => _type = null),
                  ),
                  for (final t in EventType.values)
                    _FilterChip(
                      label: t.pluralLabel,
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ),
                ],
              ),
            ),
            if (all.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Aún no hay registros')),
              )
            else if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 48,
                      color: AppColors.inkFaint,
                    ),
                    const SizedBox(height: 8),
                    const Text('Sin coincidencias'),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _reset,
                      child: const Text('Restablecer filtros'),
                    ),
                  ],
                ),
              )
            else
              for (final g in groups) ...[
                SectionHeader(
                  monthFmt.format(DateTime(g.year, g.month)),
                  caps: true,
                ),
                for (final e in g.events)
                  _TimelineItem(event: e, petName: names[e.petId] ?? ''),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected ? null : cardShadow(),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.onPrimary : AppColors.inkSoft,
          ),
        ),
      ),
    ),
  );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1.5;
    for (double y = 24; y < size.height; y += 6) {
      canvas.drawLine(Offset(20, y), Offset(20, y + 3), paint);
    }
    canvas.drawCircle(
      const Offset(20, 24),
      4,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.event, required this.petName});
  final HealthEvent event;
  final String petName;

  @override
  Widget build(BuildContext context) {
    final who = [
      petName,
      event.vetName ?? event.clinic,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: CustomPaint(painter: _DashedLinePainter()),
          ),
          Expanded(
            child: AppCard(
              onTap: () => context.push('/events/${event.id}'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TypeIcon(event.type, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: AppText.cardTitle.copyWith(fontSize: 17),
                              ),
                            ),
                            Text(
                              fmtShortDay(event.occurredAt),
                              style: AppText.bodyStrong,
                            ),
                          ],
                        ),
                        if (who.isNotEmpty)
                          Text(
                            who,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        if (event.notes != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              event.notes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                            ),
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
    );
  }
}
