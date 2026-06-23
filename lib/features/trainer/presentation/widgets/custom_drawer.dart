import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../pages/students_list_page.dart';
import '../pages/frequency_report_page.dart';
import '../pages/workout_library_page.dart';
import '../pages/diet_library_page.dart';
import '../pages/financial_management_page.dart';
import '../pages/exercise_videos_page.dart';
import '../pages/physical_assessment_page.dart';
import '../pages/anamnese_page.dart';
import '../../../../shared/widgets/feature_placeholder_page.dart';

/// Menu lateral customizado
class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Cabeçalho do Drawer
            _buildHeader(context, user?.name ?? 'Personal Trainer'),

            const SizedBox(height: 8),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    title: 'Meus Alunos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StudentsListPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.bar_chart,
                    title: 'Relatório de frequência',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FrequencyReportPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.fitness_center,
                    title: 'Biblioteca de Treinos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WorkoutLibraryPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.video_library,
                    title: 'Vídeos de Exercícios',
                    subtitle: '+1800 vídeos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ExerciseVideosPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.assessment,
                    title: 'Avaliações Físicas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PhysicalAssessmentPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.restaurant_menu,
                    title: 'Nutrição e Dietas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DietLibraryPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Anamnese',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AnamnesePage(),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: AppColors.surfaceLight),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.attach_money,
                    title: 'Gestão Financeira',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FinancialManagementPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.campaign,
                    title: 'Marketing',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FeaturePlaceholderPage(
                            title: 'Marketing',
                            icon: Icons.campaign,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.analytics,
                    title: 'Relatórios',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FeaturePlaceholderPage(
                            title: 'Relatórios',
                            icon: Icons.analytics,
                          ),
                        ),
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(color: AppColors.surfaceLight),
                  ),

                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FeaturePlaceholderPage(
                            title: 'Configurações',
                            icon: Icons.settings,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Ajuda e Suporte',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.popUntil(context, ModalRoute.withName('/trainer/home'));
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FeaturePlaceholderPage(
                            title: 'Ajuda e Suporte',
                            icon: Icons.help_outline,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout
            _buildLogoutButton(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Nome
          Text(
            userName,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Personal Trainer',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.teal,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.logout,
            color: AppColors.error,
            size: 24,
          ),
        ),
        title: Text(
          'Sair',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          // Confirmação de logout
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Sair da Conta',
                style: AppTextStyles.headlineMedium,
              ),
              content: Text(
                'Tem certeza que deseja sair?',
                style: AppTextStyles.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancelar',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Sair',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldLogout == true && context.mounted) {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
        },
      ),
    );
  }
}