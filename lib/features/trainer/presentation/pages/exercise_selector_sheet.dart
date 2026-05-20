import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/exercise_entity.dart';
import '../providers/exercises_provider.dart';
import '../widgets/exercise_selector_card.dart';

/// Bottom Sheet para selecionar exercícios
class ExerciseSelectorSheet extends ConsumerStatefulWidget {
  final Function(ExerciseEntity) onExerciseSelected;

  const ExerciseSelectorSheet({
    super.key,
    required this.onExerciseSelected,
  });

  @override
  ConsumerState<ExerciseSelectorSheet> createState() =>
      _ExerciseSelectorSheetState();
}

class _ExerciseSelectorSheetState extends ConsumerState<ExerciseSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  List<ExerciseEntity> _filteredExercises = [];

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
    _updateFilteredExercises();
  }

  void _updateFilteredExercises() {
    final exercisesNotifier = ref.read(exercisesProvider.notifier);
    setState(() {
      _filteredExercises = exercisesNotifier.search(
        _searchController.text,
        category: _selectedCategory,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesProvider);

    if (_filteredExercises.isEmpty && !exercisesState.isLoading) {
      _filteredExercises = exercisesState.exercises;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Cabeçalho
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selecionar Exercício',
                    style: AppTextStyles.headlineMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Buscar exercício...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filtro de categorias
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildCategoryChip('Todos', null),
                ...ExerciseCategory.all.map(
                  (category) => _buildCategoryChip(category, category),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de exercícios
          Expanded(
            child: exercisesState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : _filteredExercises.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          return ExerciseSelectorCard(
                            exercise: exercise,
                            onTap: () {
                              widget.onExerciseSelected(exercise);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = category;
          });
          _updateFilteredExercises();
        },
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
        selectedColor: AppColors.teal,
        backgroundColor: AppColors.surface,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum exercício encontrado',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}