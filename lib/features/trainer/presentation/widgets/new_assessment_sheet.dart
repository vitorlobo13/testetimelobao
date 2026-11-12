import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/physical_measurement_entity.dart';
import '../providers/physical_measurement_provider.dart';

/// Formulário de avaliação física (personal) ou de medidas (aluno), com
/// fotos de evolução opcionais. [linkId] é o vínculo do aluno.
Future<void> showNewAssessmentSheet(
  BuildContext context, {
  required String linkId,
  required String studentName,
  bool simplified = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _NewAssessmentSheet(
      linkId: linkId,
      studentName: studentName,
      simplified: simplified,
    ),
  );
}

class _NewAssessmentSheet extends ConsumerStatefulWidget {
  const _NewAssessmentSheet({
    required this.linkId,
    required this.studentName,
    required this.simplified,
  });

  final String linkId;
  final String studentName;
  final bool simplified;

  @override
  ConsumerState<_NewAssessmentSheet> createState() =>
      _NewAssessmentSheetState();
}

class _NewAssessmentSheetState extends ConsumerState<_NewAssessmentSheet> {
  final _fields = <String, TextEditingController>{
    for (final k in [
      'weight', 'height', 'fat', 'muscle', 'chest', 'waist', 'hip',
      'leftArm', 'rightArm', 'leftThigh', 'rightThigh', 'notes',
    ])
      k: TextEditingController(),
  };
  final List<XFile> _photos = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String key) =>
      double.tryParse(_fields[key]!.text.replaceAll(',', '.').trim());

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file != null) setState(() => _photos.add(file));
  }

  Future<void> _save() async {
    final measurement = PhysicalMeasurementEntity(
      id: '',
      studentId: widget.linkId,
      recordedAt: DateTime.now(),
      weight: _num('weight'),
      height: _num('height'),
      fatPercentage: _num('fat'),
      muscleMass: _num('muscle'),
      chest: _num('chest'),
      waist: _num('waist'),
      hip: _num('hip'),
      leftArm: _num('leftArm'),
      rightArm: _num('rightArm'),
      leftThigh: _num('leftThigh'),
      rightThigh: _num('rightThigh'),
      notes: _fields['notes']!.text.trim().isEmpty
          ? null
          : _fields['notes']!.text.trim(),
    );
    if (measurement.weight == null &&
        measurement.waist == null &&
        measurement.fatPercentage == null &&
        _photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Preencha ao menos uma medida ou adicione uma foto.'),
      ));
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(assessmentRepositoryProvider);
      final urls = <String>[];
      for (final photo in _photos) {
        urls.add(await repo.uploadPhoto(widget.linkId, photo));
      }
      await ref
          .read(physicalMeasurementProvider.notifier)
          .addMeasurement(measurement.copyWith(photoUrls: urls));
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('Avaliação salva!'),
        backgroundColor: AppColors.success,
      ));
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao salvar: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _numberField(String key, String label) => Expanded(
        child: CustomTextField(
          label: label,
          controller: _fields[key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );

  Widget _row(List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              children[i],
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.simplified ? 'REGISTRAR MEDIDAS' : 'NOVA AVALIAÇÃO',
              style: AppTextStyles.headlineSmall,
            ),
            Text(widget.studentName, style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
            _row([
              _numberField('weight', 'Peso (kg)'),
              _numberField('height', 'Altura (cm)'),
            ]),
            _row([
              _numberField('fat', '% Gordura'),
              if (!widget.simplified) _numberField('muscle', 'Massa magra (kg)'),
            ]),
            Text('PERÍMETROS (cm)', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            _row([
              _numberField('chest', 'Tórax'),
              _numberField('waist', 'Cintura'),
              _numberField('hip', 'Quadril'),
            ]),
            if (!widget.simplified) ...[
              _row([
                _numberField('leftArm', 'Braço esq.'),
                _numberField('rightArm', 'Braço dir.'),
              ]),
              _row([
                _numberField('leftThigh', 'Coxa esq.'),
                _numberField('rightThigh', 'Coxa dir.'),
              ]),
              CustomTextField(
                label: 'Observações',
                controller: _fields['notes'],
                maxLines: 3,
              ),
              const SizedBox(height: 12),
            ],
            Text('FOTOS DE EVOLUÇÃO', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _photos.length; i++)
                  Chip(
                    avatar: const Icon(Icons.photo, size: 18),
                    label: Text('Foto ${i + 1}'),
                    onDeleted: () => setState(() => _photos.removeAt(i)),
                  ),
                if (_photos.length < 4)
                  ActionChip(
                    avatar: const Icon(Icons.add_a_photo, size: 18),
                    label: const Text('Adicionar foto'),
                    onPressed: _saving ? null : _pickPhoto,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'As fotos ficam visíveis só para o aluno e o personal dele.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }
}
