import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';
import '../widgets/student_card.dart';
import 'student_detail_page.dart';



/// Tela de lista completa de alunos com filtros
class StudentsListPage extends ConsumerStatefulWidget {
  const StudentsListPage({super.key});

  @override
  ConsumerState<StudentsListPage> createState() => _StudentsListPageState();
}

class _StudentsListPageState extends ConsumerState<StudentsListPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filtros
  StudentStatus? _selectedStatus;
  PaymentStatus? _selectedPaymentStatus;
  SortOption _sortOption = SortOption.nameAsc;
  
  // Lista filtrada
  List<StudentEntity> _filteredStudents = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final dashboardState = ref.read(trainerDashboardProvider);
    var students = List<StudentEntity>.from(dashboardState.students);

    // Filtro de busca
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      students = students.where((student) {
        return student.name.toLowerCase().contains(searchTerm) ||
               student.email.toLowerCase().contains(searchTerm) ||
               (student.phone?.contains(searchTerm) ?? false);
      }).toList();
    }

    // Filtro de status
    if (_selectedStatus != null) {
      students = students.where((s) => s.status == _selectedStatus).toList();
    }

    // Filtro de pagamento
    if (_selectedPaymentStatus != null) {
      students = students
          .where((s) => s.paymentStatus == _selectedPaymentStatus)
          .toList();
    }

    // Ordenação
    switch (_sortOption) {
      case SortOption.nameAsc:
        students.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        students.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.dateAsc:
        students.sort((a, b) => a.enrollmentDate.compareTo(b.enrollmentDate));
        break;
      case SortOption.dateDesc:
        students.sort((a, b) => b.enrollmentDate.compareTo(a.enrollmentDate));
        break;
      case SortOption.paymentOverdue:
        students.sort((a, b) {
          if (a.isPaymentOverdue && !b.isPaymentOverdue) return -1;
          if (!a.isPaymentOverdue && b.isPaymentOverdue) return 1;
          return 0;
        });
        break;
    }

    setState(() {
      _filteredStudents = students;
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(trainerDashboardProvider.notifier).refresh();
    _applyFilters();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedStatus: _selectedStatus,
        selectedPaymentStatus: _selectedPaymentStatus,
        sortOption: _sortOption,
        onApply: (status, paymentStatus, sortOption) {
          setState(() {
            _selectedStatus = status;
            _selectedPaymentStatus = paymentStatus;
            _sortOption = sortOption;
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedStatus = null;
            _selectedPaymentStatus = null;
            _sortOption = SortOption.nameAsc;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(trainerDashboardProvider);

    // Aplica filtros quando os dados mudam
    if (_filteredStudents.isEmpty && dashboardState.students.isNotEmpty) {
      Future.microtask(() => _applyFilters());
    }

    final hasActiveFilters = _selectedStatus != null || 
                             _selectedPaymentStatus != null ||
                             _sortOption != SortOption.nameAsc;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Meus Alunos', style: AppTextStyles.headlineMedium),
        actions: [
          // Botão de filtro com indicador
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterBottomSheet,
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          _buildSearchBar(),

          // Chips de filtros ativos
          if (hasActiveFilters) _buildActiveFiltersChips(),

          // Contador
          _buildCounter(),

          // Lista de alunos
          Expanded(
            child: dashboardState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: AppColors.teal,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return StudentCard(
                              student: student,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailPage(student: student),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar novo aluno')),
          );
        },
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'Novo Aluno',
          style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Buscar por nome, email ou telefone...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedStatus != null)
            _buildFilterChip(
              label: 'Status: ${_selectedStatus!.displayName}',
              onDeleted: () {
                setState(() => _selectedStatus = null);
                _applyFilters();
              },
            ),
          if (_selectedPaymentStatus != null)
            _buildFilterChip(
              label: 'Pagamento: ${_selectedPaymentStatus!.displayName}',
              onDeleted: () {
                setState(() => _selectedPaymentStatus = null);
                _applyFilters();
              },
            ),
          if (_sortOption != SortOption.nameAsc)
            _buildFilterChip(
              label: 'Ordenação: ${_sortOption.displayName}',
              onDeleted: () {
                setState(() => _sortOption = SortOption.nameAsc);
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
        ),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 18),
        deleteIconColor: AppColors.textPrimary,
        backgroundColor: AppColors.teal.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.teal),
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_filteredStudents.length} aluno(s) encontrado(s)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    final hasFilters = _selectedStatus != null || _selectedPaymentStatus != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch || hasFilters
                  ? Icons.search_off
                  : Icons.people_outline,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch || hasFilters
                  ? 'Nenhum aluno encontrado'
                  : 'Você ainda não tem alunos',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch || hasFilters
                  ? 'Tente ajustar os filtros de busca'
                  : 'Adicione seu primeiro aluno para começar',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasSearch || hasFilters) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedStatus = null;
                    _selectedPaymentStatus = null;
                  });
                  _applyFilters();
                },
                child: Text(
                  'Limpar filtros',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opções de ordenação
enum SortOption {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
  paymentOverdue,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.nameAsc:
        return 'Nome (A-Z)';
      case SortOption.nameDesc:
        return 'Nome (Z-A)';
      case SortOption.dateAsc:
        return 'Data (Mais antigos)';
      case SortOption.dateDesc:
        return 'Data (Mais recentes)';
      case SortOption.paymentOverdue:
        return 'Pagamento atrasado';
    }
  }
}

/// Bottom Sheet de Filtros
class _FilterBottomSheet extends StatefulWidget {
  final StudentStatus? selectedStatus;
  final PaymentStatus? selectedPaymentStatus;
  final SortOption sortOption;
  final Function(StudentStatus?, PaymentStatus?, SortOption) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.selectedStatus,
    required this.selectedPaymentStatus,
    required this.sortOption,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late StudentStatus? _tempStatus;
  late PaymentStatus? _tempPaymentStatus;
  late SortOption _tempSortOption;

  @override
  void initState() {
    super.initState();
    _tempStatus = widget.selectedStatus;
    _tempPaymentStatus = widget.selectedPaymentStatus;
    _tempSortOption = widget.sortOption;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros e Ordenação',
                style: AppTextStyles.headlineMedium,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status do Aluno
          Text(
            'Status do Aluno',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Todos',
                selected: _tempStatus == null,
                onSelected: (_) => setState(() => _tempStatus = null),
              ),
              ...StudentStatus.values.map(
                (status) => _buildChoiceChip(
                  label: status.displayName,
                  selected: _tempStatus == status,
                  onSelected: (_) => setState(() => _tempStatus = status),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status de Pagamento
          Text(
            'Status de Pagamento',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip(
                label: 'Todos',
                selected: _tempPaymentStatus == null,
                onSelected: (_) => setState(() => _tempPaymentStatus = null),
              ),
              ...PaymentStatus.values.map(
                (status) => _buildChoiceChip(
                  label: status.displayName,
                  selected: _tempPaymentStatus == status,
                  onSelected: (_) => setState(() => _tempPaymentStatus = status),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Ordenação
          Text(
            'Ordenar por',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...SortOption.values.map(
            (option) => RadioListTile<SortOption>(
              title: Text(
                option.displayName,
                style: AppTextStyles.bodyMedium,
              ),
              value: option,
              groupValue: _tempSortOption,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tempSortOption = value);
                }
              },
              activeColor: AppColors.teal,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 24),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClear,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Limpar',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _tempStatus,
                      _tempPaymentStatus,
                      _tempSortOption,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Aplicar',
                    style: AppTextStyles.buttonMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.teal,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.teal : AppColors.surfaceLight,
        ),
      ),
    );
  }
}