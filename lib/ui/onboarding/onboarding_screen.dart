import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.replay = false});

  /// Si es `true` (desde Ajustes) al terminar solo se cierra.
  final bool replay;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide(this.icon, this.bg, this.fg, this.title, this.body);
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String body;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _slides = [
    _Slide(Icons.notifications_none_rounded, AppColors.peach, AppColors.orangeText, 'Nunca olvides una vacuna',
        'Te avisamos antes de cada vacuna, desparasitación o pastilla antipulgas.'),
    _Slide(Icons.folder_special_outlined, AppColors.mint, AppColors.mintInk, 'Todo su historial en un lugar',
        'Consultas, enfermedades y fotos del carnet, siempre a la mano.'),
    _Slide(Icons.ios_share_rounded, AppColors.greenBg, AppColors.greenInk, 'Respalda y lleva su carnet',
        'Tus datos viven en tu teléfono. Exporta un respaldo y un carnet en PDF cuando lo necesites.'),
  ];

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() => widget.replay ? context.pop() : context.go('/pets/new?first=1');

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(children: [
                const Icon(Icons.pets, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text('Huellitas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.4)),
                const Spacer(),
                GestureDetector(
                  onTap: _start,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Saltar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(48)),
                          child: Icon(s.icon, size: 64, color: s.fg),
                        ),
                        const SizedBox(height: 32),
                        Text(s.title, textAlign: TextAlign.center, style: AppText.title),
                        const SizedBox(height: 12),
                        Text(s.body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.inkSoft)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -6)],
                ),
                child: FilledButton(
                  onPressed: last ? _start : () => _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                  child: Text(last ? 'Comenzar' : 'Siguiente'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
