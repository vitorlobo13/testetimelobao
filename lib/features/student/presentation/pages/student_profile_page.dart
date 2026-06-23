import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';

/// Notifier de estado para o perfil do aluno
class StudentProfileState {
  final double weight;
  final double height;
  final int age;
  final String phone;
  final String planType;
  final String trainerName;
  final bool isEditing;

  const StudentProfileState({
    required this.weight,
    required this.height,
    required this.age,
    required this.phone,
    required this.planType,
    required this.trainerName,
    this.isEditing = false,
  });

  double get bmi => weight / ((height / 100) * (height / 100));

  StudentProfileState copyWith({
    double? weight,
    double? height,
    int? age,
    String? phone,
    String? planType,
    String? trainerName,
    bool? isEditing,
  }) {
    return StudentProfileState(
      weight: weight ?? this.weight,
      height: height ?? this.height,
      age: age ?? this.age,
      phone: phone ?? this.phone,
      planType: planType ?? this.planType,
      trainerName: trainerName ?? this.trainerName,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class StudentProfileNotifier extends Notifier<StudentProfileState> {
  @override
  StudentProfileState build() {
    // Dados iniciais mockados para o aluno logado
    return const StudentProfileState(
      weight: 78.5,
      height: 176.0,
      age: 26,
      phone: '(11) 99876-5432',
      planType: 'Semestral Premium',
      trainerName: 'Rodrigo Lobão (Personal)',
    );
  }

  void toggleEditing() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void saveProfile({required double weight, required double height, required int age, required String phone}) {
    state = state.copyWith(
      weight: weight,
      height: height,
      age: age,
      phone: phone,
      isEditing: false,
    );
  }
}

final studentProfileProvider =
    NotifierProvider<StudentProfileNotifier, StudentProfileState>(() {
  return StudentProfileNotifier();
});

/// Tela de Perfil do Aluno
class StudentProfilePage extends ConsumerStatefulWidget {
  const StudentProfilePage({super.key});

  @override
  ConsumerState<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends ConsumerState<StudentProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(studentProfileProvider);
    _weightController = TextEditingController(text: profile.weight.toString());
    _heightController = TextEditingController(text: profile.height.toString());
    _ageController = TextEditingController(text: profile.age.toString());
    _phoneController = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(studentProfileProvider);
    final user = authState.user;

    final userName = user?.name ?? 'Aluno Lobão';
    final userEmail = user?.email ?? 'aluno@timelobao.com.br';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('MEU PERFIL', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              profileState.isEditing ? Icons.close : Icons.edit,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              if (profileState.isEditing) {
                // Cancela e restaura valores anteriores
                _weightController.text = profileState.weight.toString();
                _heightController.text = profileState.height.toString();
                _ageController.text = profileState.age.toString();
                _phoneController.text = profileState.phone;
              }
              ref.read(studentProfileProvider.notifier).toggleEditing();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar do usuário e cabeçalho principal
              _buildProfileHeader(userName, userEmail),
              const SizedBox(height: 24),

              // Dados Físicos e IMC
              _buildPhysicalSection(profileState),
              const SizedBox(height: 16),

              // Informações de Contato
              _buildContactSection(profileState),
              const SizedBox(height: 16),

              // Informações de Plano e Personal Trainer
              _buildPlanSection(profileState),
              const SizedBox(height: 24),

              // Botão Salvar
              if (profileState.isEditing)
                CustomButton(
                  text: 'SALVAR ALTERAÇÕES',
                  onPressed: _saveForm,
                  type: ButtonType.primary,
                  icon: Icons.save,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.teal.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.lightTeal,
                fontSize: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalSection(StudentProfileState profile) {
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
              const Icon(Icons.monitor_weight, color: AppColors.lightTeal),
              const SizedBox(width: 8),
              Text(
                'DADOS FÍSICOS',
                style: AppTextStyles.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile.isEditing) ...[
            CustomTextField(
              label: 'Peso (kg)',
              hint: 'Ex: 75.0',
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || double.tryParse(v) == null) {
                  return 'Insira um peso válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Altura (cm)',
              hint: 'Ex: 175',
              controller: _heightController,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || double.tryParse(v) == null) {
                  return 'Insira uma altura válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Idade',
              hint: 'Ex: 25',
              controller: _ageController,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || int.tryParse(v) == null) {
                  return 'Insira uma idade válida';
                }
                return null;
              },
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPhysicalDetail('Peso', '${profile.weight} kg'),
                _buildPhysicalDetail('Altura', '${(profile.height / 100).toStringAsFixed(2)} m'),
                _buildPhysicalDetail('Idade', '${profile.age} anos'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ÍNDICE DE MASSA CORPORAL (IMC)',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.bmi.toStringAsFixed(1),
                        style: AppTextStyles.displayMedium.copyWith(
                          color: _getBmiColor(profile.bmi),
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _getBmiClassification(profile.bmi),
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: _getBmiColor(profile.bmi),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhysicalDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headlineSmall),
      ],
    );
  }

  Widget _buildContactSection(StudentProfileState profile) {
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
              const Icon(Icons.phone, color: AppColors.lightTeal),
              const SizedBox(width: 8),
              Text(
                'CONTATO',
                style: AppTextStyles.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (profile.isEditing)
            CustomTextField(
              label: 'Telefone',
              hint: 'Ex: (11) 99999-9999',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Insira um telefone válido';
                }
                return null;
              },
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Celular', style: AppTextStyles.bodyMedium),
                Text(
                  profile.phone,
                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPlanSection(StudentProfileState profile) {
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
              const Icon(Icons.card_membership, color: AppColors.lightTeal),
              const SizedBox(width: 8),
              Text(
                'PLANO & PERSONAL',
                style: AppTextStyles.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tipo de Plano', style: AppTextStyles.bodyMedium),
              Text(
                profile.planType,
                style: AppTextStyles.headlineSmall.copyWith(
                  fontSize: 16,
                  color: AppColors.lightTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Treinador', style: AppTextStyles.bodyMedium),
              Text(
                profile.trainerName,
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.warning;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }

  String _getBmiClassification(double bmi) {
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25) return 'Peso ideal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  void _saveForm() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(studentProfileProvider.notifier).saveProfile(
            weight: double.parse(_weightController.text),
            height: double.parse(_heightController.text),
            age: int.parse(_ageController.text),
            phone: _phoneController.text,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
