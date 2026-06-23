import 'package:flutter/material.dart';
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
import '../../domain/entities/student_entity.dart';



/// Tela principal do Dashboard do Professor
class TrainerHomePage extends ConsumerStatefulWidget {
  const TrainerHomePage({super.key});

  @override
  ConsumerState<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends ConsumerState<TrainerHomePage> {
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

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('NOTIFICAÇÕES', style: AppTextStyles.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              title: 'Treino Concluído',
              subtitle: 'Ana Paula Silva finalizou o Treino B.',
              time: 'Há 10 min',
            ),
            const Divider(color: AppColors.surfaceLight),
            _buildNotificationItem(
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              title: 'Mensalidade Atrasada',
              subtitle: 'Pedro Oliveira está com pagamento pendente.',
              time: 'Há 2 horas',
            ),
            const Divider(color: AppColors.surfaceLight),
            _buildNotificationItem(
              icon: Icons.local_fire_department,
              color: AppColors.warning,
              title: 'Foco no Treino',
              subtitle: 'Carlos Mendes concluiu o 3º treino da semana.',
              time: 'Há 1 dia',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineSmall.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(time, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
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

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.textPrimary),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      actions: [
        // Notificações
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: AppColors.textPrimary,
              onPressed: () => _showNotificationsDialog(context),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName! 👋',
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('EEEE, d MMMM', 'pt_BR').format(now),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkTeal.withValues(alpha: 0.1),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(TrainerDashboardState state) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visão Geral',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              StatCard(
                title: 'Total de Alunos',
                value: state.totalStudents.toString(),
                icon: Icons.people,
                iconColor: AppColors.teal,
                onTap: () {
                      Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StudentsListPage(),
                      ),
                    );
                },
              ),
              StatCard(
                title: 'Alunos Ativos',
                value: state.activeStudents.toString(),
                icon: Icons.check_circle,
                iconColor: AppColors.success,
                onTap: () {
                  // TODO: Filtrar ativos
                },
              ),
              StatCard(
                title: 'Pagamentos Pendentes',
                value: state.pendingPayments.toString(),
                icon: Icons.warning,
                iconColor: AppColors.warning,
                backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                onTap: () {
                  // TODO: Ver pagamentos pendentes
                },
              ),
              StatCard(
                title: 'Receita Mensal',
                value: currencyFormat.format(state.monthlyRevenue),
                icon: Icons.attach_money,
                iconColor: AppColors.success,
                subtitle: 'Prevista',
                onTap: () {
                  // TODO: Ver detalhes financeiros
                },
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
            'Ações Rápidas',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 16),
          QuickActionCard(
            title: 'Adicionar Novo Aluno',
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
            title: 'Criar Novo Treino',
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
            title: 'Registrar Avaliação',
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
                'Alunos Recentes',
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
        'Novo Aluno',
        style: AppTextStyles.buttonMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}