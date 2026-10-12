import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/models.dart';
import '../domain/treatment_status.dart';
import 'theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.stripe,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? stripe;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: stripe == null
              ? content
              : IntrinsicHeight(
                  child: Row(children: [
                    Container(width: 4, color: stripe),
                    Expanded(child: content),
                  ]),
                ),
        ),
      ),
    );
  }
}

enum StatusKind { ok, soon, overdue }

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.kind, {super.key});

  factory StatusChip.forDue(DueStatus s, String label, {Key? key}) => StatusChip(
        label,
        switch (s) {
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
      StatusKind.ok => (AppColors.primary, AppColors.primary),
      StatusKind.soon => (AppColors.orange, AppColors.orangeText),
      StatusKind.overdue => (AppColors.coral, AppColors.coral),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ?trailing,
        ]),
      );
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
            ? Image.file(file, fit: BoxFit.cover)
            : ColoredBox(
                color: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(Icons.pets, color: AppColors.primary, size: size * 0.5),
              ),
      ),
    );
  }
}
