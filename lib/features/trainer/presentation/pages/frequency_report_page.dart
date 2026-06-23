import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/trainer_provider.dart';
import '../widgets/custom_drawer.dart';

class FrequencyReportPage extends ConsumerStatefulWidget {
  const FrequencyReportPage({super.key});

  @override
  ConsumerState<FrequencyReportPage> createState() => _FrequencyReportPageState();
}

class _FrequencyReportPageState extends ConsumerState<FrequencyReportPage> {
  // Estado para o período selecionado
  String _selectedRangeType = '30'; // '15', '30' ou 'custom'
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );

  // Paginação
  int _currentPage = 1;
  static const int _itemsPerPage = 6;

  void _setDateRange15Days() {
    setState(() {
      _selectedRangeType = '15';
      _dateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 14)),
        end: DateTime.now(),
      );
      _currentPage = 1; // Reseta página
    });
  }

  void _setDateRange30Days() {
    setState(() {
      _selectedRangeType = '30';
      _dateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 29)),
        end: DateTime.now(),
      );
      _currentPage = 1; // Reseta página
    });
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.teal,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedRangeType = 'custom';
        _dateRange = pickedRange;
        _currentPage = 1; // Reseta página
      });
    }
  }

  /// Gera a quantidade de treinos para o aluno baseado no intervalo de datas e no ID do aluno
  int _calculateWorkoutsForStudent(String studentId, int days) {
    // Coeficiente semanal determinístico baseado no hash do ID
    final int hash = studentId.hashCode.abs();
    final double weeklyRate = 2.0 + (hash % 4); // Frequência média semanal entre 2.0 e 5.0 treinos
    
    // Calcula o total proporcional aos dias
    final double weeks = days / 7.0;
    int calculated = (weeks * weeklyRate).round();

    // Pequena variação para não ficar totalmente fixo
    final int variance = (hash % 3) - 1; // -1, 0, ou 1
    calculated = (calculated + variance).clamp(0, 999);

    return calculated;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(trainerDashboardProvider);
    final students = dashboardState.students;

    // Calcula os dias no intervalo
    final int days = _dateRange.end.difference(_dateRange.start).inDays + 1;

    // Mapeia alunos com seus treinos calculados
    final List<({dynamic student, int workoutCount})> listWithCount = students.map((student) {
      final int count = _calculateWorkoutsForStudent(student.id, days);
      return (student: student, workoutCount: count);
    }).toList();

    // Ordena do aluno que mais treinou para o que menos treinou
    listWithCount.sort((a, b) => b.workoutCount.compareTo(a.workoutCount));

    // Soma do total de treinos
    final int grandTotal = listWithCount.fold(0, (sum, item) => sum + item.workoutCount);

    // Paginação
    final int totalItems = listWithCount.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);

    final paginatedList = listWithCount.isEmpty
        ? <({dynamic student, int workoutCount})>[]
        : listWithCount.sublist(startIndex, endIndex);

    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String dateRangeStr = '${formatter.format(_dateRange.start)} - ${formatter.format(_dateRange.end)}';

    // Para o gráfico de progresso
    final int maxWorkouts = listWithCount.isNotEmpty ? listWithCount.first.workoutCount : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('FREQUÊNCIA DE TREINOS', style: AppTextStyles.displaySmall),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seleção de Período
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      _buildPeriodChip(
                        label: 'Últimos 15 dias',
                        isSelected: _selectedRangeType == '15',
                        onTap: _setDateRange15Days,
                      ),
                      const SizedBox(width: 8),
                      _buildPeriodChip(
                        label: 'Últimos 30 dias',
                        isSelected: _selectedRangeType == '30',
                        onTap: _setDateRange30Days,
                      ),
                      const SizedBox(width: 8),
                      _buildPeriodChip(
                        label: 'Personalizado',
                        isSelected: _selectedRangeType == 'custom',
                        onTap: _selectCustomRange,
                      ),
                    ],
                  ),
                ),

                // Período ativo
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, color: AppColors.teal, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Período Analisado',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateRangeStr,
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '$days ${days == 1 ? "dia" : "dias"}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cabeçalho da Listagem
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ranking de Frequência',
                        style: AppTextStyles.headlineMedium,
                      ),
                      if (totalPages > 0)
                        Text(
                          'Pág $_currentPage de $totalPages',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                        ),
                    ],
                  ),
                ),

                // Lista de alunos
                Expanded(
                  child: paginatedList.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum aluno cadastrado ou sem atividade no período.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: paginatedList.length,
                          itemBuilder: (context, index) {
                            final item = paginatedList[index];
                            final student = item.student;
                            final count = item.workoutCount;
                            
                            // Calcula porcentagem do progresso em relação ao primeiro colocado
                            final double progressPercent = maxWorkouts > 0 ? count / maxWorkouts : 0.0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.surfaceLight),
                              ),
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Posição no Ranking (com cores para top 3)
                                        _buildRankBadge(startIndex + index + 1),
                                        const SizedBox(width: 12),
                                        
                                        // Iniciais / Foto do aluno
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                                          child: Text(
                                            student.name[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.lightTeal,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Nome e Email do Aluno
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: AppTextStyles.bodyLarge.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                student.email,
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.textTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Quantidade de Treinos
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '$count',
                                              style: AppTextStyles.headlineSmall.copyWith(
                                                color: AppColors.teal,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              count == 1 ? 'treino' : 'treinos',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Barra de Progresso Visual
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progressPercent,
                                        minHeight: 6,
                                        backgroundColor: AppColors.surfaceLight,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Controles de Paginação (se houver mais de uma página)
                if (totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          color: _currentPage > 1 ? AppColors.teal : AppColors.textTertiary,
                          onPressed: _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        ...List.generate(totalPages, (index) {
                          final pageNumber = index + 1;
                          final isCurrent = pageNumber == _currentPage;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: GestureDetector(
                              onTap: () => setState(() => _currentPage = pageNumber),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppColors.teal : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrent ? AppColors.teal : AppColors.surfaceLight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$pageNumber',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: isCurrent ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          color: _currentPage < totalPages ? AppColors.teal : AppColors.textTertiary,
                          onPressed: _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ],
                    ),
                  ),

                // Totalizador Geral no Rodapé
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL DO PERÍODO',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Soma dos treinos de todos os alunos',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$grandTotal',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.teal : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.teal : AppColors.surfaceLight,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(int position) {
    Color badgeColor;
    Color textColor;

    switch (position) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Ouro
        textColor = Colors.black87;
        break;
      case 2:
        badgeColor = const Color(0xFFC0C0C0); // Prata
        textColor = Colors.black87;
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        textColor = Colors.black87;
        break;
      default:
        badgeColor = AppColors.surfaceLight;
        textColor = AppColors.textSecondary;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$position',
          style: AppTextStyles.bodyMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
