import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PickDateTime = Future<DateTime?> Function(BuildContext context, DateTime initial);

/// Fecha y hora en una sola hoja con ruedas (como el reloj del iPhone), 24 h.
/// `null` si se cancela.
Future<DateTime?> pickDateTimeWithWheel(BuildContext context, DateTime initial) {
  var value = initial;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          TextButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Cancelar')),
          const Spacer(),
          TextButton(
            key: const Key('pickerDone'),
            onPressed: () => Navigator.pop(sheetContext, value),
            child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        SizedBox(
          height: 216,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            use24hFormat: true,
            initialDateTime: initial,
            minimumYear: 2000,
            maximumYear: 2100,
            onDateTimeChanged: (d) => value = d,
          ),
        ),
      ]),
    ),
  );
}

// Se sobreescribe en las pruebas: girar ruedas con el dedo no es práctico ahí.
final pickDateTimeProvider = Provider<PickDateTime>((ref) => pickDateTimeWithWheel);
