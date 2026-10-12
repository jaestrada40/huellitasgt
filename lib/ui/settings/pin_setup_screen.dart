import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../theme.dart';
import 'pin_pad.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  String? _error;

  Future<void> _onPin(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
    } else if (_first == pin) {
      await ref.read(pinStoreProvider).setPin(pin);
      if (mounted) context.pop(true);
    } else {
      setState(() {
        _first = null;
        _error = 'Los PIN no coinciden';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('PIN de respaldo')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_first == null ? 'Elige un PIN de 4 dígitos' : 'Confirma tu PIN',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              height: 28,
              child: _error == null ? null : Text(_error!, style: const TextStyle(color: AppColors.coral)),
            ),
            PinPad(onComplete: _onPin),
          ]),
        ),
      );
}
