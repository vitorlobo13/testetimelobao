import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/trainer_provider.dart';
import '../../../invite/presentation/widgets/invite_share_sheet.dart';

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
  bool _exempt = false;
  late DateTime _nextDue;

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
    final today = DateTime.now();
    // Aluno novo: a primeira mensalidade vence hoje (fica pendente até registrar).
    _nextDue = s?.nextPaymentDate ?? DateTime(today.year, today.month, today.day);

    if (s != null) {
      _selectedGender = s.gender ?? Gender.male;
      if (['Básico', 'Premium', 'Trimestral', 'Semestral', 'Anual'].contains(s.planType)) {
        _selectedPlan = s.planType!;
      } else {
        _selectedPlan = 'Básico';
      }
      _exempt = s.paymentStatus == PaymentStatus.exempt;
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
              _buildDueAndExemptSection(),
              const SizedBox(height: 32),

              // Botão Cadastrar
              CustomButton(
                text: widget.student != null ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR ALUNO',
                onPressed: _saving ? null : _saveStudent,
                isLoading: _saving,
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDue,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('pt', 'BR'),
      helpText: 'Próximo vencimento',
    );
    if (picked != null) setState(() => _nextDue = picked);
  }

  Widget _buildDueAndExemptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_exempt) ...[
          Text(
            'Próximo vencimento',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd/MM/yyyy').format(_nextDue),
                      style: AppTextStyles.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Depois, cada pagamento registrado empurra o vencimento automaticamente.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.teal,
          title: Text('Aluno isento de mensalidade', style: AppTextStyles.bodyLarge),
          value: _exempt,
          onChanged: (v) => setState(() => _exempt = v),
        ),
      ],
    );
  }

  bool _saving = false;

  Future<void> _saveStudent() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final double? weight = double.tryParse(_weightController.text);
    final double? height = double.tryParse(_heightController.text);
    final int? age = int.tryParse(_ageController.text);
    final double fee = double.tryParse(_monthlyFeeController.text) ?? 0.0;

    final isEditing = widget.student != null;
    final existing = widget.student;

    final savedStudent = StudentEntity(
      id: existing?.id ?? '',
      trainerId: existing?.trainerId ?? '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      enrollmentDate: existing?.enrollmentDate ?? DateTime.now(),
      isActive: existing?.isActive ?? true,
      status: existing?.status ?? StudentStatus.active,
      weight: weight,
      height: height,
      age: age,
      gender: _selectedGender,
      planType: _selectedPlan,
      monthlyFee: fee,
      nextPaymentDate: _nextDue,
      paymentStatus: _exempt
          ? PaymentStatus.exempt
          : (existing == null || existing.paymentStatus == PaymentStatus.exempt
              ? PaymentStatus.pending
              : existing.paymentStatus),
      lastWorkoutDate: existing?.lastWorkoutDate,
      totalWorkouts: existing?.totalWorkouts ?? 0,
      studentUid: existing?.studentUid,
      linkStatus: existing?.linkStatus ?? LinkStatus.pending,
    );

    setState(() => _saving = true);
    final notifier = ref.read(trainerDashboardProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (isEditing) {
        await notifier.updateStudent(savedStudent);
        messenger.showSnackBar(SnackBar(
          content: Text('Dados de "${savedStudent.name}" atualizados com sucesso!'),
          backgroundColor: AppColors.success,
        ));
        navigator.pop();
      } else {
        final id = await notifier.addStudent(savedStudent);
        messenger.showSnackBar(SnackBar(
          content: Text('Aluno "${savedStudent.name}" cadastrado! Envie o convite.'),
          backgroundColor: AppColors.success,
        ));
        // Já abre o convite para mandar no WhatsApp; ao fechar, volta.
        if (mounted) {
          await showInviteShareSheet(context, savedStudent.copyWith(id: id));
        }
        navigator.pop();
      }
    } on FirebaseException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao salvar: ${e.message}'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
