import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../../trainer/domain/entities/student_entity.dart';
import '../../domain/entities/diet_entity.dart';
import '../../domain/entities/meal_entity.dart';
import '../providers/diet_provider.dart';
import '../widgets/meal_card.dart';
import '../widgets/food_item_card.dart';
import '../widgets/macros_chart.dart';

/// Tela de criação de dieta (Professor)
class CreateDietPage extends ConsumerStatefulWidget {
  final StudentEntity student;
  final DietEntity? initialDiet;

  const CreateDietPage({
    super.key,
    required this.student,
    this.initialDiet,
  });

  @override
  ConsumerState<CreateDietPage> createState() => _CreateDietPageState();
}

class _CreateDietPageState extends ConsumerState<CreateDietPage> {
  final _formKey = GlobalKey<FormState>();
  final _dietNameController = TextEditingController();
  final _dietDescriptionController = TextEditingController();
  final _targetCaloriesController = TextEditingController();
  final _targetProteinController = TextEditingController();
  final _targetCarbsController = TextEditingController();
  final _targetFatsController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDiet != null) {
      _dietNameController.text = widget.initialDiet!.name;
      _dietDescriptionController.text = widget.initialDiet!.description ?? '';
      _targetCaloriesController.text = widget.initialDiet!.targetCalories?.toStringAsFixed(0) ?? '';
      _targetProteinController.text = widget.initialDiet!.targetProtein?.toStringAsFixed(0) ?? '';
      _targetCarbsController.text = widget.initialDiet!.targetCarbs?.toStringAsFixed(0) ?? '';
      _targetFatsController.text = widget.initialDiet!.targetFats?.toStringAsFixed(0) ?? '';
    }
    // Reseta/inicializa o construtor ao entrar
    Future.microtask(() {
      if (widget.initialDiet != null) {
        ref.read(dietProvider.notifier).startDietBuilderFrom(widget.initialDiet!);
      } else {
        ref.read(dietProvider.notifier).startDietBuilder();
      }
    });
  }

  @override
  void dispose() {
    _dietNameController.dispose();
    _dietDescriptionController.dispose();
    _targetCaloriesController.dispose();
    _targetProteinController.dispose();
    _targetCarbsController.dispose();
    _targetFatsController.dispose();
    super.dispose();
  }

  void _showAddMealDialog() {
    final mealNameController = TextEditingController();
    final mealTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Nova Refeição', style: AppTextStyles.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Nome da Refeição',
              hint: 'Ex: Café da Manhã, Almoço...',
              controller: mealNameController,
              prefixIcon: Icons.restaurant,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Horário',
              hint: 'Ex: 07:00',
              controller: mealTimeController,
              prefixIcon: Icons.access_time,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (mealNameController.text.isNotEmpty &&
                  mealTimeController.text.isNotEmpty) {
                ref.read(dietProvider.notifier).addMeal(
                      mealNameController.text,
                      mealTimeController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: Text(
              'Adicionar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodDialog(int mealIndex) {
    final foodNameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController(text: 'g');
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Adicionar Alimento', style: AppTextStyles.headlineMedium),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nome do Alimento',
                hint: 'Ex: Arroz integral',
                controller: foodNameController,
                prefixIcon: Icons.food_bank,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Quantidade',
                      hint: 'Ex: 150',
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.scale,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Unidade',
                      hint: 'g',
                      controller: unitController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Macronutrientes',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Calorias (kcal)',
                controller: caloriesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.local_fire_department,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Proteínas (g)',
                controller: proteinController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.egg,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Carboidratos (g)',
                controller: carbsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.grain,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Gorduras (g)',
                controller: fatsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.opacity,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Observações (Opcional)',
                hint: 'Ex: Pode substituir por batata doce',
                controller: notesController,
                maxLines: 2,
                prefixIcon: Icons.notes,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (foodNameController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty &&
                  caloriesController.text.isNotEmpty) {
                final food = FoodItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: foodNameController.text,
                  quantity: double.tryParse(quantityController.text) ?? 0,
                  unit: unitController.text,
                  calories: double.tryParse(caloriesController.text) ?? 0,
                  protein: double.tryParse(proteinController.text) ?? 0,
                  carbs: double.tryParse(carbsController.text) ?? 0,
                  fats: double.tryParse(fatsController.text) ?? 0,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );

                ref.read(dietProvider.notifier).addFoodToMeal(mealIndex, food);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Adicionar',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMealFoodsDialog(int mealIndex, MealEntity meal) {
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
                        Text(meal.name, style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${meal.foods.length} alimento(s)',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
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
                            'Nenhum alimento adicionado',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        ...meal.foods.asMap().entries.map((entry) {
                          final foodIndex = entry.key;
                          final food = entry.value;
                          return FoodItemCard(
                            food: food,
                            onDelete: () {
                              ref.read(dietProvider.notifier).removeFoodFromMeal(
                                    mealIndex,
                                    foodIndex,
                                  );
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    ),
            ),

            // Botão adicionar alimento
            Padding(
              padding: const EdgeInsets.all(20),
              child: CustomButton(
                text: 'ADICIONAR ALIMENTO',
                onPressed: () {
                  Navigator.pop(context);
                  _showAddFoodDialog(mealIndex);
                },
                type: ButtonType.primary,
                icon: Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    // Valida nome
    if (_dietNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome da dieta'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dietState = ref.read(dietProvider);

    // Valida refeições
    if (dietState.meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma refeição'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await ref.read(dietProvider.notifier).saveDiet(
          studentId: widget.student.id,
          trainerId: 'trainer_123', // TODO: Pegar do usuário logado
          name: _dietNameController.text,
          description: _dietDescriptionController.text.isEmpty
              ? null
              : _dietDescriptionController.text,
          targetCalories: _targetCaloriesController.text.isEmpty
              ? null
              : double.tryParse(_targetCaloriesController.text),
          targetProtein: _targetProteinController.text.isEmpty
              ? null
              : double.tryParse(_targetProteinController.text),
          targetCarbs: _targetCarbsController.text.isEmpty
              ? null
              : double.tryParse(_targetCarbsController.text),
          targetFats: _targetFatsController.text.isEmpty
              ? null
              : double.tryParse(_targetFatsController.text),
        );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dieta criada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar dieta'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietState = ref.watch(dietProvider);
    final meals = dietState.meals;

    // Calcula totais
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (var meal in meals) {
      totalCalories += meal.totalCalories;
      totalProtein += meal.totalProtein;
      totalCarbs += meal.totalCarbs;
      totalFats += meal.totalFats;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Criar Dieta', style: AppTextStyles.headlineMedium),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check, color: AppColors.teal),
              label: Text(
                'Salvar',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.teal,
                ),
              ),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.teal,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informações do aluno
          _buildStudentHeader(),

          const SizedBox(height: 24),

          // Formulário da dieta
          _buildDietForm(),

          const SizedBox(height: 24),

          // Metas nutricionais
          _buildTargetsForm(),

          const SizedBox(height: 24),

          // Resumo atual
          if (meals.isNotEmpty) ...[
            MacrosChart(
              totalCalories: totalCalories,
              totalProtein: totalProtein,
              totalCarbs: totalCarbs,
              totalFats: totalFats,
              targetCalories: _targetCaloriesController.text.isEmpty
                  ? null
                  : double.tryParse(_targetCaloriesController.text),
              targetProtein: _targetProteinController.text.isEmpty
                  ? null
                  : double.tryParse(_targetProteinController.text),
              targetCarbs: _targetCarbsController.text.isEmpty
                  ? null
                  : double.tryParse(_targetCarbsController.text),
              targetFats: _targetFatsController.text.isEmpty
                  ? null
                  : double.tryParse(_targetFatsController.text),
            ),
            const SizedBox(height: 24),
          ],

          // Título das refeições
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Refeições',
                style: AppTextStyles.headlineMedium,
              ),
              TextButton.icon(
                onPressed: _showAddMealDialog,
                icon: const Icon(Icons.add, color: AppColors.teal),
                label: Text(
                  'Adicionar',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista de refeições
          if (meals.isEmpty)
            _buildEmptyMeals()
          else
            ...meals.asMap().entries.map((entry) {
              final index = entry.key;
              final meal = entry.value;
              return MealCard(
                meal: meal,
                isEditable: true,
                onTap: () => _showMealFoodsDialog(index, meal),
                onDelete: () {
                  ref.read(dietProvider.notifier).removeMeal(index);
                },
              );
            }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Center(
              child: Text(
                widget.student.name.split(' ').take(2).map((w) => w[0]).join(),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Criando dieta para:',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  widget.student.name,
                  style: AppTextStyles.headlineSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Nome da Dieta',
            hint: 'Ex: Dieta Hipertrofia - 3000 kcal',
            controller: _dietNameController,
            prefixIcon: Icons.restaurant_menu,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Descrição (Opcional)',
            hint: 'Ex: Dieta focada em ganho de massa muscular',
            controller: _dietDescriptionController,
            maxLines: 2,
            prefixIcon: Icons.description,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsForm() {
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
          Text(
            'Metas Nutricionais Diárias (Opcional)',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Calorias (kcal)',
            hint: 'Ex: 3000',
            controller: _targetCaloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.local_fire_department,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Proteínas (g)',
                  hint: 'Ex: 180',
                  controller: _targetProteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Carbs (g)',
                  hint: 'Ex: 375',
                  controller: _targetCarbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Gorduras (g)',
                  hint: 'Ex: 83',
                  controller: _targetFatsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeals() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.restaurant,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma refeição adicionada',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em "Adicionar" para criar',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}