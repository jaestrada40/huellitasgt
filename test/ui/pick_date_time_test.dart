import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/ui/pick_date_time.dart';

void main() {
  Future<void> open(WidgetTester tester, void Function(DateTime?) onResult) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onResult(await pickDateTimeWithWheel(context, DateTime(2026, 10, 20, 19, 30))),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('la rueda muestra fecha y hora juntas y «Listo» devuelve lo elegido', (tester) async {
    DateTime? result;
    await open(tester, (v) => result = v);
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    await tester.tap(find.byKey(const Key('pickerDone')));
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 10, 20, 19, 30));
  });

  testWidgets('girar la rueda de la hora cambia la hora elegida', (tester) async {
    DateTime? result;
    await open(tester, (v) => result = v);
    // Rueda de horas: la primera de las que muestran números de 2 dígitos (19 → más abajo).
    await tester.drag(find.text('19'), const Offset(0, -80)); // hacia arriba = horas siguientes
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pickerDone')));
    await tester.pumpAndSettle();
    expect(result!.hour, isNot(19));
    expect(result!.minute, 30);
  });

  testWidgets('Cancelar devuelve null', (tester) async {
    DateTime? result = DateTime(2000);
    await open(tester, (v) => result = v);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
