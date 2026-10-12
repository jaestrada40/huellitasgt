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
  _Freq('Ninguna', null, null),
  _Freq('1 mes', 1, IntervalUnit.months),
  _Freq('3 meses', 3, IntervalUnit.months),
  _Freq('6 meses', 6, IntervalUnit.months),
  _Freq('1 año', 1, IntervalUnit.years),
];

String _titleLabel(EventType t) => switch (t) {
      EventType.vaccine => 'Nombre de la vacuna *',
      EventType.deworming || EventType.fleaTick => 'Producto *',
      EventType.illness => 'Síntoma o diagnóstico *',
      EventType.checkup => 'Motivo de la consulta *',
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
  final _clinic = TextEditingController();
  final _lot = TextEditingController();
  final _weight = TextEditingController();
  final List<NewAttachment> _attachments = [];
  late String? _petId = widget.petId ?? ref.read(currentPetProvider)?.id;
  late EventType _type = widget.initialType ?? EventType.vaccine;
  late DateTime _date = ref.read(clockProvider)();
  late int _daysBefore = ref.read(prefsProvider).reminderDaysBefore;
  late final AttachmentStore _store = ref.read(attachmentStoreProvider);
  int _freqIndex = 0;
  bool _reminder = true;
  bool _saved = false;
  bool _saving = false;

  @override
  void dispose() {
    if (!_saved) {
      for (final a in _attachments) {
        unawaited(_store.delete(a.relativePath)); // fotos que nunca se guardaron
      }
    }
    for (final c in [_title, _notes, _vet, _clinic, _lot, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  double? get _parsedWeight => double.tryParse(_weight.text.trim().replaceAll(',', '.'));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source);
    if (x == null) return;
    try {
      final rel = await _store.importImage(File(x.path));
      if (mounted) {
        setState(() => _attachments.add(
              NewAttachment(relativePath: rel, kind: AttachmentKind.image, label: 'Comprobante'),
            ));
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
      await ref.read(healthServiceProvider).logEvent(LogEventInput(
            petId: _petId!,
            type: _type,
            title: title,
            occurredAt: _date,
            product: _type.canRecur ? title : null,
            lot: _lot.text,
            vetName: _vet.text,
            clinic: _clinic.text,
            notes: _notes.text,
            weightKg: _parsedWeight,
            intervalValue: freq.value,
            intervalUnit: freq.unit,
            reminderEnabled: _reminder,
            reminderDaysBefore: _daysBefore,
            attachments: _attachments,
          ));
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

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(petsProvider).asData?.value ?? const <Pet>[];
    final freq = _freqs[_freqIndex];
    final next = (_type.canRecur && freq.value != null)
        ? addInterval(_date, freq.value!, freq.unit!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar evento'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pets.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: _petId,
                  decoration: const InputDecoration(labelText: 'Mascota'),
                  items: [for (final p in pets) DropdownMenuItem(value: p.id, child: Text(p.name))],
                  onChanged: (v) => setState(() => _petId = v),
                ),
              const SectionHeader('Tipo de evento'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final t in EventType.values)
                  ChoiceChip(
                    avatar: Icon(iconForType(t), size: 18),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('eventTitleField'),
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: _titleLabel(_type)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
              ),
              if (_type == EventType.vaccine)
                Wrap(spacing: 8, children: [
                  for (final s in const ['Antirrábica', 'Múltiple', 'Giardia'])
                    ActionChip(label: Text('+ $s'), onPressed: () => setState(() => _title.text = s)),
                ]),
              const SectionHeader('Fecha'),
              ListTile(
                tileColor: AppColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('Fecha de aplicación o evento'),
                subtitle: Text(fmtDay(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              if (_type.canRecur) ...[
                const SectionHeader('Frecuencia de repetición'),
                Wrap(spacing: 8, children: [
                  for (var i = 0; i < _freqs.length; i++)
                    ChoiceChip(
                      label: Text(_freqs[i].label),
                      selected: _freqIndex == i,
                      onSelected: (_) => setState(() => _freqIndex = i),
                    ),
                ]),
              ],
              if (next != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  stripe: AppColors.primary,
                  child: Text('Próxima dosis sugerida: ${fmtDay(next)}'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorio previo'),
                  subtitle: Text('Avisarme $_daysBefore ${_daysBefore == 1 ? 'día' : 'días'} antes por notificación'),
                  value: _reminder,
                  onChanged: (v) => setState(() => _reminder = v),
                ),
                if (_reminder)
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _daysBefore > 1 ? () => setState(() => _daysBefore--) : null,
                    ),
                    Text('$_daysBefore'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _daysBefore < 14 ? () => setState(() => _daysBefore++) : null,
                    ),
                  ]),
              ],
              const SectionHeader('Detalles'),
              TextFormField(
                key: const Key('eventNotesField'),
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas o indicaciones del veterinario'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _vet, decoration: const InputDecoration(labelText: 'Veterinario')),
              const SizedBox(height: 12),
              TextFormField(controller: _clinic, decoration: const InputDecoration(labelText: 'Clínica')),
              const SizedBox(height: 12),
              TextFormField(controller: _lot, decoration: const InputDecoration(labelText: 'Lote (opcional)')),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('eventWeightField'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso del día en kg (opcional)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final w = _parsedWeight;
                  return (w == null || w <= 0 || w >= 300) ? 'Escribe un peso válido' : null;
                },
              ),
              const SectionHeader('Comprobante y carnet'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in _attachments)
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_store.fileFor(a.relativePath), width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          unawaited(_store.delete(a.relativePath));
                          setState(() => _attachments.remove(a));
                        },
                        child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                      ),
                    ),
                  ]),
              ]),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_circle),
                label: const Text('Guardar en historial'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
