import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../theme.dart';
import 'pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  Future<void> _tryBiometrics() async {
    if (await ref.read(biometricAuthProvider)()) widget.onUnlocked();
  }

  Future<void> _verify(String pin) async {
    final ok = await ref.read(pinStoreProvider).verify(pin);
    if (ok) {
      widget.onUnlocked();
    } else if (mounted) {
      setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('Huellitas', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text('Ingresa tu PIN', style: TextStyle(color: AppColors.inkSoft)),
              SizedBox(
                height: 28,
                child: _error ? const Text('PIN incorrecto', style: TextStyle(color: AppColors.coral)) : null,
              ),
              PinPad(onComplete: _verify),
              TextButton(onPressed: _tryBiometrics, child: const Text('Usar Face ID o huella')),
            ]),
          ),
        ),
      );
}
