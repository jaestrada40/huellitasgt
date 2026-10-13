import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/treatment_status.dart';
import '../domain/weight_unit.dart';
import 'format.dart';
import 'theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.ring,
    this.color = AppColors.card,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  /// Anillo de 1 px (p. ej. coral para lo atrasado).
  final Color? ring;
  final Color color;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        boxShadow: color == AppColors.card ? cardShadow() : null,
        border: ring == null ? null : Border.all(color: ring!.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

enum StatusKind { ok, soon, overdue, today }

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.kind, {super.key});

  factory StatusChip.forDue(DueStatus s, String label, {Key? key}) => StatusChip(
        label,
        label == 'Hoy'
            ? StatusKind.today
            : switch (s) {
                DueStatus.overdue => StatusKind.overdue,
                DueStatus.dueSoon => StatusKind.soon,
                DueStatus.upcoming => StatusKind.ok,
              },
        key: key,
      );

  final String label;
  final StatusKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      StatusKind.ok => (AppColors.mint, AppColors.mintInk),
      StatusKind.soon => (AppColors.peach, AppColors.orangeText),
      StatusKind.overdue => (AppColors.coral.withValues(alpha: 0.15), AppColors.coral),
      StatusKind.today => (AppColors.orange, AppColors.onPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.caps = false});
  final String title;
  final Widget? trailing;

  /// Etiqueta pequeña en mayúsculas (TIPO, MASCOTA...).
  final bool caps;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(4, caps ? 16 : 20, 4, 8),
        child: Row(children: [
          Expanded(child: Text(caps ? title.toUpperCase() : title, style: caps ? AppText.caps : AppText.h2)),
          ?trailing,
        ]),
      );
}

/// Color de fondo y de ícono por tipo de evento (como en el diseño).
(Color bg, Color fg) typeColors(EventType t) => switch (t) {
      EventType.vaccine => (AppColors.mint, AppColors.mintInk),
      EventType.deworming => (AppColors.peach, AppColors.orangeText),
      EventType.fleaTick => (AppColors.greenBg, AppColors.greenInk),
      EventType.illness => (AppColors.coral.withValues(alpha: 0.15), AppColors.coral),
      EventType.checkup => (AppColors.muted, AppColors.ink),
    };

class TypeIcon extends StatelessWidget {
  const TypeIcon(this.type, {super.key, this.size = 44});
  final EventType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = typeColors(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(iconForType(type), color: fg, size: size * 0.48),
    );
  }
}

class PetAvatar extends ConsumerWidget {
  const PetAvatar({super.key, required this.pet, this.size = 48});
  final Pet pet;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rel = pet.photoPath;
    final file = rel == null ? null : ref.watch(attachmentStoreProvider).fileFor(rel);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: (file != null && file.existsSync())
            ? FramedImage(file: file, focus: Alignment(pet.photoFocusX, pet.photoFocusY), zoom: pet.photoZoom)
            : ColoredBox(
                color: AppColors.mint,
                child: Icon(Icons.pets, color: AppColors.primary, size: size * 0.5),
              ),
      ),
    );
  }
}

/// Foto grande de la mascota (o un fondo menta con huella si no tiene).
class PetPhoto extends ConsumerWidget {
  const PetPhoto({super.key, required this.pet, required this.height});
  final Pet pet;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rel = pet.photoPath;
    final file = rel == null ? null : ref.watch(attachmentStoreProvider).fileFor(rel);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: (file != null && file.existsSync())
          ? FramedImage(file: file, focus: Alignment(pet.photoFocusX, pet.photoFocusY), zoom: pet.photoZoom)
          : const ColoredBox(
              color: AppColors.mint,
              child: Icon(Icons.pets, color: AppColors.primary, size: 96),
            ),
    );
  }
}

/// Botón redondo blanco (atrás, etc.) sobre fotos.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: AppColors.shadow.withValues(alpha: 0.3),
        child: IconButton(tooltip: tooltip, onPressed: onTap, icon: Icon(icon, color: AppColors.ink, size: 22)),
      );
}

/// Encabezado de pantallas secundarias: «‹ Atrás» y el título grande.
class BackHeader extends StatelessWidget {
  const BackHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          label: const Text('Atrás', style: TextStyle(fontSize: 16)),
        ),
        Text(title, style: AppText.title),
        const SizedBox(height: 16),
      ]);
}

/// Foto con el encuadre elegido: llena el marco (cover), alineada al punto de
/// enfoque y ampliada [zoom] veces desde ese mismo punto. Equivale a dibujar la
/// foto a `zoom` veces su tamaño de cover con esa alineación, así el enfoque
/// -1..1 siempre significa «ese borde pegado al marco».
class FramedImage extends StatelessWidget {
  const FramedImage({super.key, required this.file, this.focus = Alignment.center, this.zoom = 1});
  final File file;
  final Alignment focus;
  final double zoom;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: Transform.scale(
          scale: zoom,
          alignment: focus,
          child: Image.file(
            file,
            fit: BoxFit.cover,
            alignment: focus,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
}

/// Selector kg | lb para ponerlo junto a los campos de peso. Cambia la unidad
/// de toda la app (la misma de Ajustes).
class WeightUnitToggle extends ConsumerWidget {
  const WeightUnitToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(weightUnitProvider);
    Widget option(WeightUnit u) {
      final on = u == unit;
      return GestureDetector(
        key: Key('weightUnit_${u.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(weightUnitProvider.notifier).select(u),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            u.symbol,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: on ? AppColors.onPrimary : AppColors.inkSoft,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [for (final u in WeightUnit.values) option(u)]),
    );
  }
}
