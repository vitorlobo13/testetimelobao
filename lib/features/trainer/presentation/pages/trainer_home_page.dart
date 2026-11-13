import 'package:flutter/material.dart';
import '../../../../shared/notifications/notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/trainer_provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/student_card.dart';
import 'package:intl/intl.dart';
import 'students_list_page.dart';
import 'student_detail_page.dart';
import 'add_student_page.dart';
import 'create_workout_page.dart';
import 'physical_assessment_page.dart';
import 'financial_management_page.dart';
import 'trainer_updates_page.dart';
import '../../domain/entities/student_entity.dart';



/// Tela principal do Dashboard do Professor
class TrainerHomePage extends ConsumerStatefulWidget {
  const TrainerHomePage({super.key});

  @override
  ConsumerState<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends ConsumerState<TrainerHomePage> {
  void _openFinance() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FinancialManagementPage()),
      );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Carrega dados ao iniciar
    Future.microtask(
      () => ref.read(trainerDashboardProvider.notifier).loadDashboardData(),
    );
  }

  Future<void> _onRefresh() async {
    await ref.read(trainerDashboardProvider.notifier).refresh();
  }

  void _showSelectStudentSheet(BuildContext context, List<StudentEntity> students, {required void Function(StudentEntity) onSelect}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selecione o Aluno', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                      child: Text(student.name[0].toUpperCase(), style: const TextStyle(color: AppColors.lightTeal)),
                    ),
                    title: Text(student.name, style: AppTextStyles.bodyLarge),
                    subtitle: Text(student.email, style: AppTextStyles.bodySmall),
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(student);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(trainerDashboardProvider);
    final userName = authState.user?.name.split(' ').first ?? 'Professor';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.teal,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            slivers: [
              // App Bar customizada
              _buildAppBar(userName),

              // Conteúdo
              SliverToBoxAdapter(
                child: dashboardState.isLoading && dashboardState.students.isEmpty
                    ? _buildLoading()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ativar push neste aparelho
                          const PushPromptCard(),

                          // Cards de estatísticas
                          _buildStatsSection(dashboardState),

                          const SizedBox(height: 24),

                          // Ações rápidas
                          _buildQuickActionsSection(dashboardState),

                          const SizedBox(height: 24),

                          // Últimos alunos
                          _buildRecentStudentsSection(dashboardState),

                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
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

    // Barra fixa só com os ícones; a saudação fica no conteúdo, para não
    // passar por cima dos ícones no celular.
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: const [
        // Atualizações (pendências por aluno) e notificações
        TrainerUpdatesButton(),
        NotificationBell(),
        SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _capitalize(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now)),
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$greeting, ', style: AppTextStyles.voice),
                    TextSpan(
                      text: '$userName.',
                      style: AppTextStyles.voice.copyWith(
                        color: AppColors.pink,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildStatsSection(TrainerDashboardState state) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visão geral',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Altura fixa: nada vaza da caixa, no celular ou no computador.
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 96,
            ),
            children: [
              StatCard(
                title: 'Alunos',
                value: state.totalStudents.toString(),
                icon: Icons.people,
                iconColor: AppColors.blueLight,
                onTap: () {
                      Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StudentsListPage(),
                      ),
                    );
                },
              ),
              StatCard(
                title: 'Ativos',
                value: state.activeStudents.toString(),
                icon: Icons.check_circle,
                iconColor: AppColors.success,
                onTap: () {
                  // TODO: Filtrar ativos
                },
              ),
              StatCard(
                title: 'Pendentes',
                value: state.pendingPayments.toString(),
                icon: Icons.schedule,
                iconColor: AppColors.pink,
                // Realça (número e borda em rosa) só quando há pendência.
                backgroundColor:
                    state.pendingPayments > 0 ? AppColors.pink : null,
                onTap: _openFinance,
              ),
              StatCard(
                title: 'Receita/mês',
                value: currencyFormat.format(state.monthlyRevenue),
                icon: Icons.attach_money,
                iconColor: AppColors.success,
                onTap: _openFinance,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(TrainerDashboardState dashboardState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações rápidas',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 16),
          QuickActionCard(
            title: 'Adicionar aluno',
            description: 'Cadastre um novo aluno no sistema',
            icon: Icons.person_add,
            color: AppColors.teal,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddStudentPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          QuickActionCard(
            title: 'Criar treino',
            description: 'Monte um treino personalizado',
            icon: Icons.fitness_center,
            color: AppColors.success,
            onTap: () {
              _showSelectStudentSheet(
                context,
                dashboardState.students,
                onSelect: (student) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateWorkoutPage(student: student),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          QuickActionCard(
            title: 'Registrar avaliação',
            description: 'Faça avaliação física de um aluno',
            icon: Icons.assignment,
            color: AppColors.info,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PhysicalAssessmentPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStudentsSection(TrainerDashboardState state) {
    final recentStudents = state.students.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alunos recentes',
                style: AppTextStyles.headlineMedium,
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StudentsListPage(),
                    ),
                  );
                },
                child: Text(
                  'Ver todos',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentStudents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum aluno cadastrado',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...recentStudents.map(
              (student) => StudentCard(
                student: student,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StudentDetailPage(student: student),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(
          color: AppColors.teal,
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AddStudentPage(),
          ),
        );
      },
      backgroundColor: AppColors.teal,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        'Novo aluno',
        style: AppTextStyles.buttonMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}