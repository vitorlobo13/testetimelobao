import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/user_entity.dart';
import '../widgets/custom_button.dart';
import '../widgets/profile_card.dart';
import '../providers/auth_provider.dart';

/// Tela de Seleção de Perfil (Professor ou Aluno)
class ProfileSelectionPage extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String password;

  const ProfileSelectionPage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<ProfileSelectionPage> createState() =>
      _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends ConsumerState<ProfileSelectionPage>
    with SingleTickerProviderStateMixin {
  UserType? _selectedProfile;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um perfil para continuar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Registra o usuário
    final success = await ref.read(authProvider.notifier).register(
          name: widget.name,
          email: widget.email,
          password: widget.password,
          userType: _selectedProfile!,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navega baseado no tipo de usuário
      if (_selectedProfile == UserType.trainer) {
        Navigator.of(context).pushReplacementNamed('/trainer/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/student/home');
      }
    } else {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.darkTeal.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Cabeçalho
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildHeader(),
                ),

                // Cards de perfil
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Card Professor
                        ProfileCard(
                          title: 'PERSONAL TRAINER',
                          description:
                              'Gerencie seus alunos e prescreva treinos personalizados',
                          icon: Icons.fitness_center,
                          isSelected: _selectedProfile == UserType.trainer,
                          onTap: () {
                            setState(() {
                              _selectedProfile = UserType.trainer;
                            });
                          },
                          features: const [
                            'Gestão completa de alunos',
                            'Prescrição de treinos e exercícios',
                            'Biblioteca com +1800 vídeos',
                            'Anamnese e avaliações físicas',
                            'Controle financeiro',
                            'Ferramentas de marketing',
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Card Aluno
                        ProfileCard(
                          title: 'ALUNO',
                          description:
                              'Acompanhe seus treinos e evolua seus resultados',
                          icon: Icons.person,
                          isSelected: _selectedProfile == UserType.student,
                          onTap: () {
                            setState(() {
                              _selectedProfile = UserType.student;
                            });
                          },
                          features: const [
                            'Acesso aos seus treinos',
                            'Vídeos demonstrativos',
                            'Cronômetro e controle de séries',
                            'Histórico de evolução',
                            'Feedback para o professor',
                            'Gestão de pagamentos',
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Botão de continuar
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: CustomButton(
                    text: 'FINALIZAR CADASTRO',
                    onPressed: authState.isLoading ? null : _handleContinue,
                    isLoading: authState.isLoading,
                    type: ButtonType.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quase lá, ${widget.name.split(' ').first}!',
          style: AppTextStyles.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione seu perfil para personalizar sua experiência',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _selectedProfile != null
                      ? AppColors.teal
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Passo 3 de 3',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}