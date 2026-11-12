import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import 'package:time_lobao/features/nutrition/domain/entities/meal_entity.dart';
import 'package:time_lobao/features/nutrition/presentation/providers/diet_library_provider.dart';
import 'package:time_lobao/features/nutrition/presentation/providers/diet_provider.dart';
import 'package:time_lobao/features/nutrition/presentation/widgets/macros_chart.dart';
import 'package:time_lobao/features/nutrition/presentation/widgets/meal_card.dart';
import 'package:time_lobao/features/nutrition/presentation/widgets/food_item_card.dart';

/// Tela da Biblioteca de Dietas do Professor
///
/// Permite ao professor:
/// - Visualizar todos os templates criados, com filtro por categoria
/// - Criar novos templates para a biblioteca
/// - Editar templates existentes
/// - Excluir templates
///
/// Os templates desta biblioteca podem ser importados
/// ao prescrever uma dieta para um aluno.
class DietLibraryPage extends ConsumerStatefulWidget {
  const DietLibraryPage({super.key});

  @override
  ConsumerState<DietLibraryPage> createState() => _DietLibraryPageState();
}

class _DietLibraryPageState extends ConsumerState<DietLibraryPage> {
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(dietLibraryProvider);

    final allCategories = ['Todos', ...libraryState.categories];

    final filtered = _selectedCategory == 'Todos'
        ? libraryState.templates
        : libraryState.templates
            .where((t) => t.category == _selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('BIBLIOTECA DE DIETAS', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTemplateEditor(context, template: null),
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'NOVO TEMPLATE',
          style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
        ),
      ),
      body: libraryState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contador
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    '${libraryState.templates.length} dieta(s) na biblioteca',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

                // Filtros por categoria
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: allCategories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = category);
                            }
                          },
                          selectedColor: AppColors.teal,
                          backgroundColor: AppColors.surface,
                          labelStyle: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.teal
                                  : AppColors.surfaceLight,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Lista de templates
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _TemplateCard(
                              template: filtered[index],
                              onEdit: () => _openTemplateEditor(
                                context,
                                template: filtered[index],
                              ),
                              onDelete: () => _confirmDelete(
                                context,
                                filtered[index],
                              ),
                              onView: () => _openTemplateViewer(
                                context,
                                filtered[index],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 72,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 20),
          Text(
            _selectedCategory == 'Todos'
                ? 'Biblioteca vazia'
                : 'Nenhuma dieta em "$_selectedCategory"',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Toque em "Novo Template" para criar\nsua primeira dieta modelo.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Visualizador ────────────────────────────────────────────────────────

  void _openTemplateViewer(BuildContext context, DietTemplateModel template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateViewerSheet(template: template),
    );
  }

  // ─── Editor ──────────────────────────────────────────────────────────────

  void _openTemplateEditor(
    BuildContext context, {
    required DietTemplateModel? template,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TemplateEditorPage(existingTemplate: template),
      ),
    );
  }

  // ─── Excluir ─────────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, DietTemplateModel template) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Excluir template?', style: AppTextStyles.headlineMedium),
        content: Text(
          'O template "${template.name}" será removido da biblioteca permanentemente.',
          style: AppTextStyles.bodyMedium,
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
              ref
                  .read(dietLibraryProvider.notifier)
                  .deleteTemplate(template.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template "${template.name}" excluído.'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: Text(
              'Excluir',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card do template ─────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final DietTemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(template.category);

    return GestureDetector(
      onTap: onView,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                // Badge de categoria
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: categoryColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    template.category.toUpperCase(),
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Calorias
                Text(
                  '${template.totalCalories.toStringAsFixed(0)} kcal',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: 14,
                    color: AppColors.lightTeal,
                  ),
                ),
                const SizedBox(width: 8),
                // Menu de ações
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  color: AppColors.surface,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18, color: AppColors.teal),
                          const SizedBox(width: 12),
                          Text('Editar', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(
                            'Excluir',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text(template.name, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 6),
            Text(
              template.description,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Macros
            Row(
              children: [
                _macroChip('P', '${template.totalProtein.toStringAsFixed(0)}g', AppColors.teal),
                const SizedBox(width: 8),
                _macroChip('C', '${template.totalCarbs.toStringAsFixed(0)}g', AppColors.success),
                const SizedBox(width: 8),
                _macroChip('G', '${template.totalFats.toStringAsFixed(0)}g', AppColors.warning),
                const Spacer(),
                // Qtde de refeições
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${template.meals.length} refeição(ões)',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Linha de data
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  template.updatedAt != null
                      ? 'Atualizado em ${DateFormat('dd/MM/yyyy').format(template.updatedAt!)}'
                      : 'Criado em ${DateFormat('dd/MM/yyyy').format(template.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
                const Spacer(),
                // Atalho para editar
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit, size: 13, color: AppColors.lightTeal),
                        const SizedBox(width: 4),
                        Text(
                          'Editar',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.lightTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Hipertrofia':
        return AppColors.teal;
      case 'Emagrecimento':
        return AppColors.error;
      case 'Definição':
        return AppColors.warning;
      case 'Saúde':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }
}

// ─── Bottom sheet de visualização completa do template ────────────────────

class _TemplateViewerSheet extends ConsumerWidget {
  final DietTemplateModel template;

  const _TemplateViewerSheet({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name, style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        template.category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.lightTeal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Descrição
                if (template.description.isNotEmpty) ...[
                  Text(
                    template.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Resumo nutricional
                MacrosChart(
                  totalCalories: template.totalCalories,
                  totalProtein: template.totalProtein,
                  totalCarbs: template.totalCarbs,
                  totalFats: template.totalFats,
                  targetCalories: template.targetCalories,
                  targetProtein: template.targetProtein,
                  targetCarbs: template.targetCarbs,
                  targetFats: template.targetFats,
                ),

                const SizedBox(height: 20),

                Text('Refeições', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 12),

                // Cards de refeição (apenas visualização)
                ...template.meals.map(
                  (meal) => _MealViewCard(meal: meal),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealViewCard extends StatelessWidget {
  final MealEntity meal;

  const _MealViewCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 15, color: AppColors.lightTeal),
              const SizedBox(width: 6),
              Text(
                '${meal.name}  •  ${meal.time}',
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 15),
              ),
            ],
          ),
          if (meal.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              meal.notes!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...meal.foods.map(
            (food) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FoodItemCard(food: food),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${meal.totalCalories.toStringAsFixed(0)} kcal  |  P ${meal.totalProtein.toStringAsFixed(0)}g  C ${meal.totalCarbs.toStringAsFixed(0)}g  G ${meal.totalFats.toStringAsFixed(0)}g',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Página de edição/criação de template ────────────────────────────────

class _TemplateEditorPage extends ConsumerStatefulWidget {
  final DietTemplateModel? existingTemplate;

  const _TemplateEditorPage({this.existingTemplate});

  @override
  ConsumerState<_TemplateEditorPage> createState() =>
      _TemplateEditorPageState();
}

class _TemplateEditorPageState extends ConsumerState<_TemplateEditorPage> {
  final _uuid = const Uuid();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetCaloriesController = TextEditingController();
  final _targetProteinController = TextEditingController();
  final _targetCarbsController = TextEditingController();
  final _targetFatsController = TextEditingController();
  String _selectedCategory = 'Hipertrofia';
  bool _isSaving = false;

  final _categories = [
    'Hipertrofia',
    'Emagrecimento',
    'Definição',
    'Saúde',
    'Manutenção',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.existingTemplate;
    if (t != null) {
      _nameController.text = t.name;
      _descriptionController.text = t.description;
      _selectedCategory = t.category;
      _targetCaloriesController.text =
          t.targetCalories?.toStringAsFixed(0) ?? '';
      _targetProteinController.text =
          t.targetProtein?.toStringAsFixed(0) ?? '';
      _targetCarbsController.text = t.targetCarbs?.toStringAsFixed(0) ?? '';
      _targetFatsController.text = t.targetFats?.toStringAsFixed(0) ?? '';
    }

    Future.microtask(() {
      if (t != null) {
        ref.read(dietProvider.notifier).loadMeals(t.meals);
      } else {
        ref.read(dietProvider.notifier).startDietBuilder();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
              style: AppTextStyles.buttonMedium
                  .copyWith(color: AppColors.textSecondary),
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
              style: AppTextStyles.buttonMedium
                  .copyWith(color: AppColors.teal),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Quantidade',
                      hint: '150',
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
              const SizedBox(height: 12),
              CustomTextField(label: 'Calorias (kcal)', controller: caloriesController, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefixIcon: Icons.local_fire_department),
              const SizedBox(height: 12),
              CustomTextField(label: 'Proteínas (g)', controller: proteinController, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefixIcon: Icons.egg),
              const SizedBox(height: 12),
              CustomTextField(label: 'Carboidratos (g)', controller: carbsController, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefixIcon: Icons.grain),
              const SizedBox(height: 12),
              CustomTextField(label: 'Gorduras (g)', controller: fatsController, keyboardType: const TextInputType.numberWithOptions(decimal: true), prefixIcon: Icons.opacity),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (foodNameController.text.isNotEmpty && quantityController.text.isNotEmpty && caloriesController.text.isNotEmpty) {
                final food = FoodItem(
                  id: _uuid.v4(),
                  name: foodNameController.text,
                  quantity: double.tryParse(quantityController.text) ?? 0,
                  unit: unitController.text,
                  calories: double.tryParse(caloriesController.text) ?? 0,
                  protein: double.tryParse(proteinController.text) ?? 0,
                  carbs: double.tryParse(carbsController.text) ?? 0,
                  fats: double.tryParse(fatsController.text) ?? 0,
                );
                ref.read(dietProvider.notifier).addFoodToMeal(mealIndex, food);
                Navigator.pop(context);
              }
            },
            child: Text('Adicionar', style: AppTextStyles.buttonMedium.copyWith(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  void _showMealFoodsSheet(int mealIndex, MealEntity meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(meal.name, style: AppTextStyles.headlineMedium),
                        Text(
                          '${meal.foods.length} alimento(s)',
                          style: AppTextStyles.bodySmall,
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
                      child: Text(
                        'Nenhum alimento adicionado',
                        style: AppTextStyles.bodyMedium,
                      ),
                    )
                  : Consumer(
                      builder: (context, ref, _) {
                        final meals = ref.watch(dietProvider).meals;
                        final updatedMeal = mealIndex < meals.length
                            ? meals[mealIndex]
                            : meal;
                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: updatedMeal.foods
                              .asMap()
                              .entries
                              .map(
                                (entry) => FoodItemCard(
                                  food: entry.value,
                                  onDelete: () {
                                    ref
                                        .read(dietProvider.notifier)
                                        .removeFoodFromMeal(
                                          mealIndex,
                                          entry.key,
                                        );
                                  },
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
            ),
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
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome do template.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final meals = ref.read(dietProvider).meals;
    if (meals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma refeição.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final notifier = ref.read(dietLibraryProvider.notifier);
    final existing = widget.existingTemplate;

    if (existing != null) {
      notifier.updateTemplate(
        existing.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          meals: meals,
          targetCalories: double.tryParse(_targetCaloriesController.text),
          targetProtein: double.tryParse(_targetProteinController.text),
          targetCarbs: double.tryParse(_targetCarbsController.text),
          targetFats: double.tryParse(_targetFatsController.text),
        ),
      );
    } else {
      notifier.addTemplate(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        meals: meals,
        targetCalories: double.tryParse(_targetCaloriesController.text),
        targetProtein: double.tryParse(_targetProteinController.text),
        targetCarbs: double.tryParse(_targetCarbsController.text),
        targetFats: double.tryParse(_targetFatsController.text),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null
              ? 'Template atualizado com sucesso!'
              : 'Template criado e adicionado à biblioteca!',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dietState = ref.watch(dietProvider);
    final meals = dietState.meals;

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    for (final m in meals) {
      totalCalories += m.totalCalories;
      totalProtein += m.totalProtein;
      totalCarbs += m.totalCarbs;
      totalFats += m.totalFats;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.existingTemplate != null
              ? 'EDITAR TEMPLATE'
              : 'NOVO TEMPLATE',
          style: AppTextStyles.displaySmall,
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.teal,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check, color: AppColors.teal),
              label: Text(
                'Salvar',
                style: AppTextStyles.buttonMedium.copyWith(color: AppColors.teal),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Informações básicas
          CustomTextField(
            label: 'Nome do Template',
            hint: 'Ex: Bulk Limpo – Hipertrofia',
            controller: _nameController,
            prefixIcon: Icons.restaurant_menu,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Descrição',
            hint: 'Ex: Dieta hipercalórica focada em ganho de massa...',
            controller: _descriptionController,
            maxLines: 2,
            prefixIcon: Icons.description,
          ),
          const SizedBox(height: 16),

          // Categoria
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finalidade / Categoria', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (v) {
                        if (v) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: AppColors.teal,
                      backgroundColor: AppColors.surfaceLight,
                      labelStyle: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? AppColors.teal : Colors.transparent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Metas nutricionais
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Metas Nutricionais (Opcional)', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Calorias alvo (kcal)',
                  controller: _targetCaloriesController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.local_fire_department,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Proteínas (g)',
                        controller: _targetProteinController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        label: 'Carbs (g)',
                        controller: _targetCarbsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        label: 'Gorduras (g)',
                        controller: _targetFatsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Resumo nutricional das refeições já adicionadas
          if (meals.isNotEmpty) ...[
            MacrosChart(
              totalCalories: totalCalories,
              totalProtein: totalProtein,
              totalCarbs: totalCarbs,
              totalFats: totalFats,
              targetCalories: double.tryParse(_targetCaloriesController.text),
              targetProtein: double.tryParse(_targetProteinController.text),
              targetCarbs: double.tryParse(_targetCarbsController.text),
              targetFats: double.tryParse(_targetFatsController.text),
            ),
            const SizedBox(height: 20),
          ],

          // Refeições
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Refeições', style: AppTextStyles.headlineMedium),
              TextButton.icon(
                onPressed: _showAddMealDialog,
                icon: const Icon(Icons.add, color: AppColors.teal),
                label: Text(
                  'Adicionar',
                  style: AppTextStyles.buttonMedium.copyWith(color: AppColors.teal),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (meals.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.restaurant, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma refeição adicionada',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...meals.asMap().entries.map((entry) {
              final index = entry.key;
              final meal = entry.value;
              return MealCard(
                meal: meal,
                isEditable: true,
                onTap: () => _showMealFoodsSheet(index, meal),
                onDelete: () => ref.read(dietProvider.notifier).removeMeal(index),
              );
            }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

