import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

class AttachmentException implements Exception {
  const AttachmentException(this.message);
  final String message;
  @override
  String toString() => message;
}

typedef CompressFn = Future<void> Function(File source, String targetPath);

class AttachmentStore {
  AttachmentStore({
    required this.root,
    required String Function() newId,
    CompressFn? compress,
  })  : _newId = newId,
        _compress = compress ?? _defaultCompress;

  /// Carpeta de documentos de la app; los adjuntos viven en `root/attachments`.
  final Directory root;
  final String Function() _newId;
  final CompressFn _compress;

  Future<String> importImage(File source) async {
    final rel = p.posix.join('attachments', '${_newId()}.jpg');
    final target = fileFor(rel);
    await target.parent.create(recursive: true);
    try {
      await _compress(source, target.path);
    } catch (e) {
      await delete(rel);
      if (e is AttachmentException) rethrow;
      throw const AttachmentException('No se pudo guardar la foto');
    }
    return rel;
  }

  Future<String> importPdf(File source) async {
    final rel = p.posix.join('attachments', '${_newId()}.pdf');
    final target = fileFor(rel);
    await target.parent.create(recursive: true);
    await source.copy(target.path);
    return rel;
  }

  File fileFor(String relativePath) => File(p.join(root.path, relativePath));

  Future<void> delete(String relativePath) async {
    final f = fileFor(relativePath);
    if (await f.exists()) await f.delete();
  }
}

Future<void> _defaultCompress(File source, String targetPath) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    source.absolute.path,
    targetPath,
    minWidth: 1600,
    minHeight: 1600,
    quality: 80,
    format: CompressFormat.jpeg,
  );
  if (result == null) throw const AttachmentException('No se pudo comprimir la imagen');
}
