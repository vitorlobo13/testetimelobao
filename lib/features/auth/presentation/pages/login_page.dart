import 'package:flutter/material.dart';
import '../../../../shared/widgets/brand_wordmark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';

/// Tela de Login
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('RECUPERAR SENHA', style: AppTextStyles.headlineMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insira seu e-mail cadastrado e enviaremos instruções para redefinir sua senha.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'E-mail',
              hint: 'seuemail@exemplo.com',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email,
            ),
          ],
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
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.contains('@')) {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final sent = await ref
                    .read(authProvider.notifier)
                    .sendPasswordReset(email);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(sent
                        ? 'Link de redefinição enviado para $email'
                        : ref.read(authProvider).errorMessage ??
                            'Não foi possível enviar o e-mail.'),
                    backgroundColor:
                        sent ? AppColors.success : AppColors.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Insira um e-mail válido'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(
              'Enviar',
              style: AppTextStyles.buttonMedium.copyWith(color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Limpa mensagens de erro anteriores
    ref.read(authProvider.notifier).clearError();

    // Valida formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Tenta fazer login
    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      // O go_router leva para a área certa (personal/aluno/admin).
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login realizado com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // Mostra erro
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
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
                  const SizedBox(height: 40),

                  // Logo e Título
                  _buildHeader(),

                  const SizedBox(height: 60),

                  // Formulário
                  _buildForm(),

                  const SizedBox(height: 16),

                  // Lembrar-me e Esqueci a senha
                  _buildRememberAndForgot(),

                  const SizedBox(height: 32),

                  // Botão de Login
                  CustomButton(
                    text: 'ENTRAR',
                    onPressed: authState.isLoading ? null : _handleLogin,
                    isLoading: authState.isLoading,
                    type: ButtonType.primary,
                  ),

                  const SizedBox(height: 24),

                  // Divisor
                  _buildDivider(),

                  const SizedBox(height: 24),

                  // Registro
                  _buildRegisterSection(),

                  const SizedBox(height: 40),
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
      children: [
        // Logo Placeholder
        const BrandWordmark(size: 46),

        const SizedBox(height: 28),

        Text(
          'Bem-vindo de volta',
          style: AppTextStyles.voice.copyWith(fontSize: 26),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
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
          hint: '••••••••',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: Icons.lock_outline,
          validator: Validators.password,
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Lembrar-me
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: AppColors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Lembrar-me',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),

        // Esqueci a senha
        TextButton(
          onPressed: () => _showForgotPasswordDialog(context),
          child: Text(
            'Esqueci a senha',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.surfaceLight)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.surfaceLight)),
      ],
    );
  }

  Widget _buildRegisterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Não tem uma conta? ',
          style: AppTextStyles.bodyMedium,
        ),
        GestureDetector(
          onTap: _navigateToRegister,
          child: Text(
            'Cadastre-se',
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
