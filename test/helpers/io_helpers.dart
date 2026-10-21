import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un PNG verde de 20×20 válido, para que Image.file lo decodifique.
Future<File> writePng(Directory dir, String name) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 20, 20), Paint()..color = Colors.green);
  final image = await recorder.endRecording().toImage(20, 20);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  final f = File('${dir.path}/$name');
  f.parent.createSync(recursive: true);
  return f..writeAsBytesSync(bytes.buffer.asUint8List());
}

/// Los archivos y la BD usan E/S real, que el reloj falso no hace avanzar:
/// alterna tiempo real y cuadros hasta que se encadenan todos los pasos.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
}

/// Como [settleIo] pero espera (hasta ~4 s reales) a que aparezca [finder]:
/// con la máquina cargada la E/S real tarda más que unos cuantos cuadros fijos.
Future<void> settleUntil(WidgetTester tester, Finder finder, {int tries = 100}) async {
  for (var i = 0; i < tries && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
