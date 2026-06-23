import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/presentation/widgets/custom_button.dart';

/// Tela padrão de alta fidelidade para funcionalidades futuras
class FeaturePlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'Estamos preparando esta seção com recursos avançados para alavancar seu trabalho. Em breve estará disponível.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(title.toUpperCase(), style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone com brilho gradiente de fundo
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 72,
                  color: AppColors.lightTeal,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Novidades a caminho!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'VOLTAR',
                onPressed: () => Navigator.of(context).pop(),
                type: ButtonType.secondary,
                icon: Icons.chevron_left,
                width: 160,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
