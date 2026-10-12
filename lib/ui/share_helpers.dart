import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app/providers.dart';

/// Guarda [bytes] en la carpeta temporal y abre la hoja de compartir del sistema.
Future<void> sharePdf(WidgetRef ref, Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes);
  await ref.read(shareFileProvider)(file.path);
}
