import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

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
