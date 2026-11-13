import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/confirm_logout.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../nutrition/presentation/pages/diet_view_page.dart';
import '../pages/my_workouts_page.dart';
import '../pages/student_anamnese_page.dart';
import '../pages/student_profile_page.dart';
import '../pages/workout_history_page.dart';
import '../providers/student_workout_provider.dart';

/// Menu lateral do aluno: só o que ele pode ver e fazer.
class StudentDrawer extends ConsumerWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final linkId = ref.watch(studentWorkoutProvider).link?.linkId;

    /// Fecha o menu, volta para a tela inicial e abre [page].
    void open(Widget page) {
      Navigator.pop(context);
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.pink, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileAvatar(radius: 35, borderColor: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Aluno',
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text('Aluno', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _item(Icons.home_outlined, 'Início', () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }),
                  _item(Icons.fitness_center, 'Meus treinos',
                      () => open(const MyWorkoutsPage())),
                  if (linkId != null)
                    _item(Icons.restaurant_menu, 'Minha dieta',
                        () => open(DietViewPage(studentId: linkId))),
                  _item(Icons.history, 'Histórico de treinos',
                      () => open(const WorkoutHistoryPage())),
                  _item(Icons.person_outline, 'Meu perfil',
                      () => open(const StudentProfilePage()),
                      subtitle: 'Dados, evolução e avaliações'),
                  if (linkId != null)
                    _item(Icons.assignment_outlined, 'Anamnese',
                        () => open(StudentAnamnesePage(linkId: linkId))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
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
                  child: const Icon(Icons.logout, color: AppColors.error),
                ),
                title: Text(
                  'Sair',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => confirmLogout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap,
      {String? subtitle}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.teal, size: 24),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: subtitle == null
          ? null
          : Text(subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}
