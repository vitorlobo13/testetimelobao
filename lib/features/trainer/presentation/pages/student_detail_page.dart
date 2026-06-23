import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../domain/entities/student_entity.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';
import '../widgets/workout_history_item.dart';
import '../widgets/payment_history_item.dart';
import 'create_workout_page.dart';
import 'add_student_page.dart';
import 'physical_assessment_page.dart';
import '../providers/trainer_provider.dart';
import '../../../nutrition/presentation/pages/create_diet_page.dart';
import '../../../nutrition/presentation/providers/diet_provider.dart';
import '../../../nutrition/presentation/widgets/macros_chart.dart';
import '../../../nutrition/presentation/widgets/meal_card.dart';
import '../../../nutrition/presentation/widgets/food_item_card.dart';
import '../../../nutrition/domain/entities/meal_entity.dart';


/// Tela de detalhes completos do aluno
class StudentDetailPage extends ConsumerStatefulWidget {
  final StudentEntity student;

  const StudentDetailPage({
    super.key,
    required this.student,
  });

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StudentEntity _currentStudent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
      // Carrega dieta do aluno
      Future.microtask(() {
        ref.read(dietProvider.notifier).loadDiet(widget.student.id);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _currentStudent = ref.watch(trainerDashboardProvider).students.firstWhere(
      (s) => s.id == widget.student.id,
      orElse: () => widget.student,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar com foto e nome
            _buildAppBar(),

            // Abas
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.teal,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.teal,
                  labelStyle: AppTextStyles.buttonMedium,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Informações'),
                    Tab(text: 'Treinos'),
                    Tab(text: 'Pagamentos'),
                    Tab(text: 'Dieta'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(),
            _buildWorkoutsTab(),                
            _buildPaymentsTab(),
            _buildDietTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddStudentPage(
                  student: _currentStudent,
                ),
              ),
            );
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
          color: AppColors.surface,
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.block, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Text('Suspender', style: AppTextStyles.bodyMedium),
                ],
              ),
              onTap: () {
                // TODO: Implementar suspensão
              },
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Text('Excluir', style: AppTextStyles.bodyMedium),
                ],
              ),
              onTap: () {
                // TODO: Implementar exclusão
              },
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkTeal.withValues(alpha: 0.3),
                AppColors.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                // Avatar
                _buildAvatar(),
                const SizedBox(height: 16),
                // Nome
                Text(
                  _currentStudent.name,
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Badges
                _buildBadges(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: AppColors.teal, width: 3),
        boxShadow: AppColors.shadowLarge,
      ),
      child: _currentStudent.photoUrl != null
          ? ClipOval(
              child: Image.network(
                _currentStudent.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = _currentStudent.name
        .split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return Center(
      child: Text(
        initials,
        style: AppTextStyles.displaySmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildBadge(
          _currentStudent.status.displayName,
          _getStatusColor(_currentStudent.status),
        ),
        if (_currentStudent.planType != null)
          _buildBadge(
            _currentStudent.planType!,
            AppColors.teal,
          ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ABA 4: DIETA
  Widget _buildDietTab() {
    final dietState = ref.watch(dietProvider);
    final diet = dietState.currentDiet;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão criar/editar dieta
          if (diet == null)
            CustomButton(
              text: 'CRIAR DIETA',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateDietPage(
                      student: _currentStudent,
                    ),
                  ),
                );
              },
              type: ButtonType.primary,
              icon: Icons.add,
            )
          else
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'EDITAR DIETA',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateDietPage(
                            student: _currentStudent,
                            initialDiet: diet,
                          ),
                        ),
                      );
                    },
                    type: ButtonType.secondary,
                    icon: Icons.edit,
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: '',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateDietPage(
                          student: _currentStudent,
                        ),
                      ),
                    );
                  },
                  type: ButtonType.primary,
                  icon: Icons.add,
                  width: 56,
                  height: 50,
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Dieta atual
          if (diet != null) ...[
            // Informações da dieta
            SectionCard(
              title: 'Dieta Atual',
              icon: Icons.restaurant_menu,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diet.name,
                    style: AppTextStyles.headlineSmall,
                  ),
                  if (diet.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      diet.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Total de Refeições',
                    value: diet.totalMeals.toString(),
                    icon: Icons.restaurant,
                  ),
                  InfoRow(
                    label: 'Data de Criação',
                    value: DateFormat('dd/MM/yyyy').format(diet.createdAt),
                    icon: Icons.calendar_today,
                  ),
                ],
              ),
            ),

            // Resumo nutricional
            MacrosChart(
              totalCalories: diet.totalDailyCalories,
              totalProtein: diet.totalDailyProtein,
              totalCarbs: diet.totalDailyCarbs,
              totalFats: diet.totalDailyFats,
              targetCalories: diet.targetCalories,
              targetProtein: diet.targetProtein,
              targetCarbs: diet.targetCarbs,
              targetFats: diet.targetFats,
            ),

            const SizedBox(height: 16),

            // Refeições
            SectionCard(
              title: 'Refeições',
              icon: Icons.dining,
              child: Column(
                children: [
                  ...diet.meals.map((meal) {
                    return MealCard(
                      meal: meal,
                      onTap: () => _showMealDetailsBottomSheet(context, meal),
                    );
                  }),
                ],
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma dieta prescrita',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.active:
        return AppColors.success;
      case StudentStatus.inactive:
        return AppColors.textTertiary;
      case StudentStatus.suspended:
        return AppColors.error;
      case StudentStatus.trial:
        return AppColors.warning;
    }
  }

  // ABA 1: INFORMAÇÕES
  Widget _buildInfoTab() {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Informações de Contato
          SectionCard(
            title: 'Informações de Contato',
            icon: Icons.contact_phone,
            child: Column(
              children: [
                InfoRow(
                  label: 'Email',
                  value: _currentStudent.email,
                  icon: Icons.email_outlined,
                ),
                if (_currentStudent.phone != null)
                  InfoRow(
                    label: 'Telefone',
                    value: _currentStudent.phone!,
                    icon: Icons.phone_outlined,
                    trailing: IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.teal),
                      onPressed: () {
                        // TODO: Ligar para o aluno
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Dados Físicos
          SectionCard(
            title: 'Dados Físicos',
            icon: Icons.fitness_center,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(
                        label: 'Peso',
                        value: _currentStudent.weight != null
                            ? '${_currentStudent.weight} kg'
                            : 'Não informado',
                        icon: Icons.monitor_weight,
                      ),
                    ),
                    Expanded(
                      child: InfoRow(
                        label: 'Altura',
                        value: _currentStudent.height != null
                            ? '${_currentStudent.height} cm'
                            : 'Não informado',
                        icon: Icons.height,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: InfoRow(
                        label: 'IMC',
                        value: _currentStudent.bmi != null
                            ? _currentStudent.bmi!.toStringAsFixed(1)
                            : 'N/A',
                        valueColor: _getBmiColor(_currentStudent.bmi),
                        icon: Icons.assessment,
                      ),
                    ),
                    Expanded(
                      child: InfoRow(
                        label: 'Idade',
                        value: _currentStudent.age != null
                            ? '${_currentStudent.age} anos'
                            : 'Não informado',
                        icon: Icons.cake,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Informações de Matrícula
          SectionCard(
            title: 'Matrícula',
            icon: Icons.event,
            child: Column(
              children: [
                InfoRow(
                  label: 'Data de Matrícula',
                  value: DateFormat('dd/MM/yyyy').format(_currentStudent.enrollmentDate),
                  icon: Icons.calendar_today,
                ),
                InfoRow(
                  label: 'Tempo como aluno',
                  value: _getEnrollmentDuration(),
                  icon: Icons.schedule,
                ),
                if (_currentStudent.monthlyFee != null)
                  InfoRow(
                    label: 'Mensalidade',
                    value: currencyFormat.format(_currentStudent.monthlyFee),
                    icon: Icons.attach_money,
                    valueColor: AppColors.success,
                  ),
              ],
            ),
          ),

          // Estatísticas de Treino
          SectionCard(
            title: 'Estatísticas',
            icon: Icons.bar_chart,
            child: Column(
              children: [
                InfoRow(
                  label: 'Total de Treinos',
                  value: _currentStudent.totalWorkouts.toString(),
                  icon: Icons.fitness_center,
                ),
                if (_currentStudent.lastWorkoutDate != null)
                  InfoRow(
                    label: 'Último Treino',
                    value: '${_currentStudent.daysSinceLastWorkout} dia(s) atrás',
                    icon: Icons.update,
                    valueColor: _currentStudent.daysSinceLastWorkout! > 7
                        ? AppColors.error
                        : AppColors.success,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ABA 2: TREINOS
  Widget _buildWorkoutsTab() {
    // Dados mockados para demonstração
    final workoutHistory = [
      WorkoutHistoryItem(
        workoutName: 'Treino A - Peito e Tríceps',
        date: DateTime.now().subtract(const Duration(days: 1)),
        duration: 65,
        completed: true,
      ),
      WorkoutHistoryItem(
        workoutName: 'Treino B - Costas e Bíceps',
        date: DateTime.now().subtract(const Duration(days: 3)),
        duration: 70,
        completed: true,
      ),
      WorkoutHistoryItem(
        workoutName: 'Treino C - Pernas',
        date: DateTime.now().subtract(const Duration(days: 5)),
        duration: 80,
        completed: true,
      ),
      WorkoutHistoryItem(
        workoutName: 'Treino D - Ombros',
        date: DateTime.now().subtract(const Duration(days: 7)),
        duration: 55,
        completed: false,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Treino Atual
          SectionCard(
            title: 'Treino Atual',
            icon: Icons.fitness_center,
            actionLabel: 'Editar',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateWorkoutPage(
                    student: _currentStudent,
                  ),
                ),
              );
            },
            child: _currentStudent.currentWorkoutId != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Treino ABC - Hipertrofia',
                        style: AppTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Divisão: Push/Pull/Legs',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Criado em: 15/04/2024',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhum treino prescrito',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ),

          // Histórico de Treinos
          SectionCard(
            title: 'Histórico de Treinos',
            icon: Icons.history,
            actionLabel: 'Ver todos',
            onTap: () {
              _showWorkoutHistoryBottomSheet(context, workoutHistory);
            },
            child: Column(
              children: workoutHistory.isEmpty
                  ? [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Nenhum treino realizado',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : workoutHistory,
            ),
          ),
        ],
      ),
    );
  }

  // ABA 3: PAGAMENTOS
  Widget _buildPaymentsTab() {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Dados mockados para demonstração
    final paymentHistory = [
      PaymentHistoryItem(
        date: DateTime(2024, 5, 1),
        amount: _currentStudent.monthlyFee ?? 250.00,
        paid: false,
        reference: 'Maio/2024',
      ),
      PaymentHistoryItem(
        date: DateTime(2024, 4, 1),
        amount: _currentStudent.monthlyFee ?? 250.00,
        paid: true,
        reference: 'Abril/2024',
      ),
      PaymentHistoryItem(
        date: DateTime(2024, 3, 1),
        amount: _currentStudent.monthlyFee ?? 250.00,
        paid: true,
        reference: 'Março/2024',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Resumo Financeiro
          SectionCard(
            title: 'Resumo Financeiro',
            icon: Icons.account_balance_wallet,
            child: Column(
              children: [
                InfoRow(
                  label: 'Mensalidade',
                  value: _currentStudent.monthlyFee != null
                      ? currencyFormat.format(_currentStudent.monthlyFee)
                      : 'Não definida',
                  icon: Icons.attach_money,
                  valueColor: AppColors.success,
                ),
                if (_currentStudent.nextPaymentDate != null)
                  InfoRow(
                    label: 'Próximo Vencimento',
                    value: DateFormat('dd/MM/yyyy').format(_currentStudent.nextPaymentDate!),
                    icon: Icons.event,
                    valueColor: _currentStudent.isPaymentOverdue
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                InfoRow(
                  label: 'Status',
                  value: _currentStudent.paymentStatus.displayName,
                  icon: Icons.info_outline,
                  valueColor: _getPaymentStatusColor(_currentStudent.paymentStatus),
                ),
              ],
            ),
          ),

          // Histórico de Pagamentos
          SectionCard(
            title: 'Histórico de Pagamentos',
            icon: Icons.receipt_long,
            actionLabel: 'Ver todos',
            onTap: () {
              _showPaymentHistoryBottomSheet(context, paymentHistory);
            },
            child: Column(
              children: paymentHistory,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBottomBar() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(
        top: BorderSide(color: AppColors.surfaceLight),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'PRESCREVER TREINO',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateWorkoutPage(
                    student: _currentStudent,
                  ),
                ),
              );
            },
            type: ButtonType.primary,
            height: 50,
          ),
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: '',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PhysicalAssessmentPage(
                  initialStudent: _currentStudent,
                ),
              ),
            );
          },
          type: ButtonType.secondary,
          icon: Icons.assessment,
          width: 50,
          height: 50,
        ),
      ],
    ),
  );
}

  // Helpers
  Color _getBmiColor(double? bmi) {
    if (bmi == null) return AppColors.textSecondary;
    if (bmi < 18.5) return AppColors.warning;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.overdue:
        return AppColors.error;
      case PaymentStatus.exempt:
        return AppColors.info;
    }
  }

  String _getEnrollmentDuration() {
    final duration = DateTime.now().difference(_currentStudent.enrollmentDate);
    final months = (duration.inDays / 30).floor();
    
    if (months < 1) {
      return '${duration.inDays} dia(s)';
    } else if (months < 12) {
      return '$months mês(es)';
    } else {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      return remainingMonths > 0
          ? '$years ano(s) e $remainingMonths mês(es)'
          : '$years ano(s)';
    }
  }

  void _showWorkoutHistoryBottomSheet(
    BuildContext context,
    List<Widget> items,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico de Treinos',
                      style: AppTextStyles.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: items,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentHistoryBottomSheet(
    BuildContext context,
    List<Widget> items,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico de Pagamentos',
                      style: AppTextStyles.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: items,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMealDetailsBottomSheet(BuildContext context, MealEntity meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              meal.time,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${meal.foods.length} alimento(s)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: meal.foods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.restaurant,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum alimento recomendado',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: meal.foods.length,
                      itemBuilder: (context, index) {
                        final food = meal.foods[index];
                        return FoodItemCard(food: food);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delegate para TabBar fixo
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}