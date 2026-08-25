import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../theme/daleh_theme.dart';
import 'primary_button.dart';

class ErrorState extends StatelessWidget {
  final Object erro;
  final VoidCallback? onTentarNovamente;

  const ErrorState({super.key, required this.erro, this.onTentarNovamente});

  IconData get _icone {
    if (erro is ApiException) {
      switch ((erro as ApiException).kind) {
        case ApiErrorKind.network:
          return Icons.wifi_off;
        case ApiErrorKind.unauthorized:
          return Icons.lock_outline;
        case ApiErrorKind.forbidden:
          return Icons.block;
        case ApiErrorKind.notFound:
          return Icons.search_off;
        default:
          return Icons.error_outline;
      }
    }
    return Icons.error_outline;
  }

  String get _mensagem {
    if (erro is ApiException) {
      final e = erro as ApiException;
      if (e.kind == ApiErrorKind.forbidden) {
        return 'Você não tem permissão pra ver ou fazer isso.';
      }
      return e.message;
    }
    return 'Algo deu errado. Tenta de novo.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icone, color: DalehColors.danger, size: 40),
            const SizedBox(height: 16),
            Text(
              _mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DalehColors.text, fontWeight: FontWeight.w700),
            ),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: 20),
              PrimaryButton(label: 'Tentar de novo', onPressed: onTentarNovamente, icon: Icons.refresh),
            ],
          ],
        ),
      ),
    );
  }
}
