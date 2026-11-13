import '../../../../core/theme/team_theme_provider.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../widgets/student_drawer.dart';
import 'package:flutter/material.dart';
import '../../../../shared/notifications/notifications.dart';
import '../widgets/student_evolution_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../nutrition/domain/entities/diet_entity.dart';
import '../../../nutrition/presentation/pages/diet_view_page.dart';
import '../../../nutrition/presentation/providers/diet_provider.dart';
import '../../../trainer/domain/entities/workout_entity.dart';
import '../providers/student_workout_provider.dart';
import '../widgets/workout_card.dart';
import 'workout_execution_page.dart';

/// Tela home do aluno
class StudentHomePage extends ConsumerStatefulWidget {
  const StudentHomePage({super.key});

  @override
  ConsumerState<StudentHomePage> createState() => _StudentHomePageState();
}

const bool _dietEnabled = true;

class _StudentHomePageState extends ConsumerState<StudentHomePage> {
  @override
  void initState() {
    super.initState();
    // Carrega a dieta do vínculo ativo assim que ele for conhecido.
    Future.microtask(() {
      final linkId = ref.read(studentWorkoutProvider).link?.linkId;
      if (linkId != null) ref.read(dietProvider.notifier).loadDiet(linkId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        precacheAvatar(context, ref.read(authProvider).user?.photoUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final workoutState = ref.watch(studentWorkoutProvider);
    ref.listen(studentWorkoutProvider.select((s) => s.link?.linkId),
        (_, linkId) {
      if (linkId != null) ref.read(dietProvider.notifier).loadDiet(linkId);
    });
    final userName = authState.user?.name.split(' ').first ?? 'Aluno';

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const StudentDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref
                .read(studentWorkoutProvider.notifier)
                .loadCurrentWorkout();
            final linkId = ref.read(studentWorkoutProvider).link?.linkId;
            if (linkId != null) {
              await ref.read(dietProvider.notifier).loadDiet(linkId);
            }
          },
          color: AppColors.teal,
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(userName),

              // Conteúdo
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (workoutState.link != null &&
                        workoutState.link!.consentAt == null)
                      _buildConsentCard(),
                    const PushPromptCard(),
                    const PendingAnamneseCard(),
                    workoutState.isLoading
                        ? _buildLoading()
                        : workoutState.currentWorkout == null
                            ? _buildNoWorkout()
                            : _buildContent(context, ref, workoutState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(String userName) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Bom dia';
    } else if (hour < 18) {
      greeting = 'Boa tarde';
    } else {
      greeting = 'Boa noite';
    }

    // Saudação no estilo da marca, abaixo dos ícones (sem sobrepor).
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu, color: AppColors.textPrimary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  () {
                    final d =
                        DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now);
                    return d[0].toUpperCase() + d.substring(1);
                  }(),
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '$greeting, ', style: AppTextStyles.voice),
                    TextSpan(
                      text: '$userName.',
                      style: AppTextStyles.voice.copyWith(
                        color: AppColors.pink,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ])),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Histórico, perfil e sair ficaram no menu (☰).
        const TeamThemeButton(),
        const NotificationBell(),
      ],
    );
  }

  /// Termo de consentimento (LGPD) mostrado no primeiro acesso.
  Widget _buildConsentCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uso dos seus dados', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Para montar e acompanhar seus treinos, seu personal registra '
            'informações como medidas, avaliações físicas, anamnese e o '
            'histórico dos treinos. Esses dados ficam visíveis só para você '
            'e para o seu personal, e são apagados se você sair do time.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () =>
                  ref.read(studentWorkoutProvider.notifier).acceptConsent(),
              child: const Text('Li e concordo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StudentWorkoutState workoutState,
  ) {
    final workout = workoutState.currentWorkout!;
    final dietState = ref.watch(dietProvider);
    final diet = dietState.currentDiet;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informações do treino atual
          _buildWorkoutInfo(workout),

          const SizedBox(height: 24),

          // SEÇÃO: Dieta (ligada ao Firestore na leva 3; até lá fica oculta
          // para o aluno não ver uma dieta de exemplo como se fosse dele)
          if (_dietEnabled) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Minha Dieta',
                  style: AppTextStyles.headlineMedium,
                ),
                if (diet != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DietViewPage(
                            studentId:
                                ref.read(studentWorkoutProvider).link!.linkId,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Ver tudo',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.teal,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (diet != null)
              _buildDietPreview(context, diet)
            else
              _buildNoDietCard(),
            const SizedBox(height: 24),
          ],

          // Título das divisões
          Text(
            'Seus Treinos',
            style: AppTextStyles.headlineMedium,
          ),

          const SizedBox(height: 16),

          // Lista de divisões
          ...workout.divisions.map((division) {
            return WorkoutCard(
              division: division,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutExecutionPage(
                      division: division,
                    ),
                  ),
                );
              },
              lastCompletedDate: null,
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfo(WorkoutEntity workout) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treino Atual',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      workout.name,
                      style: AppTextStyles.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (workout.description != null) ...[
            const SizedBox(height: 12),
            Text(
              workout.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.fitness_center,
                label: '${workout.totalDivisions} divisões',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.list,
                label: '${workout.totalExercises} exercícios',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietPreview(BuildContext context, DietEntity diet) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DietViewPage(
              studentId: ref.read(studentWorkoutProvider).link!.linkId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Superfície lisa com borda (antes: degradê verde chamativo).
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.shadowLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diet.name,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${diet.totalMeals} refeições',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),

            const SizedBox(height: 16),

            // Macros resumidos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickMacro(
                  '${diet.totalDailyCalories.toStringAsFixed(0)}\nkcal',
                  Icons.local_fire_department,
                ),
                _buildQuickMacro(
                  '${diet.totalDailyProtein.toStringAsFixed(0)}g\nProt',
                  Icons.egg,
                ),
                _buildQuickMacro(
                  '${diet.totalDailyCarbs.toStringAsFixed(0)}g\nCarbs',
                  Icons.grain,
                ),
                _buildQuickMacro(
                  '${diet.totalDailyFats.toStringAsFixed(0)}g\nGord',
                  Icons.opacity,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMacro(String text, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDietCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_menu,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhuma dieta prescrita',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aguarde seu professor',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.teal),
      ),
    );
  }

  Widget _buildNoWorkout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum treino prescrito',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aguarde seu professor prescrever\num treino para você',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
