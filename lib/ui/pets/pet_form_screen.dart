import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../services/attachment_store.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId, this.first = false});
  final String? petId;
  final bool first;

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _microchip = TextEditingController();
  final _allergies = TextEditingController();
  final _vetName = TextEditingController();
  final _vetClinic = TextEditingController();
  final _vetPhone = TextEditingController();
  final _userName = TextEditingController();
  final _weight = TextEditingController();
  PetSpecies _species = PetSpecies.dog;
  PetSex? _sex;
  bool _neutered = false;
  DateTime? _birth;
  String? _photo;
  String? _originalPhoto;
  Pet? _existing;
  late bool _loading = widget.petId != null;
  bool _saved = false;
  late final AttachmentStore _store = ref.read(attachmentStoreProvider);

  @override
  void initState() {
    super.initState();
    _userName.text = ref.read(prefsProvider).userName ?? '';
    if (widget.petId != null) _load();
  }

  Future<void> _load() async {
    final p = await ref.read(petRepoProvider).get(widget.petId!);
    if (p != null) {
      _existing = p;
      _name.text = p.name;
      _breed.text = p.breed ?? '';
      _microchip.text = p.microchip ?? '';
      _allergies.text = p.allergiesNotes ?? '';
      _vetName.text = p.vetName ?? '';
      _vetClinic.text = p.vetClinic ?? '';
      _vetPhone.text = p.vetPhone ?? '';
      _species = p.species;
      _sex = p.sex;
      _neutered = p.neutered;
      _birth = p.birthDate;
      _photo = _originalPhoto = p.photoPath;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    if (!_saved && _photo != null && _photo != _originalPhoto) {
      unawaited(_store.delete(_photo!)); // foto nueva que nunca se guardó
    }
    for (final c in [
      _name,
      _breed,
      _microchip,
      _allergies,
      _vetName,
      _vetClinic,
      _vetPhone,
      _userName,
      _weight,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickPhoto(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source);
    if (x == null) return;
    try {
      final rel = await _store.importImage(File(x.path));
      if (_photo != null && _photo != _originalPhoto) {
        await _store.delete(_photo!);
      }
      if (mounted) setState(() => _photo = rel);
    } on AttachmentException catch (e) {
      if (mounted) _snack(e.message);
    }
  }

  Future<void> _pickBirth() async {
    final now = ref.read(clockProvider)();
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? now,
      firstDate: DateTime(1990),
      lastDate: now,
    );
    if (d != null) {
      setState(() => _birth = DateTime.utc(d.year, d.month, d.day));
    }
  }

  String? _n(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  double? get _parsedWeight =>
      double.tryParse(_weight.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isNew = _existing == null;
    final pet = Pet(
      id: _existing?.id ?? ref.read(idGeneratorProvider)(),
      name: _name.text.trim(),
      species: _species,
      breed: _n(_breed),
      sex: _sex,
      neutered: _neutered,
      birthDate: _birth,
      microchip: _n(_microchip),
      photoPath: _photo,
      allergiesNotes: _n(_allergies),
      vetName: _n(_vetName),
      vetClinic: _n(_vetClinic),
      vetPhone: _n(_vetPhone),
      createdAt: _existing?.createdAt ?? ref.read(clockProvider)(),
      archived: _existing?.archived ?? false,
    );
    await ref.read(petRepoProvider).save(pet);
    if (widget.first) await ref.read(prefsProvider).setUserName(_userName.text);
    final kg = _parsedWeight;
    if (kg != null) {
      await ref
          .read(weightRepoProvider)
          .save(
            WeightEntry(
              id: ref.read(idGeneratorProvider)(),
              petId: pet.id,
              date: dateOnly(ref.read(clockProvider)()),
              kg: kg,
            ),
          );
    }
    if (_originalPhoto != null && _originalPhoto != _photo) {
      await _store.delete(_originalPhoto!);
    }
    _saved = true;
    if (isNew) ref.read(selectedPetIdProvider.notifier).select(pet.id);
    await ref.read(reminderCoordinatorProvider).sync();
    if (!mounted) return;
    if (widget.first) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  Widget _speciesPill(PetSpecies s) {
    final selected = _species == s;
    final emoji = switch (s) {
      PetSpecies.dog => '🐶',
      PetSpecies.cat => '🐱',
      PetSpecies.other => '🐾',
    };
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _species = s),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? null : cardShadow(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji),
              const SizedBox(width: 8),
              Text(
                speciesLabel(s).replaceAll(' mascota', ''),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: selected ? AppColors.onPrimary : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final photoFile = _photo == null ? null : _store.fileFor(_photo!);
    final hasPhoto = photoFile != null && photoFile.existsSync();
    final birthText = _birth == null
        ? 'Sin definir'
        : '${_birth!.day.toString().padLeft(2, '0')}/${_birth!.month.toString().padLeft(2, '0')}/${_birth!.year}';
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    if (widget.first)
                      const SizedBox(width: 48)
                    else
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancelar'),
                      ),
                    Expanded(
                      child: Text(
                        widget.first
                            ? 'Agrega tu primera mascota'
                            : (_existing == null
                                  ? 'Nueva mascota'
                                  : 'Editar mascota'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => _pickPhoto(ImageSource.gallery),
                  child: Container(
                    width: 112,
                    height: 112,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: hasPhoto
                        ? Image.file(photoFile, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_camera_outlined,
                                color: AppColors.mintInk,
                                size: 30,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Foto',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mintInk,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    child: const Text('Tomar foto'),
                  ),
                  TextButton(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    child: const Text('Elegir de la galería'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.first) ...[
                TextFormField(
                  key: const Key('userNameField'),
                  controller: _userName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: '¿Cómo te llamas?',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  for (final sp in PetSpecies.values) ...[
                    _speciesPill(sp),
                    if (sp != PetSpecies.values.last) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('petNameField'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Nombre'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Escribe el nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breed,
                decoration: const InputDecoration(hintText: 'Raza'),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.field),
                onTap: _pickBirth,
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
                          'Fecha de nacimiento',
                          style: TextStyle(fontSize: 16, color: AppColors.ink),
                        ),
                      ),
                      Text(
                        birthText,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('petWeightField'),
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(hintText: 'Peso (kg)'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final w = _parsedWeight;
                        return (w == null || w <= 0 || w >= 300)
                            ? 'Escribe un peso válido'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _microchip,
                      decoration: const InputDecoration(hintText: 'Microchip'),
                    ),
                  ),
                ],
              ),
              const SectionHeader('Más datos (opcional)', caps: true),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<PetSex>(
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: PetSex.male, label: Text('Macho')),
                        ButtonSegment(
                          value: PetSex.female,
                          label: Text('Hembra'),
                        ),
                      ],
                      selected: _sex == null ? <PetSex>{} : {_sex!},
                      onSelectionChanged: (s) =>
                          setState(() => _sex = s.isEmpty ? null : s.first),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Esterilizado'),
                value: _neutered,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() => _neutered = v),
              ),
              TextFormField(
                controller: _allergies,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Alergias o condiciones',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vetName,
                decoration: const InputDecoration(hintText: 'Veterinario'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vetClinic,
                decoration: const InputDecoration(hintText: 'Clínica'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vetPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Teléfono del veterinario',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
