import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
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
import '../widgets/student_workouts_section.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../finance/data/payment_repository.dart';
import '../../../finance/presentation/widgets/payment_actions.dart';
import 'create_workout_page.dart';
import 'add_student_page.dart';
import 'physical_assessment_page.dart';
import '../providers/trainer_provider.dart';
import '../../../invite/presentation/widgets/invite_share_sheet.dart';
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

  bool get _isSuspended => _currentStudent.linkStatus == LinkStatus.suspended;

  Future<void> _toggleSuspension() async {
    final suspend = !_isSuspended;
    try {
      await ref
          .read(trainerDashboardProvider.notifier)
          .setSuspended(_currentStudent, suspend);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(suspend
            ? 'Acesso de ${_currentStudent.name} suspenso.'
            : 'Acesso de ${_currentStudent.name} reativado.'),
        backgroundColor: AppColors.success,
      ));
    } on FirebaseException catch (e) {
      _showError('Erro: ${e.message}');
    }
  }

  Future<void> _confirmDelete() async {
    // Espera o menu fechar antes de abrir o diálogo.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Excluir aluno', style: AppTextStyles.headlineSmall),
        content: Text(
          'Isso apaga ${_currentStudent.name} e TODOS os dados dele '
          '(treinos, histórico, avaliações). Não dá para desfazer.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(trainerDashboardProvider.notifier)
          .deleteStudent(_currentStudent);
      navigator.pop();
    } on FirebaseFunctionsException catch (e) {
      _showError(e.message ?? 'Erro ao excluir.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
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
        if (!_currentStudent.hasAccount &&
            _currentStudent.linkStatus != LinkStatus.archived)
          IconButton(
            tooltip: 'Enviar convite',
            icon: const Icon(Icons.send_to_mobile, color: AppColors.lightTeal),
            onPressed: () => showInviteShareSheet(context, _currentStudent),
          ),
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
              onTap: _toggleSuspension,
              child: Row(
                children: [
                  Icon(
                    _isSuspended ? Icons.lock_open : Icons.block,
                    color: _isSuspended ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(_isSuspended ? 'Reativar' : 'Suspender',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: _confirmDelete,
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Text('Excluir', style: AppTextStyles.bodyMedium),
                ],
              ),
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
    // Treinos realizados pelo aluno (Firestore, tempo real)
    final sessions =
        ref.watch(studentSessionsProvider(_currentStudent.id)).value ?? const [];
    final workoutHistory = [
      for (final session in sessions)
        WorkoutHistoryItem(
          workoutName:
              session.divisionName ?? session.workoutName ?? 'Treino',
          date: session.startTime,
          duration: session.duration.inMinutes,
          // Concluído = finalizou com todos os exercícios feitos.
          completed: session.completed && session.completionPercentage >= 100,
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Treino atual e anteriores (Firestore)
          StudentWorkoutsSection(student: _currentStudent),
          const SizedBox(height: 16),

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
    final s = _currentStudent;
    final status = s.effectivePaymentStatus;
    final paymentsAsync = ref.watch(linkPaymentsProvider(s.id));

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
                  value: s.monthlyFee != null
                      ? currencyFormat.format(s.monthlyFee)
                      : 'Não definida',
                  icon: Icons.attach_money,
                  valueColor: AppColors.success,
                ),
                InfoRow(
                  label: 'Plano',
                  value: s.planMonths == 1
                      ? (s.planType ?? 'Mensal')
                      : '${s.planType} (${s.planMonths} meses por pagamento)',
                  icon: Icons.card_membership,
                ),
                InfoRow(
                  label: 'Próximo Vencimento',
                  value: s.nextPaymentDate != null
                      ? DateFormat('dd/MM/yyyy').format(s.nextPaymentDate!)
                      : 'Não definido',
                  icon: Icons.event,
                  valueColor: paymentStatusColor(status),
                ),
                InfoRow(
                  label: 'Situação',
                  value: status == PaymentStatus.exempt
                      ? 'Isento'
                      : '${status.displayName} · ${dueLabel(s)}',
                  icon: Icons.info_outline,
                  valueColor: paymentStatusColor(status),
                ),
                if (status != PaymentStatus.exempt) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.surfaceLight),
                          ),
                          onPressed: () => chargeOnWhatsApp(context, s,
                              trainerName: ref.read(authProvider).user?.name),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Cobrar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => showRegisterPaymentSheet(context, s),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Registrar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Histórico de Pagamentos
          SectionCard(
            title: 'Histórico de Pagamentos',
            icon: Icons.receipt_long,
            child: paymentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.teal)),
              ),
              error: (e, _) => Text('Erro ao carregar pagamentos: $e',
                  style: const TextStyle(color: AppColors.error)),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nenhum pagamento registrado ainda.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : Column(
                      children: [
                        for (final p in list)
                          PaymentTile(
                            payment: p,
                            onDelete: () =>
                                confirmDeletePayment(context, ref, p, s),
                          ),
                      ],
                    ),
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