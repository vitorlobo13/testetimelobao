import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import 'profile_selection_page.dart';

/// Tela de Cadastro
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Verifica termos de uso
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você deve aceitar os termos de uso'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Valida formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Navega para seleção de perfil
    if (!mounted) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileSelectionPage(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.darkTeal.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho
                  _buildHeader(),

                  const SizedBox(height: 40),

                  // Formulário
                  _buildForm(),

                  const SizedBox(height: 20),

                  // Termos de uso
                  _buildTermsCheckbox(),

                  const SizedBox(height: 32),

                  // Botão de Cadastro
                  CustomButton(
                    text: 'CONTINUAR',
                    onPressed: authState.isLoading ? null : _handleRegister,
                    isLoading: authState.isLoading,
                    type: ButtonType.primary,
                  ),

                  const SizedBox(height: 24),

                  // Login
                  _buildLoginSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Criar Conta',
          style: AppTextStyles.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Preencha seus dados para começar',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Nome completo
        CustomTextField(
          label: 'Nome Completo',
          hint: 'João Silva',
          controller: _nameController,
          keyboardType: TextInputType.name,
          prefixIcon: Icons.person_outline,
          validator: Validators.name,
        ),

        const SizedBox(height: 20),

        // Email
        CustomTextField(
          label: 'Email',
          hint: 'seu@email.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: Validators.email,
        ),

        const SizedBox(height: 20),

        // Senha
        CustomTextField(
          label: 'Senha',
          hint: 'Mínimo 8 caracteres',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          validator: Validators.strongPassword,
        ),

        const SizedBox(height: 20),

        // Confirmar senha
        CustomTextField(
          label: 'Confirmar Senha',
          hint: 'Digite a senha novamente',
          controller: _confirmPasswordController,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          validator: (value) => Validators.confirmPassword(
              _passwordController.text.trim()
            )(value?.trim()), 
          ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (value) {
              setState(() {
                _acceptTerms = value ?? false;
              });
            },
            activeColor: AppColors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMedium,
              children: [
                const TextSpan(text: 'Eu aceito os '),
                TextSpan(
                  text: 'Termos de Uso',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: ' e a '),
                TextSpan(
                  text: 'Política de Privacidade',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.teal,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Já tem uma conta? ',
          style: AppTextStyles.bodyMedium,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Entrar',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}