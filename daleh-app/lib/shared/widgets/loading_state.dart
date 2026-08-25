import 'package:flutter/material.dart';
import '../../theme/daleh_theme.dart';

class LoadingState extends StatelessWidget {
  final String? mensagem;
  const LoadingState({super.key, this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: DalehColors.turf),
            if (mensagem != null) ...[
              const SizedBox(height: 16),
              Text(mensagem!, style: const TextStyle(color: DalehColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}
