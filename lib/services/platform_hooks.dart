import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

/// Único lugar con las APIs de local_auth y file_picker, que cambian entre
/// versiones. Ajustar aquí si el analizador marca diferencias.
Future<bool> authenticateWithBiometrics() async {
  final auth = LocalAuthentication();
  try {
    if (!await auth.canCheckBiometrics) return false;
    return await auth.authenticate(
      localizedReason: 'Desbloquea Huellitas',
      biometricOnly: true,
    );
  } catch (_) {
    return false;
  }
}

Future<File?> pickBackupZip() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['zip'],
  );
  final path = files.isEmpty ? null : files.first.path;
  return path == null ? null : File(path);
}

/// Cámara o galería. `null` si la persona cancela.
Future<File?> pickPhotoWithPicker(ImageSource source) async {
  final x = await ImagePicker().pickImage(source: source);
  return x == null ? null : File(x.path);
}

/// Abre un enlace (llamada `tel:`, mapa) con la app del sistema.
Future<bool> openUri(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class RecognizedText {
  const RecognizedText(this.text, this.confidence);
  final String text;

  /// 0..1, promedio de la seguridad del lector en cada línea.
  final double confidence;
}

/// Lee el texto de una foto con el lector del iPhone (Vision, sin internet).
/// `null` si no se pudo: en Android todavía no existe, o la foto no se abrió.
Future<RecognizedText?> recognizeTextInImage(File image) async {
  try {
    final r = await const MethodChannel('huellitas/ocr')
        .invokeMapMethod<String, Object?>('recognize', image.path);
    if (r == null) return null;
    return RecognizedText(r['text'] as String, (r['confidence'] as num).toDouble());
  } catch (_) {
    return null;
  }
}
