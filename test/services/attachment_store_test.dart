import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/services/attachment_store.dart';

void main() {
  late Directory root;
  late File source;
  var n = 0;

  setUp(() {
    n = 0;
    root = Directory.systemTemp.createTempSync('huellitas_att_');
    source = File('${root.path}/origen.jpg')..writeAsStringSync('foto original grande');
  });
  tearDown(() => root.deleteSync(recursive: true));

  AttachmentStore store({CompressFn? compress}) => AttachmentStore(
        root: root,
        newId: () => 'id${n++}',
        compress: compress ?? (src, target) async => File(target).writeAsStringSync('comprimida'),
      );

  test('importImage guarda la versión comprimida bajo attachments/ y devuelve ruta relativa', () async {
    final rel = await store().importImage(source);
    expect(rel, 'attachments/id0.jpg');
    expect(File('${root.path}/$rel').readAsStringSync(), 'comprimida');
  });

  test('si la compresión falla lanza AttachmentException y no deja archivo', () async {
    final s = store(compress: (_, _) async => throw const AttachmentException('x'));
    await expectLater(s.importImage(source), throwsA(isA<AttachmentException>()));
    expect(File('${root.path}/attachments/id0.jpg').existsSync(), isFalse);
  });

  test('importPdf copia el archivo', () async {
    final pdf = File('${root.path}/r.pdf')..writeAsStringSync('%PDF');
    final rel = await store().importPdf(pdf);
    expect(rel, 'attachments/id0.pdf');
    expect(File('${root.path}/$rel').readAsStringSync(), '%PDF');
  });

  test('delete borra y no falla si no existe', () async {
    final s = store();
    final rel = await s.importImage(source);
    await s.delete(rel);
    expect(s.fileFor(rel).existsSync(), isFalse);
    await s.delete(rel); // no lanza
  });
}
