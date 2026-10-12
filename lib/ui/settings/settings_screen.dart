import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

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
  Future<void> _editName() async {
    final prefs = ref.read(prefsProvider);
    final saved = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: prefs.userName ?? ''),
    );
    if (saved == null) return;
    await prefs.setUserName(saved);
    if (mounted) setState(() {});
  }

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

  void _openSheet(Widget Function(BuildContext) builder) =>
      showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: builder).then((_) {
        if (mounted) setState(() {});
      });

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final name = prefs.userName;
    final last = prefs.lastBackupAt;
    final time = TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute).format(context);

    Widget row({
      required IconData icon,
      required Color bg,
      required Color fg,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap,
    }) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: fg, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 16, color: AppColors.ink)),
                  if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                ]),
              ),
              trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ]),
          ),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text('Ajustes', style: AppText.h1),
            const SizedBox(height: 16),
            AppCard(
              onTap: _editName,
              child: Row(children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: (name == null || name.isEmpty)
                      ? const Icon(Icons.person_outline, color: AppColors.onPrimary)
                      : Text(name.characters.first.toUpperCase(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onPrimary)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((name == null || name.isEmpty) ? 'Tu nombre' : name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text((name == null || name.isEmpty) ? 'Toca para agregarlo' : 'Tus datos viven solo en este teléfono',
                        style: AppText.body),
                  ]),
                ),
              ]),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                row(
                  icon: Icons.cloud_upload_outlined,
                  bg: AppColors.mint,
                  fg: AppColors.mintInk,
                  title: 'Respaldo',
                  subtitle: last == null ? 'Aún no has hecho un respaldo' : 'Último respaldo: ${fmtDay(last)}',
                  onTap: () => _openSheet((_) => const _BackupSheet()),
                ),
                const Divider(indent: 60),
                row(
                  icon: Icons.notifications_none_rounded,
                  bg: AppColors.peach,
                  fg: AppColors.orangeText,
                  title: 'Notificaciones',
                  subtitle: '$time · ${prefs.reminderDaysBefore} ${prefs.reminderDaysBefore == 1 ? 'día' : 'días'} antes',
                  onTap: () => _openSheet((_) => const _NotificationsSheet()),
                ),
                const Divider(indent: 60),
                row(
                  icon: Icons.lock_outline_rounded,
                  bg: AppColors.mint,
                  fg: AppColors.mintInk,
                  title: 'Bloquear con Face ID / huella',
                  trailing: Switch(
                    key: const Key('lockSwitch'),
                    value: prefs.lockEnabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    onChanged: _toggleLock,
                  ),
                  onTap: () => _toggleLock(!prefs.lockEnabled),
                ),
                if (prefs.lockEnabled) ...[
                  const Divider(indent: 60),
                  row(
                    icon: Icons.pin_outlined,
                    bg: AppColors.muted,
                    fg: AppColors.ink,
                    title: 'Cambiar PIN',
                    onTap: () => context.push<bool>('/settings/pin'),
                  ),
                ],
                const Divider(indent: 60),
                row(
                  icon: Icons.file_download_outlined,
                  bg: AppColors.greenBg,
                  fg: AppColors.greenInk,
                  title: 'Exportar historial',
                  onTap: () => exportHistoryPdf(context, ref),
                ),
                const Divider(indent: 60),
                row(
                  icon: Icons.shield_outlined,
                  bg: AppColors.muted,
                  fg: AppColors.ink,
                  title: 'Privacidad',
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
              ]),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: row(
                icon: Icons.favorite_border_rounded,
                bg: AppColors.coral.withValues(alpha: 0.15),
                fg: AppColors.coral,
                title: 'Ver bienvenida otra vez',
                onTap: () => context.push('/onboarding?replay=1'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Huellitas 1.0 · Hecho con cariño en México', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(text, style: AppText.h2),
      );
}

class _NotificationsSheet extends ConsumerStatefulWidget {
  const _NotificationsSheet();

  @override
  ConsumerState<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<_NotificationsSheet> {
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

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider);
    final notifOk = ref.watch(notificationsAllowedProvider).asData?.value ?? true;
    final time = TimeOfDay(hour: prefs.reminderHour, minute: prefs.reminderMinute).format(context);
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const _SheetTitle('Notificaciones'),
        ListTile(title: const Text('Hora del aviso'), trailing: Text(time), onTap: _pickTime),
        ListTile(
          title: const Text('Avisar con anticipación'),
          subtitle: const Text('Valor por defecto para nuevos recordatorios'),
          trailing: Text('${prefs.reminderDaysBefore} días antes'),
          onTap: _pickDays,
        ),
        ListTile(
          title: const Text('Permiso del teléfono'),
          trailing: StatusChip(notifOk ? 'Activadas' : 'Desactivadas', notifOk ? StatusKind.ok : StatusKind.overdue),
          onTap: notifOk
              ? null
              : () async {
                  await ref.read(schedulerProvider).requestPermission();
                  ref.invalidate(notificationsAllowedProvider);
                  await ref.read(reminderCoordinatorProvider).sync();
                },
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _BackupSheet extends ConsumerWidget {
  const _BackupSheet();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      final file = await ref.read(backupServiceProvider).export(dir);
      await ref.read(shareFileProvider)(file.path);
      await ref.read(prefsProvider).setLastBackupAt(ref.read(clockProvider)());
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('No se pudo crear el respaldo')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await ref.read(pickBackupFileProvider)();
    if (file == null) return;
    final service = ref.read(backupServiceProvider);
    try {
      final prepared = await service.prepare(file);
      if (!context.mounted) {
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
      ref.read(homeFilterProvider.notifier).select(null);
      await ref.read(reminderCoordinatorProvider).sync();
      messenger.showSnackBar(const SnackBar(content: Text('Respaldo importado')));
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _SheetTitle('Respaldo'),
            const Padding(
              padding: EdgeInsets.only(bottom: 16, left: 4),
              child: Text('Tus datos viven solo en este teléfono. Haz un respaldo para no perderlos si cambias de celular.',
                  style: AppText.body),
            ),
            FilledButton.icon(
              onPressed: () => _export(context, ref),
              icon: const Icon(Icons.upload),
              label: const Text('Exportar respaldo'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _import(context, ref),
              icon: const Icon(Icons.download),
              label: const Text('Importar respaldo'),
            ),
          ]),
        ),
      );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('¿Cómo te llamas?'),
        content: TextField(
          key: const Key('userNameField'),
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Tu nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Guardar'),
          ),
        ],
      );
}
