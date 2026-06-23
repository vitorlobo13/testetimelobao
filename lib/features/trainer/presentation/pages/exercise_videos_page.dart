import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExerciseVideo {
  final String title;
  final String category;
  final String primaryMuscle;
  final String duration;
  final String difficulty;

  const ExerciseVideo({
    required this.title,
    required this.category,
    required this.primaryMuscle,
    required this.duration,
    required this.difficulty,
  });
}

/// Tela de Biblioteca de Vídeos de Exercícios (+1800 vídeos)
class ExerciseVideosPage extends StatefulWidget {
  const ExerciseVideosPage({super.key});

  @override
  State<ExerciseVideosPage> createState() => _ExerciseVideosPageState();
}

class _ExerciseVideosPageState extends State<ExerciseVideosPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  final List<ExerciseVideo> _videos = const [
    ExerciseVideo(
      title: 'Supino Reto com Barra',
      category: 'Peito',
      primaryMuscle: 'Peitoral Maior',
      duration: '0:45',
      difficulty: 'Intermediário',
    ),
    ExerciseVideo(
      title: 'Agachamento Livre com Barra',
      category: 'Pernas',
      primaryMuscle: 'Quadríceps',
      duration: '1:10',
      difficulty: 'Avançado',
    ),
    ExerciseVideo(
      title: 'Remada Curvada com Barra',
      category: 'Costas',
      primaryMuscle: 'Dorsais',
      duration: '0:55',
      difficulty: 'Intermediário',
    ),
    ExerciseVideo(
      title: 'Rosca Direta com Barra W',
      category: 'Braços',
      primaryMuscle: 'Bíceps Braquial',
      duration: '0:40',
      difficulty: 'Iniciante',
    ),
    ExerciseVideo(
      title: 'Elevação Lateral com Halteres',
      category: 'Ombros',
      primaryMuscle: 'Deltoide Lateral',
      duration: '0:48',
      difficulty: 'Iniciante',
    ),
    ExerciseVideo(
      title: 'Tríceps Testa com Barra W',
      category: 'Braços',
      primaryMuscle: 'Tríceps',
      duration: '0:50',
      difficulty: 'Intermediário',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', 'Peito', 'Pernas', 'Costas', 'Braços', 'Ombros'];

    final filteredVideos = _videos.where((video) {
      final matchesCategory = _selectedCategory == 'Todos' || video.category == _selectedCategory;
      final matchesSearch = video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          video.primaryMuscle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('VÍDEOS DE EXERCÍCIOS', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Buscar exercício ou músculo...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                fillColor: AppColors.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Categorias
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Grid de Vídeos
          Expanded(
            child: filteredVideos.isEmpty
                ? const Center(
                    child: Text('Nenhum vídeo encontrado.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                      return _VideoGridCard(video: video);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VideoGridCard extends StatelessWidget {
  final ExerciseVideo video;

  const _VideoGridCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail mockada com botão Play
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.surfaceLight,
                    child: Center(
                      child: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: AppColors.teal.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  // Overlay gradiente escuro
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Botão de Play centralizado
                  Center(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Iniciando reprodução do vídeo: ${video.title}'),
                            backgroundColor: AppColors.teal,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  // Duração
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.duration,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info do vídeo
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineSmall.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Músculo: ${video.primaryMuscle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video.category,
                      style: const TextStyle(color: AppColors.lightTeal, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
