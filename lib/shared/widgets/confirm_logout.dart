import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Pergunta se a pessoa quer mesmo sair e, se confirmar, encerra a sessão.
/// O go_router volta para o login quando a sessão termina.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Sair da conta', style: AppTextStyles.headlineMedium),
      content: Text('Tem certeza que deseja sair?',
          style: AppTextStyles.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar',
              style: AppTextStyles.buttonMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Sair',
              style: AppTextStyles.buttonMedium
                  .copyWith(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (shouldLogout == true && context.mounted) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    await ref.read(authProvider.notifier).logout();
  }
}
