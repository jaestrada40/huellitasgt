import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/photo_focus.dart';
import '../theme.dart';
import '../widgets.dart';

/// Resultado de encuadrar la foto: punto de enfoque y zoom.
class PhotoFraming {
  const PhotoFraming(this.focus, this.zoom);
  final Alignment focus;
  final double zoom;
}

const double kMaxPhotoZoom = 4;

/// Hoja para encuadrar la foto de la mascota: se arrastra con un dedo, se
/// pellizca con dos o se usa el deslizador de zoom. Devuelve [PhotoFraming],
/// o `null` si se cancela. Se abre con `enableDrag: false` para que la hoja
/// no le gane los arrastres verticales a la foto.
class PhotoFramingSheet extends StatefulWidget {
  const PhotoFramingSheet({
    super.key,
    required this.file,
    required this.initial,
  });
  final File file;
  final PhotoFraming initial;

  @override
  State<PhotoFramingSheet> createState() => _PhotoFramingSheetState();
}

class _PhotoFramingSheetState extends State<PhotoFramingSheet> {
  // Mismo recorte que la foto grande del perfil (ancho × 300).
  static const _frameRatio = 390 / 300;

  late Alignment _focus = widget.initial.focus;
  late double _zoom = widget.initial.zoom;
  double _zoomAtStart = 1;
  Size? _imageSize;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (mounted) {
      setState(
        () => _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ),
      );
    }
  });

  @override
  void initState() {
    super.initState();
    _stream = FileImage(widget.file).resolve(ImageConfiguration.empty)
      ..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  /// Cuánto sobresale la foto del marco en cada eje con el zoom actual.
  Offset _overflow(Size frame, double zoom) {
    final img = _imageSize;
    if (img == null) return Offset.zero;
    final cover = (frame.width / img.width) > (frame.height / img.height)
        ? frame.width / img.width
        : frame.height / img.height;
    return Offset(
      img.width * cover * zoom - frame.width,
      img.height * cover * zoom - frame.height,
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Size frame) {
    final zoom = (_zoomAtStart * d.scale).clamp(1.0, kMaxPhotoZoom);
    final o = _overflow(frame, zoom);
    setState(() {
      _zoom = zoom;
      _focus = Alignment(
        nextFocus(_focus.x, d.focalPointDelta.dx, o.dx),
        nextFocus(_focus.y, d.focalPointDelta.dy, o.dy),
      );
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ajusta la foto',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Arrástrala con un dedo. Pellizca o usa el zoom para acercarla.',
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              // En pantallas bajas o con texto grande el marco se achica
              // (misma proporción) para que la hoja nunca se desborde.
              final maxH = (MediaQuery.of(context).size.height - 400).clamp(
                140.0,
                double.infinity,
              );
              final h = (c.maxWidth / _frameRatio) < maxH
                  ? c.maxWidth / _frameRatio
                  : maxH;
              final frame = Size(h * _frameRatio, h);
              return Center(
                child: GestureDetector(
                  key: const Key('framingArea'),
                  onScaleStart: (_) => _zoomAtStart = _zoom,
                  onScaleUpdate: (d) => _onScaleUpdate(d, frame),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: frame.width,
                      height: frame.height,
                      child: FramedImage(
                        file: widget.file,
                        focus: _focus,
                        zoom: _zoom,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.zoom_out_rounded, color: AppColors.inkSoft),
              Expanded(
                child: Slider(
                  key: const Key('zoomSlider'),
                  value: _zoom,
                  min: 1,
                  max: kMaxPhotoZoom,
                  onChanged: (v) => setState(() => _zoom = v),
                ),
              ),
              const Icon(Icons.zoom_in_rounded, color: AppColors.inkSoft),
            ],
          ),
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: FramedImage(
                    file: widget.file,
                    focus: _focus,
                    zoom: _zoom,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Así se verá en Inicio',
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _focus = Alignment.center;
                  _zoom = 1;
                }),
                child: const Text('Restablecer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, PhotoFraming(_focus, _zoom)),
                  child: const Text('Listo'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
