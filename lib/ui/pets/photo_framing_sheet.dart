import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/photo_focus.dart';
import '../theme.dart';

/// Hoja para encuadrar la foto de la mascota arrastrándola. Devuelve el
/// nuevo enfoque como [Alignment], o `null` si se cancela.
class PhotoFramingSheet extends StatefulWidget {
  const PhotoFramingSheet({super.key, required this.file, required this.initial});
  final File file;
  final Alignment initial;

  @override
  State<PhotoFramingSheet> createState() => _PhotoFramingSheetState();
}

class _PhotoFramingSheetState extends State<PhotoFramingSheet> {
  // Mismo recorte que la foto grande del perfil (ancho × 300).
  static const _frameRatio = 390 / 300;

  late Alignment _focus = widget.initial;
  Size? _imageSize;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (mounted) {
      setState(() => _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble()));
    }
  });

  @override
  void initState() {
    super.initState();
    _stream = FileImage(widget.file).resolve(ImageConfiguration.empty)..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  void _drag(DragUpdateDetails d, Size frame) {
    final img = _imageSize;
    if (img == null) return;
    final scale = (frame.width / img.width) > (frame.height / img.height)
        ? frame.width / img.width
        : frame.height / img.height;
    setState(() {
      _focus = Alignment(
        nextFocus(_focus.x, d.delta.dx, img.width * scale - frame.width),
        nextFocus(_focus.y, d.delta.dy, img.height * scale - frame.height),
      );
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Ajusta la foto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('Arrástrala para centrar a tu mascota.', style: TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final frame = Size(c.maxWidth, c.maxWidth / _frameRatio);
                return GestureDetector(
                  key: const Key('framingArea'),
                  onPanUpdate: (d) => _drag(d, frame),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: frame.width,
                      height: frame.height,
                      child: Image.file(widget.file, fit: BoxFit.cover, alignment: _focus),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Image.file(widget.file, fit: BoxFit.cover, alignment: _focus),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Así se verá en Inicio', style: TextStyle(color: AppColors.inkSoft))),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, _focus), child: const Text('Listo'))),
            ]),
          ]),
        ),
      );
}
