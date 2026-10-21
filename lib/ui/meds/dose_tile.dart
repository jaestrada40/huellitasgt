import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/medication_logic.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

String fmtHour(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Marca o desmarca una dosis como dada y reprograma los avisos
/// (una dosis dada ya no debe sonar).
Future<void> toggleDose(WidgetRef ref, Dose d) async {
  await ref
      .read(medicationRepoProvider)
      .setDose(d.medication.id, d.index, d.given ? null : ref.read(clockProvider)());
  await ref.read(reminderCoordinatorProvider).sync();
}

/// Marca la dosis como dada; la fila pasa a la siguiente dosis del medicamento,
/// así que se ofrece «Deshacer» por si fue un toque sin querer.
Future<void> giveDose(BuildContext context, WidgetRef ref, Dose d) async {
  final messenger = ScaffoldMessenger.of(context);
  await toggleDose(ref, d);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('${d.medication.name}: dosis marcada'),
      action: SnackBarAction(
        label: 'Deshacer',
        // Mismo medicamento y número de dosis, ya marcada: toggleDose la desmarca.
        onPressed: () => toggleDose(ref, Dose(d.medication, d.index, d.at, DateTime.now())),
      ),
    ));
}

class DoseTile extends ConsumerWidget {
  const DoseTile({super.key, required this.dose, this.petName});
  final Dose dose;
  final String? petName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = dose.medication;
    final late = !dose.given && dose.at.isBefore(ref.watch(clockProvider)());
    return AppCard(
      ring: late ? AppColors.coral : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          constraints: const BoxConstraints(minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: dose.given ? AppColors.greenBg : (late ? AppColors.coral.withValues(alpha: 0.12) : AppColors.peach),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              fmtHour(dose.at),
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: dose.given ? AppColors.greenInk : (late ? AppColors.coral : AppColors.orangeText),
              ),
            ),
            if (fmtDoseDay(dose.at, ref.watch(clockProvider)()) case final day?)
              Text(
                day,
                key: const Key('doseDay'),
                softWrap: false,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orangeText),
              ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: AppText.cardTitle),
            Text(
              [?petName, if (m.instructions != null) m.instructions!].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body,
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: dose.given ? 'Desmarcar dosis' : 'Marcar dosis como dada',
          child: InkResponse(
            key: Key('dose_${m.id}_${dose.index}'),
            onTap: () => dose.given ? toggleDose(ref, dose) : giveDose(context, ref, dose),
            radius: 28,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: dose.given ? AppColors.primary : AppColors.muted,
              foregroundColor: dose.given ? AppColors.onPrimary : AppColors.inkSoft,
              child: const Icon(Icons.check_rounded),
            ),
          ),
        ),
      ]),
    );
  }
}
