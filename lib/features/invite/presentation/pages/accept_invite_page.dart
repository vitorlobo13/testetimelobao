import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../data/invite_repository.dart';

final _inviteRepositoryProvider =
    Provider<InviteRepository>((ref) => InviteRepository());

final _inviteInfoProvider = FutureProvider.family<InviteInfo, String>(
  (ref, token) => ref.read(_inviteRepositoryProvider).getInvite(token),
);

/// Tela aberta pelo link `/convite/{token}` que o personal manda no WhatsApp.
class AcceptInvitePage extends ConsumerWidget {
  const AcceptInvitePage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(_inviteInfoProvider(token));
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: info.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => _Message(
                icon: Icons.error_outline,
                text: e is FirebaseFunctionsException
                    ? (e.message ?? 'Erro ao abrir convite.')
                    : 'Erro ao abrir convite.',
              ),
              data: (invite) {
                if (!invite.valid) {
                  return _Message(
                    icon: Icons.link_off,
                    text: invite.reason ?? 'Convite inválido.',
                  );
                }
                final user = auth.user;
                if (user != null && !user.isStudent) {
                  return const _Message(
                    icon: Icons.person_off,
                    text: 'Você está logado como personal/admin. '
                        'Saia da conta para aceitar este convite como aluno.',
                  );
                }
                return _InviteForm(token: token, invite: invite, loggedIn: user);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ir para o login'),
          ),
        ],
      ),
    );
  }
}

class _InviteForm extends ConsumerStatefulWidget {
  const _InviteForm({
    required this.token,
    required this.invite,
    required this.loggedIn,
  });

  final String token;
  final InviteInfo invite;
  final UserEntity? loggedIn;

  @override
  ConsumerState<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends ConsumerState<_InviteForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.invite.studentName);
  late final _email = TextEditingController(text: widget.invite.email);
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(authProvider.notifier);
    final bool ok;
    if (widget.loggedIn != null) {
      ok = await notifier.acceptInvite(widget.token);
    } else {
      if (!_formKey.currentState!.validate()) return;
      ok = await notifier.registerWithInvite(
        token: widget.token,
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
    }
    if (!mounted) return;
    if (ok) {
      context.go('/aluno');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).errorMessage ?? 'Erro.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;
    final trainer = widget.invite.trainerName ?? 'Seu personal';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset('lib/assets/icons/logo.png', height: 120),
            const SizedBox(height: 16),
            Text('BEM-VINDO AO TIME LOBÃO',
                textAlign: TextAlign.center, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '$trainer convidou você para acompanhar seus treinos pelo app.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (widget.loggedIn != null)
              Text(
                'Você está logado como ${widget.loggedIn!.email}. '
                'Ao aceitar, seus treinos passam a vir de $trainer.',
                style: AppTextStyles.bodyMedium,
              )
            else ...[
              CustomTextField(
                label: 'Nome completo',
                controller: _name,
                prefixIcon: Icons.person,
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'E-mail',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Crie uma senha',
                controller: _password,
                obscureText: true,
                prefixIcon: Icons.lock,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Confirme a senha',
                controller: _confirm,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) =>
                    v != _password.text ? 'As senhas não conferem' : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Já tem conta no app? Entre pelo login e depois abra este '
                'link de novo.',
                style: AppTextStyles.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            CustomButton(
              text: widget.loggedIn != null ? 'ACEITAR CONVITE' : 'CRIAR MINHA CONTA',
              isLoading: loading,
              onPressed: loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
