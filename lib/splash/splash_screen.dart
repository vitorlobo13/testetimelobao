import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Tela de Splash Screen profissional com animações
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToHome();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // TODO: Navegar para tela de login/home
       Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Status bar transparente
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.darkTeal.withValues(alpha: 0.2),
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Placeholder (substitua por sua logo)
                      _buildLogoPlaceholder(),
                      
                      const SizedBox(height: 40),
                      
                      // Nome do App
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.primaryGradient
                            .createShader(bounds),
                        child: Text(
                          'TIME LOBÃO',
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 56,
                            letterSpacing: 4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Slogan
                      Text(
                        'QUEM ACORDA CEDO BEBE ÁGUA LIMPA',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Loading Indicator
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

Widget _buildLogoPlaceholder() {
  return Container(
    width: 200, // Aumentei um pouco para valorizar os detalhes da logo
    height: 200,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      // Mantive a sombra para dar profundidade, mas removi o fundo verde
      boxShadow: AppColors.shadowLarge,
    ),
    child: ClipOval(
      child: Image.asset(
        'lib/assets/icons/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Caso o caminho esteja errado, ele mostra o halter para o app não crashar
          return Icon(Icons.fitness_center, size: 70, color: AppColors.teal);
        },
      ),
    ),
  );
}

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.teal,
        ),
      ),
    );
  }
}