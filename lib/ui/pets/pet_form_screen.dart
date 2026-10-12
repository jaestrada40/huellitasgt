import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
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
    for (final c in [_name, _breed, _microchip, _allergies, _vetName, _vetClinic, _vetPhone]) {
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
      if (_photo != null && _photo != _originalPhoto) await _store.delete(_photo!);
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
    if (d != null) setState(() => _birth = DateTime.utc(d.year, d.month, d.day));
  }

  String? _n(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final photoFile = _photo == null ? null : _store.fileFor(_photo!);
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Nueva mascota' : 'Editar mascota'),
        leading: widget.first ? null : TextButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
        leadingWidth: 90,
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _pickPhoto(ImageSource.gallery),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: (photoFile != null && photoFile.existsSync()) ? FileImage(photoFile) : null,
                    child: (photoFile != null && photoFile.existsSync())
                        ? null
                        : const Icon(Icons.add_a_photo, color: AppColors.primary, size: 32),
                  ),
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(onPressed: () => _pickPhoto(ImageSource.camera), child: const Text('Tomar foto')),
                TextButton(onPressed: () => _pickPhoto(ImageSource.gallery), child: const Text('Elegir de la galería')),
              ]),
              const SectionHeader('Datos'),
              TextFormField(
                key: const Key('petNameField'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre de la mascota *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<PetSpecies>(
                segments: [
                  for (final s in PetSpecies.values) ButtonSegment(value: s, label: Text(speciesLabel(s).replaceAll(' mascota', ''))),
                ],
                selected: {_species},
                onSelectionChanged: (s) => setState(() => _species = s.first),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _breed, decoration: const InputDecoration(labelText: 'Raza o cruza')),
              const SizedBox(height: 12),
              SegmentedButton<PetSex>(
                emptySelectionAllowed: true,
                segments: const [
                  ButtonSegment(value: PetSex.male, label: Text('Macho')),
                  ButtonSegment(value: PetSex.female, label: Text('Hembra')),
                ],
                selected: _sex == null ? <PetSex>{} : {_sex!},
                onSelectionChanged: (s) => setState(() => _sex = s.isEmpty ? null : s.first),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Esterilizado'),
                subtitle: const Text('Castración o ligadura quirúrgica'),
                value: _neutered,
                onChanged: (v) => setState(() => _neutered = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de nacimiento o adopción'),
                subtitle: Text(_birth == null ? 'Sin definir' : fmtDay(_birth!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirth,
              ),
              TextFormField(controller: _microchip, decoration: const InputDecoration(labelText: 'Número de microchip (opcional)')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergies,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Alergias o condiciones'),
              ),
              const SectionHeader('Veterinario'),
              TextFormField(controller: _vetName, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 12),
              TextFormField(controller: _vetClinic, decoration: const InputDecoration(labelText: 'Clínica')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vetPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Guardar mascota')),
            ],
          ),
        ),
      ),
    );
  }
}
