import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/exercise_entity.dart';
import '../providers/exercises_provider.dart';

/// Tela de Biblioteca de Vídeos de Exercícios
class ExerciseVideosPage extends ConsumerStatefulWidget {
  const ExerciseVideosPage({super.key});

  @override
  ConsumerState<ExerciseVideosPage> createState() => _ExerciseVideosPageState();
}

class _ExerciseVideosPageState extends ConsumerState<ExerciseVideosPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesProvider);
    final allCategories = ['Todos', ...ExerciseCategory.all];

    final filteredVideos = exercisesState.exercises.where((video) {
      final matchesCategory = _selectedCategory == 'Todos' || video.category == _selectedCategory;
      final matchesSearch = video.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          video.muscleGroup.toLowerCase().contains(_searchQuery.toLowerCase());
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
              children: allCategories.map((category) {
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
            child: exercisesState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : filteredVideos.isEmpty
                    ? const Center(
                        child: Text('Nenhum exercício encontrado.', style: TextStyle(color: AppColors.textSecondary)),
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
                      final exercise = filteredVideos[index];
                      return _VideoGridCard(
                        exercise: exercise,
                        onAttachVideo: () => _showAttachVideoDialog(context, exercise, ref),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toque em um exercício da lista para anexar seu vídeo explicativo!'),
              backgroundColor: AppColors.teal,
            ),
          );
        },
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.video_call, color: Colors.white),
        label: const Text('Anexar Vídeo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAttachVideoDialog(BuildContext context, ExerciseEntity exercise, WidgetRef ref) {
    final urlController = TextEditingController(
      text: (exercise.videoUrl != null && exercise.videoUrl!.startsWith('http')) ? exercise.videoUrl : '',
    );
    String? localVideoPath = (exercise.videoUrl != null && !exercise.videoUrl!.startsWith('http')) ? exercise.videoUrl : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                'Anexar Vídeo',
                style: AppTextStyles.headlineMedium,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercício: ${exercise.name}',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Opção 1: Colar link externo',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.teal),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'URL (YouTube, Drive, etc)',
                      hint: 'https://...',
                      controller: urlController,
                      prefixIcon: Icons.link,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Opção 2: Enviar vídeo do celular',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.teal),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                        if (video != null) {
                          setStateDialog(() {
                            localVideoPath = video.path;
                            urlController.clear(); // Limpa a URL se escolheu vídeo local
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library, color: localVideoPath != null ? AppColors.teal : AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localVideoPath != null ? 'Vídeo Selecionado!' : 'Escolher da Galeria',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: localVideoPath != null ? AppColors.teal : AppColors.textSecondary,
                                  fontWeight: localVideoPath != null ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final url = urlController.text.trim();
                    final String? finalVideoValue = url.isNotEmpty ? url : localVideoPath;

                    final updatedExercise = ExerciseEntity(
                      id: exercise.id,
                      name: exercise.name,
                      category: exercise.category,
                      muscleGroup: exercise.muscleGroup,
                      equipment: exercise.equipment,
                      difficulty: exercise.difficulty,
                      description: exercise.description,
                      instructions: exercise.instructions,
                      thumbnailUrl: exercise.thumbnailUrl,
                      videoUrl: finalVideoValue,
                    );

                    ref.read(exercisesProvider.notifier).updateExercise(updatedExercise);
                    
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vídeo atualizado com sucesso!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Text(
                    'Salvar',
                    style: AppTextStyles.buttonMedium.copyWith(color: AppColors.teal),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VideoGridCard extends StatelessWidget {
  final ExerciseEntity exercise;
  final VoidCallback onAttachVideo;

  const _VideoGridCard({
    required this.exercise,
    required this.onAttachVideo,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasVideo ? AppColors.teal.withValues(alpha: 0.5) : AppColors.surfaceLight,
          width: hasVideo ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail mockada com botão de Editar/Adicionar Vídeo
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
                        color: hasVideo 
                            ? AppColors.teal.withValues(alpha: 0.4)
                            : AppColors.textTertiary.withValues(alpha: 0.2),
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
                  // Indicador de "Sem Vídeo" ou "Play"
                  Center(
                    child: InkWell(
                      onTap: () {
                        if (hasVideo) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Abrindo link do vídeo: ${exercise.videoUrl}'),
                              backgroundColor: AppColors.teal,
                            ),
                          );
                        } else {
                          onAttachVideo();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasVideo ? AppColors.teal : AppColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasVideo ? Icons.play_arrow : Icons.videocam_off,
                          color: hasVideo ? Colors.white : AppColors.textSecondary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  // Botão de edição no topo direito
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      onPressed: onAttachVideo,
                      tooltip: 'Editar link do vídeo',
                    ),
                  ),
                  // Status textual
                  if (!hasVideo)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sem Vídeo',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info do vídeo/exercício
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineSmall.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Músculo: ${exercise.muscleGroup}',
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
                      exercise.category,
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
