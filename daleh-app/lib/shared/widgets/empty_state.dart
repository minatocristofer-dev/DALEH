import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';
import 'primary_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: DalehColors.surface2, shape: BoxShape.circle),
              child: Icon(icon, color: DalehColors.turf, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DalehColors.muted, fontSize: 13),
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: PrimaryButton(label: ctaLabel!, onPressed: onCta)),
            ],
          ],
        ),
      ),
    );
  }
}
