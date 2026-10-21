import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/health_service.dart';
import '../../domain/medication_logic.dart';
import '../../domain/models.dart';
import '../../domain/prescription_parser.dart';
import '../../services/attachment_store.dart';
import '../format.dart';
import '../pick_date_time.dart';
import '../theme.dart';
import '../widgets.dart';

/// Un medicamento en edición. [everyTouched]/[daysTouched] evitan que lo que
/// se lee del texto («cada 12 hrs durante 7 días») pise lo que la persona
/// escribió a mano.
class _Draft {
  final name = TextEditingController();
  final instructions = TextEditingController();
  final every = TextEditingController();
  final days = TextEditingController();
  DateTime? start; // null = la primera dosis común de toda la receta
  bool everyTouched = false;
  bool daysTouched = false;

  bool get isEmpty => name.text.trim().isEmpty && instructions.text.trim().isEmpty;

  void dispose() {
    for (final c in [name, instructions, every, days]) {
      c.dispose();
    }
  }
}

/// Captura una receta. La foto es opcional: sin foto los medicamentos se
/// escriben (o dictan con el micrófono del teclado) y todo funciona igual.
class PrescriptionScreen extends ConsumerStatefulWidget {
  const PrescriptionScreen({super.key, required this.petId});
  final String petId;

  @override
  ConsumerState<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends ConsumerState<PrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vet = TextEditingController();
  final _drafts = [_Draft()];
  final _removed = <_Draft>[]; // se liberan al salir: el árbol aún los usa en este fotograma
  late final AttachmentStore _store = ref.read(attachmentStoreProvider);
  late DateTime _date = ref.read(clockProvider)();
  late DateTime _start = _nextHour(ref.read(clockProvider)());
  String? _photo;
  bool _vetFilled = false;
  bool _reading = false;
  String? _notice;
  bool _saved = false;
  bool _saving = false;

  static DateTime _nextHour(DateTime n) => DateTime(n.year, n.month, n.day, n.hour + 1);

  @override
  void dispose() {
    if (!_saved && _photo != null) unawaited(_store.delete(_photo!)); // foto que nunca se guardó
    _vet.dispose();
    for (final d in [..._drafts, ..._removed]) {
      d.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _onInstructions(_Draft d) {
    final p = parseInstructions(d.instructions.text);
    if (p.everyHours != null && !d.everyTouched) d.every.text = '${p.everyHours}';
    if (p.days != null && !d.daysTouched) d.days.text = '${p.days}';
    setState(() {});
  }

  /// Lee la foto con el OCR y llena los medicamentos. Siempre se revisa antes de guardar.
  Future<void> _read(File image) async {
    setState(() {
      _reading = true;
      _notice = null;
    });
    final read = await ref.read(recognizeTextProvider)(image);
    if (!mounted) return;
    if (read == null) {
      setState(() {
        _reading = false;
        _notice = 'No pude leer la foto en este teléfono. Escribe los medicamentos o díctalos abajo.';
      });
      return;
    }
    final parsed = parsePrescription(read.text);
    // Letra a mano, foto borrosa o un formato que no entiendo: no se adivina.
    if (read.confidence < kMinOcrConfidence || parsed.meds.isEmpty || parsed.meds.any((m) => m.name.isEmpty)) {
      setState(() {
        _reading = false;
        _notice = 'No logré leer bien toda la receta (parece escrita a mano o no se ve claro). '
            'Para no equivocarme con las dosis, mejor escribe los medicamentos tú. '
            'La foto se guarda igual.';
      });
      return;
    }
    final petName = (ref.read(petsProvider).asData?.value ?? const <Pet>[])
        .where((p) => p.id == widget.petId)
        .firstOrNull
        ?.name;
    final mismatch = parsed.patient != null &&
        petName != null &&
        !parsed.patient!.toLowerCase().contains(petName.toLowerCase());
    setState(() {
      // Reemplaza los renglones vacíos; si ya había algo escrito, agrega debajo.
      _removed.addAll(_drafts.where((d) => d.isEmpty));
      _drafts.removeWhere((d) => d.isEmpty);
      for (final m in parsed.meds) {
        final d = _Draft()
          ..name.text = m.name
          ..instructions.text = m.instructions;
        final p = parseInstructions(m.instructions);
        if (p.everyHours != null) d.every.text = '${p.everyHours}';
        if (p.days != null) d.days.text = '${p.days}';
        _drafts.add(d);
      }
      if (parsed.date != null) _date = parsed.date!;
      _reading = false;
      final unclear = [for (final m in parsed.meds) if (parseInstructions(m.instructions).everyHours == null || parseInstructions(m.instructions).days == null) m.name];
      _notice = 'Leí ${parsed.meds.length} ${parsed.meds.length == 1 ? 'medicamento' : 'medicamentos'} de la foto. '
          'Revisa que nombres, dosis y horarios coincidan con tu receta antes de guardar.'
          '${unclear.isEmpty ? '' : '\n\nEn ${unclear.join(', ')} no pude leer cada cuántas horas o por cuántos días: complétalo.'}'
          '${mismatch ? '\n\nOjo: la receta dice paciente «${parsed.patient}», no $petName.' : ''}';
    });
  }

  Future<void> _addPhoto(ImageSource source) async {
    FocusManager.instance.primaryFocus?.unfocus(); // el teclado no debe reabrirse al volver de la cámara
    final picked = await ref.read(pickPhotoProvider)(source);
    if (picked == null) return;
    try {
      final rel = await _store.importImage(picked);
      if (_photo != null) unawaited(_store.delete(_photo!));
      if (mounted) setState(() => _photo = rel);
      if (mounted) await _read(picked);
    } on AttachmentException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  void _photoSheet() => showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ]),
        ),
      );

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  /// La hora común: se aplica a todos los medicamentos (borra las horas propias).
  Future<void> _pickStart() async {
    final v = await ref.read(pickDateTimeProvider)(context, _start);
    if (v == null) return;
    setState(() {
      _start = v;
      for (final d in _drafts) {
        d.start = null;
      }
    });
  }

  Future<void> _pickDraftStart(_Draft d) async {
    final v = await ref.read(pickDateTimeProvider)(context, d.start ?? _start);
    if (v != null) setState(() => d.start = v);
  }

  String? _n(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = ref.read(idGeneratorProvider);
      final lines = [
        for (final d in _drafts)
          '${d.name.text.trim()}${_n(d.instructions) == null ? '' : ': ${d.instructions.text.trim()}'}',
      ];
      final event = await ref.read(healthServiceProvider).logEvent(LogEventInput(
            petId: widget.petId,
            type: EventType.checkup,
            title: 'Receta',
            occurredAt: _date,
            vetName: _vet.text,
            notes: lines.join('\n'),
            attachments: [
              if (_photo != null)
                NewAttachment(relativePath: _photo!, kind: AttachmentKind.image, label: 'Receta'),
            ],
          ));
      _saved = true; // la foto ya quedó guardada con el registro
      await ref.read(medicationRepoProvider).saveAll([
        for (final d in _drafts)
          Medication(
            id: id(),
            petId: widget.petId,
            eventId: event.id,
            name: d.name.text.trim(),
            instructions: _n(d.instructions),
            everyHours: int.parse(d.every.text.trim()),
            days: int.parse(d.days.text.trim()),
            startAt: d.start ?? _start,
          ),
      ]);
      // Sin el permiso del teléfono los avisos se programan pero no suenan:
      // se pide aquí, que es cuando la persona espera que le avise.
      try {
        final scheduler = ref.read(schedulerProvider);
        if (!await scheduler.hasPermission()) await scheduler.requestPermission();
      } catch (_) {
        // La receta ya está guardada; Inicio y Ajustes siguen ofreciendo «Activar».
      }
      ref.invalidate(notificationsAllowedProvider);
      await ref.read(reminderCoordinatorProvider).sync();
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('No se pudo guardar la receta');
      }
    }
  }

  Widget _dateRow(String label, String value, VoidCallback onTap, IconData icon) => InkWell(
        borderRadius: BorderRadius.circular(AppRadius.field),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(AppRadius.field)),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: AppColors.ink))),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(width: 12),
            Icon(icon, size: 20, color: AppColors.ink),
          ]),
        ),
      );

  /// Resumen de cuándo toca cada dosis, para que se vea antes de guardar.
  String? _schedule(_Draft d) {
    final every = int.tryParse(d.every.text.trim());
    final days = int.tryParse(d.days.text.trim());
    if (every == null || days == null || !isValidSchedule(every, days)) return null;
    final total = (days * 24 / every).ceil();
    final start = d.start ?? _start;
    final last = start.add(Duration(hours: every * (total - 1)));
    String hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final String when;
    if (every < 24) {
      final times = [for (var k = 0; k * every < 24; k++) start.add(Duration(hours: every * k))]
        ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
      when = 'Horarios: ${times.map(hm).join(' · ')} (${times.length} al día)';
    } else if (every == 24) {
      when = 'Todos los días a las ${hm(start)}';
    } else {
      when = 'Cada $every h, desde ${fmtShortDay(start)} ${hm(start)}';
    }
    return '$when\n$total dosis, la última el ${fmtShortDay(last)} ${hm(last)}';
  }

  static String _hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _draftCard(int i) {
    final d = _drafts[i];
    String? numberError(String? v, int max) {
      final n = int.tryParse((v ?? '').trim());
      return (n == null || n < 1 || n > max) ? '1 a $max' : null;
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Medicamento ${i + 1}', style: AppText.cardTitle)),
          if (_drafts.length > 1)
            IconButton(
              key: Key('removeMed_$i'),
              tooltip: 'Quitar medicamento',
              onPressed: () => setState(() => _removed.add(_drafts.removeAt(i))),
              icon: const Icon(Icons.delete_outline, color: AppColors.coral),
            ),
        ]),
        TextFormField(
          key: Key('medName_$i'),
          controller: d.name,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Nombre (ej. Clorfenamina 8 mg)'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: Key('medInstructions_$i'),
          controller: d.instructions,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _onInstructions(d),
          decoration: const InputDecoration(
            hintText: 'Indicación (ej. 1 tableta cada 24 horas durante 5 días)',
          ),
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextFormField(
              key: Key('medEvery_$i'),
              controller: d.every,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => d.everyTouched = true),
              decoration: const InputDecoration(labelText: 'Cada (horas)'),
              validator: (v) => numberError(v, 168),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: Key('medDays_$i'),
              controller: d.days,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => d.daysTouched = true),
              decoration: const InputDecoration(labelText: 'Durante (días)'),
              validator: (v) => numberError(v, 365),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        TextButton.icon(
          key: Key('medStart_$i'),
          onPressed: () => _pickDraftStart(d),
          icon: const Icon(Icons.alarm_outlined, size: 18),
          label: Text('Primera dosis: ${fmtShortDay(d.start ?? _start)} ${_hm(d.start ?? _start)}'),
        ),
        if (_schedule(d) != null) ...[
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.alarm_on_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(_schedule(d)!, key: Key('medSchedule_$i'), style: AppText.bodyStrong)),
          ]),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = (ref.watch(petsProvider).asData?.value ?? const <Pet>[]).where((p) => p.id == widget.petId).firstOrNull;
    if (pet != null && !_vetFilled) {
      _vetFilled = true;
      _vet.text = pet.vetClinic ?? pet.vetName ?? '';
    }
    final photoFile = _photo == null ? null : _store.fileFor(_photo!);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              BackHeader('Receta${pet == null ? '' : ' de ${pet.name}'}'),
              AppCard(
                color: AppColors.mint,
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.mic_none_rounded, color: AppColors.mintInk),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Toma una foto de la receta y la leo yo: se llenan los medicamentos y sus horarios. '
                      'También puedes escribir o dictar con el micrófono del teclado: '
                      '«una tableta cada 24 horas durante 5 días».',
                      style: TextStyle(color: AppColors.mintInk),
                    ),
                  ),
                ]),
              ),
              const SectionHeader('Foto de la receta (opcional)', caps: true),
              if (photoFile != null)
                Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Image.file(photoFile, height: 220, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(
                      key: const Key('removePrescriptionPhoto'),
                      tooltip: 'Quitar foto',
                      onPressed: () {
                        unawaited(_store.delete(_photo!));
                        setState(() => _photo = null);
                      },
                      icon: const CircleAvatar(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        child: Icon(Icons.close, size: 18),
                      ),
                    ),
                  ),
                ])
              else
                OutlinedButton.icon(
                  key: const Key('addPrescriptionPhoto'),
                  onPressed: _photoSheet,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar o elegir foto'),
                ),
              if (_reading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Leyendo la receta…', style: AppText.bodyStrong),
                  ]),
                ),
              if (_photo != null && !_reading)
                TextButton.icon(
                  key: const Key('rereadPrescription'),
                  onPressed: () => _read(_store.fileFor(_photo!)),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Leer la receta de la foto'),
                ),
              if (_notice != null)
                AppCard(
                  key: const Key('prescriptionNotice'),
                  color: AppColors.peach,
                  margin: const EdgeInsets.only(top: 8),
                  child: Text(_notice!, style: const TextStyle(color: AppColors.orangeText, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 4),
              const Text('Sin foto también funciona: llena los medicamentos de abajo.', style: AppText.body),
              const SectionHeader('Datos', caps: true),
              TextFormField(
                controller: _vet,
                decoration: const InputDecoration(hintText: 'Veterinario o clínica (opcional)'),
              ),
              const SizedBox(height: 12),
              _dateRow('Fecha de la receta', fmtDay(_date), _pickDate, Icons.calendar_today_outlined),
              const SizedBox(height: 12),
              _dateRow('Primera dosis (todas)', '${fmtShortDay(_start)} ${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
                  _pickStart, Icons.alarm_outlined),
              const SectionHeader('Medicamentos', caps: true),
              for (var i = 0; i < _drafts.length; i++) _draftCard(i),
              OutlinedButton.icon(
                key: const Key('addMedication'),
                onPressed: () => setState(() => _drafts.add(_Draft())),
                icon: const Icon(Icons.add),
                label: const Text('Agregar otro medicamento'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('savePrescription'),
                onPressed: _saving ? null : _save,
                child: const Text('Guardar y activar avisos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
