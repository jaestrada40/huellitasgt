import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/ui/pets/photo_framing_sheet.dart';

Future<File> _wideImage() async {
  // 400×100: mucho más ancha que el marco (390×300), así que sobra a los lados.
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 400, 100), Paint()..color = Colors.green);
  final image = await recorder.endRecording().toImage(400, 100);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  final f = File('${Directory.systemTemp.createTempSync('framing_').path}/wide.png');
  f.writeAsBytesSync(bytes.buffer.asUint8List());
  return f;
}

void main() {
  testWidgets('un dedo mueve la foto en el eje que sobra y el zoom abre el otro', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532); // iPhone, 390×844
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final file = (await tester.runAsync(_wideImage))!;
    PhotoFraming? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showModalBottomSheet<PhotoFraming>(
              context: context,
              isScrollControlled: true,
              enableDrag: false,
              builder: (_) => PhotoFramingSheet(file: file, initial: const PhotoFraming(Alignment.center, 1)),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    // La foto ya decodificada en caché, para no depender del reloj falso.
    await tester.runAsync(() => precacheImage(FileImage(file), tester.element(find.text('abrir'))));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Sin zoom, la foto horizontal solo se mueve de lado: arrastrar hacia
    // abajo no cambia nada, hacia la derecha cambia el enfoque en x.
    await tester.drag(find.byKey(const Key('framingArea')), const Offset(0, 80));
    await tester.pump();
    await tester.drag(find.byKey(const Key('framingArea')), const Offset(60, 0));
    await tester.pump();

    // Con zoom, ya sobra imagen arriba y abajo y un dedo la mueve en vertical.
    await tester.drag(find.byKey(const Key('zoomSlider')), const Offset(300, 0));
    await tester.pump();
    await tester.drag(find.byKey(const Key('framingArea')), const Offset(0, 40));
    await tester.pump();

    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.focus.x, lessThan(0)); // arrastrar a la derecha muestra más de la izquierda
    expect(result!.focus.y, lessThan(0)); // arrastrar hacia abajo muestra más de arriba
    expect(result!.zoom, greaterThan(1));
  });
}
