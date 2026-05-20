import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/diet_provider.dart';
import '../widgets/meal_card.dart';
import '../widgets/food_item_card.dart';
import '../widgets/macros_chart.dart';

/// Tela de visualização de dieta (Aluno)
class DietViewPage extends ConsumerStatefulWidget {
  final String studentId;

  const DietViewPage({
    super.key,
    required this.studentId,
  });

  @override
  ConsumerState<DietViewPage> createState() => _DietViewPageState();
}

class _DietViewPageState extends ConsumerState<DietViewPage> {
  @override
  void initState() {
    super.initState();
    // Carrega dieta ao iniciar
    Future.microtask(() {
      ref.read(dietProvider.notifier).loadDiet(widget.studentId);
    });
  }

  void _showMealDetails(meal) {
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

            // Lista de alimentos
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...meal.foods.map((food) => FoodItemCard(food: food)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dietState = ref.watch(dietProvider);
    final diet = dietState.currentDiet;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Minha Dieta', style: AppTextStyles.headlineMedium),
      ),
      body: dietState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : diet == null
              ? _buildNoDiet()
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(dietProvider.notifier).loadDiet(widget.studentId);
                  },
                  color: AppColors.teal,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Informações da dieta
                      _buildDietInfo(diet),

                      const SizedBox(height: 24),

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

                      const SizedBox(height: 24),

                      // Título das refeições
                      Text(
                        'Suas Refeições',
                        style: AppTextStyles.headlineMedium,
                      ),

                      const SizedBox(height: 16),

                      // Lista de refeições
                      ...diet.meals.map((meal) {
                        return MealCard(
                          meal: meal,
                          onTap: () => _showMealDetails(meal),
                        );
                      }),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDietInfo(diet) {
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
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.success,
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
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${diet.totalMeals} refeições',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (diet.description != null && diet.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              diet.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDiet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma dieta prescrita',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aguarde seu professor prescrever\numa dieta para você',
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