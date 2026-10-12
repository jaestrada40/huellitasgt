import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/app_info.dart';
import '../../app/providers.dart';
import '../../services/backup_service.dart';
import '../format.dart';
import '../share_helpers.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggleLock(bool enable) async {
    final prefs = ref.read(prefsProvider);
    if (enable) {
      final ok = await context.push<bool>('/settings/pin');
      if (ok == true) await prefs.setLockEnabled(true);
    } else {
      await ref.read(pinStoreProvider).clear();
      await prefs.setLockEnabled(false);
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickTime() async {
    final prefs = ref.read(prefsProvider);
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute),
    );
    if (t == null) return;
    await prefs.setReminderTime(t.hour, t.minute);
    await ref.read(reminderCoordinatorProvider).sync();
    if (mounted) setState(() {});
  }

  Future<void> _pickDays() async {
    final prefs = ref.read(prefsProvider);
    final d = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Avisar con anticipación'),
        children: [
          for (final n in const [1, 2, 3, 5, 7, 14])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, n),
              child: Text('$n ${n == 1 ? 'día' : 'días'} antes'),
            ),
        ],
      ),
    );
    if (d == null) return;
    await prefs.setReminderDaysBefore(d);
    if (mounted) setState(() {});
  }

  Future<void> _export() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = await ref.read(backupServiceProvider).export(dir);
      await ref.read(shareFileProvider)(file.path);
      await ref.read(prefsProvider).setLastBackupAt(ref.read(clockProvider)());
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) _snack('No se pudo crear el respaldo');
    }
  }

  Future<void> _import() async {
    final file = await ref.read(pickBackupFileProvider)();
    if (file == null) return;
    final service = ref.read(backupServiceProvider);
    try {
      final prepared = await service.prepare(file);
      if (!mounted) {
        await service.discard(prepared);
        return;
      }
      final s = prepared.summary;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Importar respaldo'),
          content: Text(
            'Se encontraron ${s.pets} ${s.pets == 1 ? 'mascota' : 'mascotas'} y ${s.events} '
            '${s.events == 1 ? 'registro' : 'registros'}. Esto reemplazará todos los datos de este teléfono. ¿Continuar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reemplazar')),
          ],
        ),
      );
      if (ok != true) {
        await service.discard(prepared);
        return;
      }
      await service.commit(prepared);
      ref.read(selectedPetIdProvider.notifier).select(null);
      await ref.read(reminderCoordinatorProvider).sync();
      if (mounted) _snack('Respaldo importado');
    } on BackupException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _exportPdf() async {
    final pet = ref.read(currentPetProvider);
    if (pet == null) {
      _snack('Agrega una mascota primero');
      return;
    }
    final events = await ref.read(eventRepoProvider).watchForPet(pet.id).first;
    final bytes = await ref.read(pdfExporterProvider).history(
          pet: pet,
          events: events,
          generatedAt: ref.read(clockProvider)(),
        );
    await sharePdf(ref, bytes, 'historial-${pet.name}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final notifOk = ref.watch(notificationsAllowedProvider).asData?.value ?? true;
    final last = prefs.lastBackupAt;
    final time = TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute).format(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            stripe: AppColors.primary,
            child: const Row(children: [
              Icon(Icons.phonelink_lock, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(child: Text('Modo 100% sin nube: tus datos nunca salen de este teléfono.')),
            ]),
          ),
          const SectionHeader('Seguridad'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                key: const Key('lockSwitch'),
                title: const Text('Bloquear con Face ID / huella'),
                subtitle: const Text('Protege el historial de tus mascotas si alguien usa tu teléfono'),
                value: prefs.lockEnabled,
                onChanged: _toggleLock,
              ),
              ListTile(
                title: const Text('Cambiar PIN'),
                enabled: prefs.lockEnabled,
                trailing: const Icon(Icons.chevron_right),
                onTap: prefs.lockEnabled ? () => context.push<bool>('/settings/pin') : null,
              ),
            ]),
          ),
          const SectionHeader('Recordatorios'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                title: const Text('Hora del aviso'),
                trailing: Text(time),
                onTap: _pickTime,
              ),
              ListTile(
                title: const Text('Avisar con anticipación'),
                subtitle: const Text('Valor por defecto para nuevos recordatorios'),
                trailing: Text('${prefs.reminderDaysBefore} días antes'),
                onTap: _pickDays,
              ),
              ListTile(
                title: const Text('Notificaciones'),
                trailing: StatusChip(notifOk ? 'Activadas' : 'Desactivadas', notifOk ? StatusKind.ok : StatusKind.overdue),
                onTap: notifOk
                    ? null
                    : () async {
                        await ref.read(schedulerProvider).requestPermission();
                        ref.invalidate(notificationsAllowedProvider);
                        await ref.read(reminderCoordinatorProvider).sync();
                      },
              ),
            ]),
          ),
          const SectionHeader('Respaldo'),
          const AppCard(
            child: Text('Tus datos viven solo en este teléfono. Haz un respaldo para no perderlos si cambias de celular.'),
          ),
          FilledButton.icon(onPressed: _export, icon: const Icon(Icons.upload), label: const Text('Exportar respaldo')),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Text(
                last == null ? 'Aún no has hecho un respaldo' : 'Último respaldo: ${fmtDay(last)}',
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          ),
          OutlinedButton.icon(onPressed: _import, icon: const Icon(Icons.download), label: const Text('Importar respaldo')),
          const SectionHeader('Datos'),
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exportar historial en PDF'),
              onTap: _exportPdf,
            ),
          ),
          const SectionHeader('Acerca de'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              ListTile(
                title: const Text('Privacidad'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Privacidad'),
                    content: const Text(
                      'Huellitas guarda toda la información y las fotos solo en tu teléfono. '
                      'No tiene cuentas, no envía datos a ningún servidor y no usa publicidad ni analíticas de terceros.',
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar'))],
                  ),
                ),
              ),
              const ListTile(title: Text('Versión'), trailing: Text(kAppVersion)),
            ]),
          ),
        ],
      ),
    );
  }
}
