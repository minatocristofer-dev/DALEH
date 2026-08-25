import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool carregando;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.carregando = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final desabilitado = carregando || onPressed == null;
    return ElevatedButton(
      onPressed: desabilitado ? null : onPressed,
      child: carregando
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: DalehColors.bg),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
  }
}
