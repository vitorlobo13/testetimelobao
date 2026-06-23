import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DietTemplate {
  final String title;
  final String description;
  final String category;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  const DietTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

/// Tela da Biblioteca de Dietas e Nutrição
class DietLibraryPage extends StatefulWidget {
  const DietLibraryPage({super.key});

  @override
  State<DietLibraryPage> createState() => _DietLibraryPageState();
}

class _DietLibraryPageState extends State<DietLibraryPage> {
  String _selectedCategory = 'Todos';

  final List<DietTemplate> _templates = const [
    DietTemplate(
      title: 'Bulk Limpo - Hipertrofia Masculina',
      description: 'Dieta hipercalórica focada em ganho de massa magra com mínimo acúmulo de gordura.',
      category: 'Hipertrofia',
      calories: 3200,
      protein: 180,
      carbs: 450,
      fats: 80,
    ),
    DietTemplate(
      title: 'Low Carb Funcional - Emagrecimento',
      description: 'Estrutura dietética focada em restrição moderada de carboidratos e gorduras saudáveis.',
      category: 'Emagrecimento',
      calories: 1800,
      protein: 140,
      carbs: 100,
      fats: 70,
    ),
    DietTemplate(
      title: 'Déficit Calórico Moderado - Definição',
      description: 'Indicado para manutenção de massa muscular enquanto reduz o percentual de gordura.',
      category: 'Definição',
      calories: 2200,
      protein: 160,
      carbs: 220,
      fats: 65,
    ),
    DietTemplate(
      title: 'Dieta Vegetariana Equilibrada',
      description: 'Plano nutricional baseado em proteínas vegetais, legumes e grãos integrais.',
      category: 'Saúde',
      calories: 2000,
      protein: 110,
      carbs: 250,
      fats: 60,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', 'Hipertrofia', 'Emagrecimento', 'Definição', 'Saúde'];

    final filteredTemplates = _selectedCategory == 'Todos'
        ? _templates
        : _templates.where((t) => t.category == _selectedCategory).toList();

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppColors.teal,
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppColors.teal : AppColors.surfaceLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Lista de Modelos
          Expanded(
            child: filteredTemplates.isEmpty
                ? const Center(
                    child: Text('Nenhuma dieta nesta categoria.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return _TemplateCard(template: template);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final DietTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  template.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${template.calories} kcal',
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 14, color: AppColors.lightTeal),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(template.title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 6),
          Text(
            template.description,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // Valores de Macros
          Row(
            children: [
              _buildMacroChip('P', '${template.protein}g', AppColors.teal),
              const SizedBox(width: 8),
              _buildMacroChip('C', '${template.carbs}g', AppColors.success),
              const SizedBox(width: 8),
              _buildMacroChip('G', '${template.fats}g', AppColors.warning),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Modelo "${template.title}" copiado para rascunhos.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.copy, size: 14, color: Colors.white),
                label: const Text(
                  'USAR DIETA',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
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
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
