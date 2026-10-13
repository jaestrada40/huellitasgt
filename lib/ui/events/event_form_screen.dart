import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/enums.dart';
import '../../domain/health_service.dart';
import '../../domain/models.dart';
import '../../services/attachment_store.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class _Freq {
  const _Freq(this.label, this.value, this.unit);
  final String label;
  final int? value;
  final IntervalUnit? unit;
}

const _freqs = [
  _Freq('Una vez', null, null),
  _Freq('Cada 1 mes', 1, IntervalUnit.months),
  _Freq('Cada 3 meses', 3, IntervalUnit.months),
  _Freq('Cada 6 meses', 6, IntervalUnit.months),
  _Freq('Cada 1 año', 1, IntervalUnit.years),
];

String _titleHint(EventType t) => switch (t) {
  EventType.vaccine => 'Ej. Vacuna antirrábica',
  EventType.deworming => 'Ej. Drontal Plus',
  EventType.fleaTick => 'Ej. NexGard Spectra',
  EventType.illness => 'Ej. Conjuntivitis leve',
  EventType.checkup => 'Ej. Chequeo general',
};

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.petId, this.initialType});
  final String? petId;
  final EventType? initialType;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _vet = TextEditingController();
  final _lot = TextEditingController();
  final _weight = TextEditingController();
  final List<NewAttachment> _attachments = [];
  late String? _petId = widget.petId ?? ref.read(currentPetProvider)?.id;
  late EventType _type = widget.initialType ?? EventType.vaccine;
  late DateTime _date = ref.read(clockProvider)();
  late final int _daysBefore = ref.read(prefsProvider).reminderDaysBefore;
  late final AttachmentStore _store = ref.read(attachmentStoreProvider);
  int _freqIndex = 0;
  bool _reminder = true;
  bool _saved = false;
  bool _saving = false;

  @override
  void dispose() {
    if (!_saved) {
      for (final a in _attachments) {
        unawaited(
          _store.delete(a.relativePath),
        ); // fotos que nunca se guardaron
      }
    }
    for (final c in [_title, _notes, _vet, _lot, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// El valor escrito, convertido a kg (así se guarda).
  double? get _parsedWeight {
    final v = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    return v == null ? null : ref.read(weightUnitProvider).toKg(v);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(
        () =>
            _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute),
      );
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source);
    if (x == null) return;
    try {
      final rel = await _store.importImage(File(x.path));
      if (mounted) {
        setState(
          () => _attachments.add(
            NewAttachment(
              relativePath: rel,
              kind: AttachmentKind.image,
              label: 'Comprobante',
            ),
          ),
        );
      }
    } on AttachmentException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_petId == null) {
      _snack('Primero agrega una mascota');
      return;
    }
    setState(() => _saving = true);
    final freq = _type.canRecur ? _freqs[_freqIndex] : _freqs[0];
    final title = _title.text.trim();
    try {
      await ref
          .read(healthServiceProvider)
          .logEvent(
            LogEventInput(
              petId: _petId!,
              type: _type,
              title: title,
              occurredAt: _date,
              product: _type.canRecur ? title : null,
              lot: _lot.text,
              vetName: _vet.text,
              notes: _notes.text,
              weightKg: _parsedWeight,
              intervalValue: freq.value,
              intervalUnit: freq.unit,
              reminderEnabled: _reminder,
              reminderDaysBefore: _daysBefore,
              attachments: _attachments,
            ),
          );
      _saved = true;
      await ref.read(reminderCoordinatorProvider).sync();
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('No se pudo guardar el registro');
      }
    }
  }

  void _pickPhotoSource() => showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final freq = _freqs[_freqIndex];
    final next = (_type.canRecur && freq.value != null)
        ? addInterval(_date, freq.value!, freq.unit!)
        : null;
    final dateText =
        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Nuevo evento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _save,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerRight,
                    ),
                    child: const Text('Listo', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              const SectionHeader('Tipo', caps: true),
              Row(
                children: [
                  for (final t in EventType.values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _type == t
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              TypeIcon(t, size: 44),
                              const SizedBox(height: 4),
                              Text(
                                t.pluralLabel,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: _type == t
                                      ? AppColors.ink
                                      : AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (pets.length > 1) ...[
                const SectionHeader('Mascota', caps: true),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final p in pets)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _petId = p.id),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                              decoration: BoxDecoration(
                                color: p.id == _petId
                                    ? AppColors.primary
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: p.id == _petId ? null : cardShadow(),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PetAvatar(pet: p, size: 36),
                                  const SizedBox(width: 8),
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: p.id == _petId
                                          ? AppColors.onPrimary
                                          : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('eventTitleField'),
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: _titleHint(_type)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Escribe el nombre'
                    : null,
              ),
              if (_type == EventType.vaccine)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final s in const [
                        'Antirrábica',
                        'Múltiple',
                        'Giardia',
                      ])
                        ActionChip(
                          label: Text('+ $s'),
                          onPressed: () => setState(() => _title.text = s),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vet,
                decoration: const InputDecoration(
                  hintText: 'Veterinario o clínica (opcional)',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.field),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Fecha aplicada',
                          style: TextStyle(fontSize: 16, color: AppColors.ink),
                        ),
                      ),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
              if (_type.canRecur) ...[
                const SectionHeader('Repetir', caps: true),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < _freqs.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _freqIndex = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _freqIndex == i
                                    ? AppColors.primary
                                    : AppColors.card,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: _freqIndex == i
                                    ? null
                                    : cardShadow(),
                              ),
                              child: Text(
                                _freqs[i].label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _freqIndex == i
                                      ? AppColors.onPrimary
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (next != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  color: AppColors.mint,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.mintInk,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRÓXIMA FECHA',
                            style: AppText.caps.copyWith(
                              color: AppColors.mintInk,
                            ),
                          ),
                          Text(
                            fmtDay(next),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.orangeText,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Avisarme $_daysBefore ${_daysBefore == 1 ? 'día' : 'días'} antes',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Switch(
                        value: _reminder,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) => setState(() => _reminder = v),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
              TextFormField(
                key: const Key('eventNotesField'),
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Notas: lote, dosis, reacciones…',
                ),
              ),
              const SectionHeader('Más detalles', caps: true),
              TextFormField(
                controller: _lot,
                decoration: const InputDecoration(hintText: 'Lote (opcional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventWeightField'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Peso del día (opcional)',
                  suffixIcon: WeightUnitToggle(),
                  suffixIconConstraints: BoxConstraints(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final w = _parsedWeight;
                  return (w == null || w <= 0 || w >= 300)
                      ? 'Escribe un peso válido'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in _attachments)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _store.fileFor(a.relativePath),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              unawaited(_store.delete(a.relativePath));
                              setState(() => _attachments.remove(a));
                            },
                            child: const CircleAvatar(
                              radius: 10,
                              child: Icon(Icons.close, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (_attachments.isNotEmpty) const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: _pickPhotoSource,
                child: CustomPaint(
                  painter: _DashedBorderPainter(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          color: AppColors.inkSoft,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Adjuntar foto del carnet o recibo',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.card),
        ),
      );
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
