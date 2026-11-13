import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/widgets/exercise_video_player.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/exercise_video_storage.dart';
import '../providers/exercises_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/workout_entity.dart';

/// Bottom Sheet para configurar exercício
class ExerciseConfigSheet extends ConsumerStatefulWidget {
  final WorkoutExercise workoutExercise;
  final Function(WorkoutExercise) onSave;

  const ExerciseConfigSheet({
    super.key,
    required this.workoutExercise,
    required this.onSave,
  });

  @override
  ConsumerState<ExerciseConfigSheet> createState() => _ExerciseConfigSheetState();
}

class _ExerciseConfigSheetState extends ConsumerState<ExerciseConfigSheet> {
  // Vídeo de demonstração (vai junto com o exercício no treino do aluno)
  final _videoStorage = ExerciseVideoStorage();
  late final TextEditingController _videoLinkController;
  late String? _videoUrl = widget.workoutExercise.exercise.videoUrl;
  XFile? _pickedVideo;
  bool _saveToCatalog = true;
  double? _progress;
  bool _saving = false;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _restController;
  late TextEditingController _loadController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.workoutExercise.sets.toString(),
    );
    _repsController = TextEditingController(
      text: widget.workoutExercise.reps,
    );
    _restController = TextEditingController(
      text: widget.workoutExercise.rest ?? '',
    );
    _loadController = TextEditingController(
      text: widget.workoutExercise.load ?? '',
    );
    _notesController = TextEditingController(
      text: widget.workoutExercise.notes ?? '',
    );
    final current = widget.workoutExercise.exercise.videoUrl ?? '';
    _videoLinkController = TextEditingController(
      // Só preenche o campo com links externos (YouTube); vídeo próprio
      // aparece como "vídeo anexado".
      text: current.contains('firebasestorage') ? '' : current,
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _loadController.dispose();
    _notesController.dispose();
    _videoLinkController.dispose();
    super.dispose();
  }

  void _toast(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ));

  Future<void> _pickVideo() async {
    final file = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: ExerciseVideoStorage.maxSeconds),
    );
    if (file == null) return;
    final problem = await _videoStorage.validate(file);
    if (!mounted) return;
    if (problem != null) {
      _toast(problem, error: true);
      return;
    }
    setState(() {
      _pickedVideo = file;
      _videoLinkController.clear();
    });
  }

  void _removeVideo() => setState(() {
        _videoUrl = null;
        _pickedVideo = null;
        _videoLinkController.clear();
      });

  Future<void> _handleSave() async {
    final link = _videoLinkController.text.trim();
    if (link.isNotEmpty && !link.startsWith('http')) {
      _toast('O link do vídeo deve começar com https://', error: true);
      return;
    }
    final original = widget.workoutExercise.exercise;
    setState(() => _saving = true);
    try {
      // 1) Vídeo final: novo upload > link digitado > vídeo próprio mantido.
      String? url = _videoUrl;
      if (_pickedVideo != null) {
        final trainerId = ref.read(authProvider).user!.id;
        final catalogId = original.id.isNotEmpty ? original.id : '';
        url = await _videoStorage.upload(
          trainerId: trainerId,
          // Salvando no catálogo, substitui o vídeo do exercício; senão,
          // fica só neste treino.
          exerciseId: _saveToCatalog && catalogId.isNotEmpty
              ? catalogId
              : 'treino_${widget.workoutExercise.id}',
          file: _pickedVideo!,
          onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        );
      } else if (link.isNotEmpty) {
        url = link;
      } else if ((_videoUrl ?? '').contains('firebasestorage')) {
        url = _videoUrl; // vídeo próprio já anexado, campo de link vazio
      } else {
        url = null;
      }

      final exercise = url == null
          ? original.copyWith(clearVideo: true)
          : original.copyWith(videoUrl: url);

      // 2) Opcional: o catálogo (Meus Exercícios) passa a ter o mesmo vídeo.
      final changed = (original.videoUrl ?? '') != (url ?? '');
      if (_saveToCatalog && changed && original.id.isNotEmpty) {
        final inCatalog = ref
            .read(exercisesProvider)
            .exercises
            .any((e) => e.id == original.id);
        if (inCatalog) {
          await ref.read(exercisesProvider.notifier).updateExercise(exercise);
        }
      }

      final updatedExercise = widget.workoutExercise.copyWith(
        exercise: exercise,
        sets: int.tryParse(_setsController.text) ?? 3,
        reps: _repsController.text,
        rest: _restController.text.isEmpty ? null : _restController.text,
        load: _loadController.text.isEmpty ? null : _loadController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      widget.onSave(updatedExercise);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('Não foi possível salvar o vídeo: $e', error: true);
      }
    }
  }

  Widget _buildVideoSection() {
    final hasOwnVideo = (_videoUrl ?? '').contains('firebasestorage') &&
        _pickedVideo == null;
    final current = _videoUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(Icons.ondemand_video, color: AppColors.lightTeal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Vídeo de demonstração',
                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 15)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('O aluno assiste à execução direto no treino dele.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          if (current != null && current.isNotEmpty && _pickedVideo == null)
            Row(children: [
              Expanded(
                child: Text(
                  hasOwnVideo ? 'Vídeo próprio anexado' : 'Vídeo anexado',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.success),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Assistir'),
                onPressed: () => showExerciseVideo(context,
                    title: widget.workoutExercise.exercise.name,
                    videoUrl: current),
              ),
              IconButton(
                tooltip: 'Remover vídeo',
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textTertiary),
                onPressed: _saving ? null : _removeVideo,
              ),
            ]),
          CustomTextField(
            label: 'Link do YouTube',
            hint: 'https://youtube.com/...',
            controller: _videoLinkController,
            prefixIcon: Icons.link,
            enabled: _pickedVideo == null && !_saving,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(_pickedVideo != null
                ? Icons.check_circle
                : Icons.video_library),
            label: Text(_pickedVideo != null
                ? 'Vídeo selecionado (toque para trocar)'
                : 'Enviar vídeo próprio (até 30 s)'),
            onPressed: _saving ? null : _pickVideo,
          ),
          if (_progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress),
          ],
          if (widget.workoutExercise.exercise.id.isNotEmpty)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.teal,
              value: _saveToCatalog,
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _saveToCatalog = v ?? true),
              title: Text('Salvar também em Meus Exercícios',
                  style: AppTextStyles.bodyMedium),
              subtitle: Text('Os próximos treinos já usam este vídeo.',
                  style: AppTextStyles.bodySmall),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
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
                        'Configurar Exercício',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.workoutExercise.exercise.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
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

          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Séries e Repetições
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Séries',
                          controller: _setsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.repeat,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Repetições',
                          hint: 'Ex: 10-12',
                          controller: _repsController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.fitness_center,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Descanso e Carga
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Descanso (seg)',
                          hint: 'Ex: 60',
                          controller: _restController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          prefixIcon: Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          label: 'Carga (kg)',
                          hint: 'Ex: 20',
                          controller: _loadController,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.scale,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Observações
                  CustomTextField(
                    label: 'Observações',
                    hint: 'Ex: Fazer lentamente, controlar a descida...',
                    controller: _notesController,
                    maxLines: 3,
                    prefixIcon: Icons.notes,
                  ),

                  const SizedBox(height: 20),

                  _buildVideoSection(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Botão salvar
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              text: _saving ? 'SALVANDO...' : 'SALVAR CONFIGURAÇÃO',
              onPressed: _saving ? null : _handleSave,
              type: ButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }
}