import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Botão customizado com múltiplos estilos
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (type) {
      case ButtonType.primary:
        return _PrimaryButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case ButtonType.secondary:
        return _SecondaryButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case ButtonType.outline:
        return _OutlineButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case ButtonType.text:
        return _TextOnlyButton(
          text: text,
          onPressed: onPressed,
          icon: icon,
        );
    }
  }
}

/// Botão primário com gradiente
class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? AppColors.primaryGradient
            : LinearGradient(
                colors: [
                  AppColors.surfaceLight,
                  AppColors.surfaceLight,
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null ? AppColors.shadowMedium : [],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.buttonLarge),
        ],
      );
    }
    return Text(text, style: AppTextStyles.buttonLarge);
  }
}

/// Botão secundário
class _SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _SecondaryButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(text, style: AppTextStyles.buttonLarge),
                  ],
                )
              : Text(text, style: AppTextStyles.buttonLarge),
    );
  }
}

/// Botão com outline
class _OutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const _OutlineButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.teal, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.teal,
                  ),
                ),
    );
  }
}

/// Botão apenas texto
class _TextOnlyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const _TextOnlyButton({
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: AppColors.teal),
                const SizedBox(width: 4),
                Text(
                  text,
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.teal,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.teal,
              ),
            ),
    );
  }
}

/// Tipos de botão disponíveis
enum ButtonType {
  primary,
  secondary,
  outline,
  text,
}