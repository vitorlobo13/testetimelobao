import 'package:flutter/material.dart';
import '../shared/widgets/brand_wordmark.dart';
import 'package:flutter/services.dart';
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

  // A navegação a partir do splash é feita pelo go_router (app_router.dart)
  // assim que o Firebase informa se existe sessão salva.

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
                      // Marca Time Lobo Lopes (tipográfica até chegar o logo)
                      const BrandWordmark(size: 58),

                      const SizedBox(height: 20),

                      // Assinatura da marca
                      Text(
                        'Mesma essência. Mais força. Mais resultados.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
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