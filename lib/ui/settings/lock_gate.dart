import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'lock_screen.dart';

/// Cubre la app con la pantalla de bloqueo al iniciar y cada vez que vuelve
/// del segundo plano, si el bloqueo está activado.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  late bool _locked = ref.read(prefsProvider).lockEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && ref.read(prefsProvider).lockEnabled) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        if (_locked)
          Positioned.fill(child: LockScreen(onUnlocked: () => setState(() => _locked = false))),
      ]);
}
