import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';

/// Tela de cadastro / edição de aluno
class AddStudentPage extends ConsumerStatefulWidget {
  final StudentEntity? student;
  const AddStudentPage({super.key, this.student});

  @override
  ConsumerState<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends ConsumerState<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late final TextEditingController _monthlyFeeController;

  Gender _selectedGender = Gender.male;
  String _selectedPlan = 'Básico';
  PaymentStatus _paymentStatus = PaymentStatus.pending;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameController = TextEditingController(text: s?.name ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _weightController = TextEditingController(text: s?.weight?.toString() ?? '');
    _heightController = TextEditingController(text: s?.height?.toString() ?? '');
    _ageController = TextEditingController(text: s?.age?.toString() ?? '');
    _monthlyFeeController = TextEditingController(text: s?.monthlyFee?.toString() ?? '');

    if (s != null) {
      _selectedGender = s.gender ?? Gender.male;
      if (['Básico', 'Premium', 'Trimestral', 'Semestral', 'Anual'].contains(s.planType)) {
        _selectedPlan = s.planType!;
      } else {
        _selectedPlan = 'Básico';
      }
      _paymentStatus = s.paymentStatus;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.student != null ? 'EDITAR ALUNO' : 'CADASTRAR ALUNO',
          style: AppTextStyles.displaySmall,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dados de Contato / Pessoais
              _buildSectionTitle('INFORMAÇÕES PESSOAIS'),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nome Completo',
                hint: 'Ex: João Silva',
                controller: _nameController,
                prefixIcon: Icons.person,
                validator: (v) => v == null || v.isEmpty ? 'Insira o nome' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'E-mail',
                hint: 'Ex: joao@email.com',
                controller: _emailController,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Insira um e-mail válido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Telefone Celular',
                hint: 'Ex: (11) 99999-9999',
                controller: _phoneController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Dados Físicos
              _buildSectionTitle('DADOS FÍSICOS'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Peso (kg)',
                      hint: 'Ex: 78.5',
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Altura (cm)',
                      hint: 'Ex: 175',
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Idade',
                      hint: 'Ex: 26',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderDropdown(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dados de Assinatura e Pagamentos
              _buildSectionTitle('PLANO E PAGAMENTO'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPlanDropdown(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Mensalidade (R\$)',
                      hint: 'Ex: 150.00',
                      controller: _monthlyFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.attach_money,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPaymentStatusDropdown(),
              const SizedBox(height: 32),

              // Botão Cadastrar
              CustomButton(
                text: widget.student != null ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR ALUNO',
                onPressed: _saveStudent,
                type: ButtonType.primary,
                icon: widget.student != null ? Icons.save : Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gênero',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Gender>(
              value: _selectedGender,
              dropdownColor: AppColors.surface,
              isExpanded: true,
              style: AppTextStyles.bodyLarge,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: const [
                DropdownMenuItem(value: Gender.male, child: Text('Masculino')),
                DropdownMenuItem(value: Gender.female, child: Text('Feminino')),
                DropdownMenuItem(value: Gender.other, child: Text('Outro')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedGender = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Plano',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPlan,
              dropdownColor: AppColors.surface,
              isExpanded: true,
              style: AppTextStyles.bodyLarge,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: const [
                DropdownMenuItem(value: 'Básico', child: Text('Básico')),
                DropdownMenuItem(value: 'Premium', child: Text('Premium')),
                DropdownMenuItem(value: 'Trimestral', child: Text('Trimestral')),
                DropdownMenuItem(value: 'Semestral', child: Text('Semestral')),
                DropdownMenuItem(value: 'Anual', child: Text('Anual')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedPlan = v;
                    // Sugere taxas padrão
                    if (v == 'Básico') _monthlyFeeController.text = '150.00';
                    if (v == 'Premium') _monthlyFeeController.text = '250.00';
                    if (v == 'Anual') _monthlyFeeController.text = '120.00';
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Inicial do Pagamento',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PaymentStatus>(
              value: _paymentStatus,
              dropdownColor: AppColors.surface,
              isExpanded: true,
              style: AppTextStyles.bodyLarge,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              items: const [
                DropdownMenuItem(value: PaymentStatus.paid, child: Text('Pago')),
                DropdownMenuItem(value: PaymentStatus.pending, child: Text('Pendente')),
                DropdownMenuItem(value: PaymentStatus.overdue, child: Text('Atrasado')),
                DropdownMenuItem(value: PaymentStatus.exempt, child: Text('Isento')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _paymentStatus = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _saveStudent() {
    if (_formKey.currentState?.validate() ?? false) {
      final double? weight = double.tryParse(_weightController.text);
      final double? height = double.tryParse(_heightController.text);
      final int? age = int.tryParse(_ageController.text);
      final double fee = double.tryParse(_monthlyFeeController.text) ?? 0.0;

      final isEditing = widget.student != null;

      final savedStudent = StudentEntity(
        id: isEditing ? widget.student!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        trainerId: isEditing ? widget.student!.trainerId : 'trainer_123',
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        enrollmentDate: isEditing ? widget.student!.enrollmentDate : DateTime.now(),
        isActive: isEditing ? widget.student!.isActive : true,
        status: isEditing ? widget.student!.status : StudentStatus.active,
        weight: weight,
        height: height,
        age: age,
        gender: _selectedGender,
        planType: _selectedPlan,
        monthlyFee: fee,
        nextPaymentDate: isEditing 
            ? widget.student!.nextPaymentDate 
            : DateTime.now().add(const Duration(days: 30)),
        paymentStatus: _paymentStatus,
        lastWorkoutDate: isEditing ? widget.student!.lastWorkoutDate : null,
        totalWorkouts: isEditing ? widget.student!.totalWorkouts : 0,
      );

      if (isEditing) {
        ref.read(trainerDashboardProvider.notifier).updateStudent(savedStudent);
      } else {
        ref.read(trainerDashboardProvider.notifier).addStudent(savedStudent);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing 
              ? 'Dados de "${savedStudent.name}" atualizados com sucesso!'
              : 'Aluno "${savedStudent.name}" cadastrado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    }
  }
}
