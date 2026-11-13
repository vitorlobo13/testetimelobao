import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/exercise_video_player.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../data/services/exercise_video_storage.dart';
import '../../domain/entities/exercise_entity.dart';
import '../providers/exercises_provider.dart';

/// Catálogo de exercícios do personal, com vídeo de demonstração
/// (link do YouTube ou vídeo próprio de até 30 s).
class ExerciseVideosPage extends ConsumerStatefulWidget {
  const ExerciseVideosPage({super.key});

  @override
  ConsumerState<ExerciseVideosPage> createState() => _ExerciseVideosPageState();
}

class _ExerciseVideosPageState extends ConsumerState<ExerciseVideosPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  bool _onlyWithVideo = false;

  @override
  Widget build(BuildContext context) {
    final exercisesState = ref.watch(exercisesProvider);
    final allCategories = ['Todos', ...ExerciseCategory.all];
    final query = _searchQuery.toLowerCase();

    final filtered = exercisesState.exercises.where((e) {
      final matchesCategory =
          _selectedCategory == 'Todos' || e.category == _selectedCategory;
      final matchesSearch = e.name.toLowerCase().contains(query) ||
          e.muscleGroup.toLowerCase().contains(query);
      final matchesVideo = !_onlyWithVideo || (e.videoUrl?.isNotEmpty ?? false);
      return matchesCategory && matchesSearch && matchesVideo;
    }).toList();
    final withVideo = exercisesState.exercises
        .where((e) => e.videoUrl?.isNotEmpty ?? false)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('MEUS EXERCÍCIOS', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Buscar exercício ou músculo...',
                hintStyle:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                fillColor: AppColors.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('Com vídeo ($withVideo)'),
                    selected: _onlyWithVideo,
                    onSelected: (v) => setState(() => _onlyWithVideo = v),
                  ),
                ),
                for (final category in allCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: exercisesState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal))
                : exercisesState.errorMessage != null
                    ? Center(
                        child: Text(exercisesState.errorMessage!,
                            style: AppTextStyles.bodyMedium))
                    : filtered.isEmpty
                        ? Center(
                            child: Text('Nenhum exercício encontrado.',
                                style: AppTextStyles.bodyMedium))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final exercise = filtered[index];
                              return _ExerciseTile(
                                exercise: exercise,
                                onEdit: () => _openEditor(exercise),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(null),
        backgroundColor: AppColors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo exercício',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _openEditor(ExerciseEntity? exercise) =>
      showExerciseEditor(context, exercise: exercise);
}

/// Abre o formulário de exercício. Devolve o exercício salvo (com id),
/// ou null se a pessoa fechar sem salvar ou excluir.
Future<ExerciseEntity?> showExerciseEditor(
  BuildContext context, {
  ExerciseEntity? exercise,
  String? initialName,
}) {
  return showModalBottomSheet<ExerciseEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) =>
        _ExerciseEditor(exercise: exercise, initialName: initialName),
  );
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onEdit});

  final ExerciseEntity exercise;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final url = exercise.videoUrl;
    final hasVideo = url != null && url.isNotEmpty;
    final youtubeId =
        hasVideo ? YoutubePlayerController.convertUrlToId(url) : null;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasVideo
            ? () => showExerciseVideo(context, title: exercise.name, videoUrl: url)
            : onEdit,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 54,
                  color: AppColors.surfaceLight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (youtubeId != null)
                        Image.network(
                          YoutubePlayerController.getThumbnail(
                            videoId: youtubeId,
                            quality: ThumbnailQuality.medium,
                            format: ThumbnailFormat.jpeg,
                          ),
                          fit: BoxFit.cover,
                          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      Icon(
                        hasVideo ? Icons.play_circle_fill : Icons.videocam_off,
                        color: hasVideo ? Colors.white : AppColors.textTertiary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.category} · ${exercise.muscleGroup} · ${exercise.equipment}',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Criar/editar exercício e anexar vídeo (link ou arquivo de até 30 s).
class _ExerciseEditor extends ConsumerStatefulWidget {
  const _ExerciseEditor({this.exercise, this.initialName});
  final ExerciseEntity? exercise;

  /// Nome já preenchido ao criar (ex.: o que foi digitado na busca).
  final String? initialName;

  @override
  ConsumerState<_ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends ConsumerState<_ExerciseEditor> {
  final _formKey = GlobalKey<FormState>();
  final _storage = ExerciseVideoStorage();
  late final _name =
      TextEditingController(text: widget.exercise?.name ?? widget.initialName);
  late final _muscle = TextEditingController(text: widget.exercise?.muscleGroup);
  late final _equipment = TextEditingController(text: widget.exercise?.equipment);
  late final _url = TextEditingController(text: widget.exercise?.videoUrl);
  late String _category = widget.exercise?.category ?? ExerciseCategory.chest;
  late String _difficulty = widget.exercise?.difficulty ?? 'Iniciante';
  XFile? _pickedVideo;
  double? _progress;
  bool _saving = false;

  bool get _isNew => widget.exercise == null;

  @override
  void dispose() {
    _name.dispose();
    _muscle.dispose();
    _equipment.dispose();
    _url.dispose();
    super.dispose();
  }

  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.error : AppColors.success,
    ));
  }

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: ExerciseVideoStorage.maxSeconds),
    );
    if (file == null) return;
    final problem = await _storage.validate(file);
    if (!mounted) return;
    if (problem != null) {
      _toast(problem, error: true);
      return;
    }
    setState(() {
      _pickedVideo = file;
      _url.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final link = _url.text.trim();
    if (link.isNotEmpty && !link.startsWith('http')) {
      _toast('O link do vídeo deve começar com https://', error: true);
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(exercisesProvider.notifier);
    try {
      var exercise = ExerciseEntity(
        id: widget.exercise?.id ?? '',
        name: _name.text.trim(),
        category: _category,
        muscleGroup: _muscle.text.trim(),
        equipment: _equipment.text.trim(),
        difficulty: _difficulty,
        description: widget.exercise?.description,
        instructions: widget.exercise?.instructions ?? const [],
        thumbnailUrl: widget.exercise?.thumbnailUrl,
        videoUrl: link.isEmpty ? null : link,
      );

      final id = _isNew ? await notifier.createExercise(exercise) : exercise.id;
      exercise = _withId(exercise, id);

      final video = _pickedVideo;
      if (video != null) {
        final trainerId = ref.read(authProvider).user!.id;
        final url = await _storage.upload(
          trainerId: trainerId,
          exerciseId: id,
          file: video,
          onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        );
        exercise = _withId(exercise, id, videoUrl: url);
        await notifier.updateExercise(exercise);
      } else if (!_isNew) {
        await notifier.updateExercise(exercise);
      }

      if (!mounted) return;
      _toast(_isNew ? 'Exercício criado!' : 'Exercício atualizado!');
      Navigator.pop(context, exercise);
    } on FirebaseException catch (e) {
      _toast('Erro ao salvar: ${e.message}', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Excluir exercício'),
        content: Text(
          'Excluir "${widget.exercise!.name}" do seu catálogo? '
          'Treinos já montados não são alterados.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(exercisesProvider.notifier).deleteExercise(widget.exercise!.id);
    if (mounted) Navigator.pop(context);
  }

  ExerciseEntity _withId(ExerciseEntity e, String id, {String? videoUrl}) =>
      ExerciseEntity(
        id: id,
        name: e.name,
        category: e.category,
        muscleGroup: e.muscleGroup,
        equipment: e.equipment,
        difficulty: e.difficulty,
        description: e.description,
        instructions: e.instructions,
        thumbnailUrl: e.thumbnailUrl,
        videoUrl: videoUrl ?? e.videoUrl,
      );

  @override
  Widget build(BuildContext context) {
    final currentVideo = widget.exercise?.videoUrl;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_isNew ? 'NOVO EXERCÍCIO' : 'EDITAR EXERCÍCIO',
                        style: AppTextStyles.headlineSmall),
                  ),
                  if (!_isNew)
                    IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: _saving ? null : _delete,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nome',
                controller: _name,
                prefixIcon: Icons.fitness_center,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: ExerciseCategory.all.contains(_category)
                    ? _category
                    : ExerciseCategory.chest,
                decoration: const InputDecoration(labelText: 'Grupo'),
                dropdownColor: AppColors.surfaceLight,
                items: [
                  for (final c in ExerciseCategory.all)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Músculo principal',
                controller: _muscle,
                prefixIcon: Icons.accessibility_new,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Equipamento',
                controller: _equipment,
                prefixIcon: Icons.build,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: const ['Iniciante', 'Intermediário', 'Avançado']
                        .contains(_difficulty)
                    ? _difficulty
                    : 'Iniciante',
                decoration: const InputDecoration(labelText: 'Dificuldade'),
                dropdownColor: AppColors.surfaceLight,
                items: const [
                  DropdownMenuItem(value: 'Iniciante', child: Text('Iniciante')),
                  DropdownMenuItem(
                      value: 'Intermediário', child: Text('Intermediário')),
                  DropdownMenuItem(value: 'Avançado', child: Text('Avançado')),
                ],
                onChanged: (v) => setState(() => _difficulty = v!),
              ),
              const SizedBox(height: 20),
              Text('VÍDEO DE DEMONSTRAÇÃO', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Link do YouTube',
                hint: 'https://youtube.com/...',
                controller: _url,
                prefixIcon: Icons.link,
                enabled: _pickedVideo == null,
              ),
              const SizedBox(height: 8),
              Text('ou', textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: Icon(_pickedVideo != null ? Icons.check_circle : Icons.video_library),
                label: Text(_pickedVideo != null
                    ? 'Vídeo selecionado (toque para trocar)'
                    : 'Enviar vídeo próprio (até 30 s)'),
                onPressed: _saving ? null : _pickVideo,
              ),
              if (currentVideo != null && currentVideo.isNotEmpty && _pickedVideo == null)
                TextButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Ver vídeo atual'),
                  onPressed: () => showExerciseVideo(context,
                      title: widget.exercise!.name, videoUrl: currentVideo),
                ),
              Text(
                'Dica: vídeo não listado no YouTube não tem custo e pode ser mais longo.',
                style: AppTextStyles.bodySmall,
              ),
              if (_progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress),
              ],
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('SALVAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
