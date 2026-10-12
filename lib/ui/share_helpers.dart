import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app/providers.dart';
import '../domain/models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Guarda [bytes] en la carpeta temporal y abre la hoja de compartir del sistema.
Future<void> sharePdf(WidgetRef ref, Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes);
  await ref.read(shareFileProvider)(file.path);
}

/// Exporta el historial en PDF; si hay varias mascotas pregunta de quién.
Future<void> exportHistoryPdf(BuildContext context, WidgetRef ref) async {
  final pets = ref.read(petsProvider).asData?.value ?? const <Pet>[];
  if (pets.isEmpty) return;
  final pet = pets.length == 1
      ? pets.first
      : await showModalBottomSheet<Pet>(
          context: context,
          builder: (sheetContext) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('¿De quién es el historial?', style: AppText.h2),
              ),
              for (final p in pets)
                ListTile(
                  leading: PetAvatar(pet: p, size: 40),
                  title: Text(p.name),
                  onTap: () => Navigator.pop(sheetContext, p),
                ),
            ]),
          ),
        );
  if (pet == null) return;
  final events = await ref.read(eventRepoProvider).watchForPet(pet.id).first;
  final bytes = await ref.read(pdfExporterProvider).history(
        pet: pet,
        events: events,
        generatedAt: ref.read(clockProvider)(),
      );
  await sharePdf(ref, bytes, 'historial-${pet.name}.pdf');
}
