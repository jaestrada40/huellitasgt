import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models.dart';
import '../share_helpers.dart';
import '../theme.dart';

/// Pide el teléfono (se recuerda) y comparte el cartel de mascota perdida en PDF.
Future<void> showLostPetSheet(BuildContext context, Pet pet) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LostPetSheet(pet: pet),
    );

class _LostPetSheet extends ConsumerStatefulWidget {
  const _LostPetSheet({required this.pet});
  final Pet pet;

  @override
  ConsumerState<_LostPetSheet> createState() => _LostPetSheetState();
}

class _LostPetSheetState extends ConsumerState<_LostPetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: ref.read(prefsProvider).ownerPhone ?? '');
  final _lastSeen = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _lastSeen.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final prefs = ref.read(prefsProvider);
    await prefs.setOwnerPhone(_phone.text);
    Uint8List? photo;
    final rel = widget.pet.photoPath;
    if (rel != null) {
      final f = ref.read(attachmentStoreProvider).fileFor(rel);
      if (await f.exists()) photo = await f.readAsBytes();
    }
    final bytes = await ref.read(pdfExporterProvider).lostPet(
          pet: widget.pet,
          contactPhone: _phone.text.trim(),
          photo: photo,
          lastSeen: _lastSeen.text,
          ownerName: prefs.userName,
        );
    await sharePdf(ref, bytes, 'se-busca-${widget.pet.name}.pdf');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Cartel de ${widget.pet.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text('Un PDF con su foto y tu teléfono, listo para imprimir o mandar por WhatsApp.', style: AppText.body),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('lostPhone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Tu teléfono de contacto'),
              validator: (v) => (v == null || v.trim().length < 6) ? 'Escribe un teléfono' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastSeen,
              decoration: const InputDecoration(labelText: 'Visto por última vez (opcional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('shareLostPet'),
              onPressed: _busy ? null : _share,
              child: const Text('Crear y compartir cartel'),
            ),
          ]),
        ),
      );
}
