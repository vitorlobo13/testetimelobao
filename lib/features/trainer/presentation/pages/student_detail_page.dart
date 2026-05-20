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
import '../../../nutrition/presentation/pages/create_diet_page.dart';
import '../../../nutrition/presentation/providers/diet_provider.dart';
import '../../../nutrition/presentation/widgets/meal_card.dart';
import '../../../nutrition/presentation/widgets/macros_chart.dart';


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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
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

          // Conteúdo das abas
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildWorkoutsTab(),                
                _buildPaymentsTab(),
                _buildDietTab(),
              ],
            ),
          ),
        ],
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Editar aluno')),
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
                AppColors.darkTeal.withOpacity(0.3),
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
                  widget.student.name,
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
      child: widget.student.photoUrl != null
          ? ClipOval(
              child: Image.network(
                widget.student.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = widget.student.name
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
          widget.student.status.displayName,
          _getStatusColor(widget.student.status),
        ),
        if (widget.student.planType != null)
          _buildBadge(
            widget.student.planType!,
            AppColors.teal,
          ),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
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
                      student: widget.student,
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
                      // TODO: Implementar edição
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edição em desenvolvimento'),
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
                          student: widget.student,
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    meal.name,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  meal.time,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildMiniMacro(
                                  '${meal.totalCalories.toStringAsFixed(0)} kcal',
                                  AppColors.warning,
                                ),
                                _buildMiniMacro(
                                  'P: ${meal.totalProtein.toStringAsFixed(0)}g',
                                  AppColors.error,
                                ),
                                _buildMiniMacro(
                                  'C: ${meal.totalCarbs.toStringAsFixed(0)}g',
                                  AppColors.success,
                                ),
                                _buildMiniMacro(
                                  'G: ${meal.totalFats.toStringAsFixed(0)}g',
                                  AppColors.info,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildMiniMacro(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
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
                  value: widget.student.email,
                  icon: Icons.email_outlined,
                ),
                if (widget.student.phone != null)
                  InfoRow(
                    label: 'Telefone',
                    value: widget.student.phone!,
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
                        value: widget.student.weight != null
                            ? '${widget.student.weight} kg'
                            : 'Não informado',
                        icon: Icons.monitor_weight,
                      ),
                    ),
                    Expanded(
                      child: InfoRow(
                        label: 'Altura',
                        value: widget.student.height != null
                            ? '${widget.student.height} cm'
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
                        value: widget.student.bmi != null
                            ? widget.student.bmi!.toStringAsFixed(1)
                            : 'N/A',
                        valueColor: _getBmiColor(widget.student.bmi),
                        icon: Icons.assessment,
                      ),
                    ),
                    Expanded(
                      child: InfoRow(
                        label: 'Idade',
                        value: widget.student.age != null
                            ? '${widget.student.age} anos'
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
                  value: DateFormat('dd/MM/yyyy').format(widget.student.enrollmentDate),
                  icon: Icons.calendar_today,
                ),
                InfoRow(
                  label: 'Tempo como aluno',
                  value: _getEnrollmentDuration(),
                  icon: Icons.schedule,
                ),
                if (widget.student.monthlyFee != null)
                  InfoRow(
                    label: 'Mensalidade',
                    value: currencyFormat.format(widget.student.monthlyFee),
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
                  value: widget.student.totalWorkouts.toString(),
                  icon: Icons.fitness_center,
                ),
                if (widget.student.lastWorkoutDate != null)
                  InfoRow(
                    label: 'Último Treino',
                    value: '${widget.student.daysSinceLastWorkout} dia(s) atrás',
                    icon: Icons.update,
                    valueColor: widget.student.daysSinceLastWorkout! > 7
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Editar treino')),
              );
            },
            child: widget.student.currentWorkoutId != null
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver histórico completo')),
              );
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
        amount: widget.student.monthlyFee ?? 250.00,
        paid: false,
        reference: 'Maio/2024',
      ),
      PaymentHistoryItem(
        date: DateTime(2024, 4, 1),
        amount: widget.student.monthlyFee ?? 250.00,
        paid: true,
        reference: 'Abril/2024',
      ),
      PaymentHistoryItem(
        date: DateTime(2024, 3, 1),
        amount: widget.student.monthlyFee ?? 250.00,
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
                  value: widget.student.monthlyFee != null
                      ? currencyFormat.format(widget.student.monthlyFee)
                      : 'Não definida',
                  icon: Icons.attach_money,
                  valueColor: AppColors.success,
                ),
                if (widget.student.nextPaymentDate != null)
                  InfoRow(
                    label: 'Próximo Vencimento',
                    value: DateFormat('dd/MM/yyyy').format(widget.student.nextPaymentDate!),
                    icon: Icons.event,
                    valueColor: widget.student.isPaymentOverdue
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                InfoRow(
                  label: 'Status',
                  value: widget.student.paymentStatus.displayName,
                  icon: Icons.info_outline,
                  valueColor: _getPaymentStatusColor(widget.student.paymentStatus),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ver histórico completo')),
              );
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
          color: Colors.black.withOpacity(0.1),
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
                    student: widget.student,
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registrar avaliação')),
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
    final duration = DateTime.now().difference(widget.student.enrollmentDate);
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