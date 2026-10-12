import 'package:flutter/material.dart';

import '../theme.dart';

/// Teclado numérico de 4 dígitos. Llama a [onComplete] con el PIN y se limpia.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onComplete});
  final void Function(String pin) onComplete;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _tap(String d) {
    if (_pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) {
      final done = _pin;
      setState(() => _pin = '');
      widget.onComplete(done);
    }
  }

  void _back() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Widget _key(String label, VoidCallback onTap, {Key? key}) => SizedBox(
        width: 72,
        height: 56,
        child: TextButton(
          key: key,
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 24, color: AppColors.ink)),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.all(8),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? AppColors.primary : AppColors.divider,
              ),
            ),
        ]),
        const SizedBox(height: 16),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final d in row) _key(d, () => _tap(d), key: Key('pin_$d')),
          ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(width: 72),
          _key('0', () => _tap('0'), key: const Key('pin_0')),
          SizedBox(
            width: 72,
            height: 56,
            child: IconButton(onPressed: _back, icon: const Icon(Icons.backspace_outlined)),
          ),
        ]),
      ]);
}
