import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../providers/admin_provider.dart';
import '../../../help/data/feedback_repository.dart';

/// Tela da conta administradora: convidar personal, ver/desativar personais
/// e ligar/desligar o cadastro aberto.
class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final email = _emailController.text.trim();
    try {
      await ref.read(adminRepositoryProvider).inviteTrainer(
            name: _nameController.text.trim(),
            email: email,
          );
      _nameController.clear();
      _emailController.clear();
      _showMessage('Convite enviado para $email');
    } on FirebaseFunctionsException catch (e) {
      _showMessage(e.message ?? 'Erro ao convidar.', error: true);
    } on FirebaseAuthException catch (e) {
      _showMessage('Conta criada, mas o e-mail falhou: ${e.message}', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleTrainer(String uid, bool active) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setTrainerActive(uid: uid, active: active);
    } on FirebaseFunctionsException catch (e) {
      _showMessage(e.message ?? 'Erro ao atualizar.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainers = ref.watch(trainersProvider);
    final selfSignup = ref.watch(selfSignupProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('ADMINISTRAÇÃO', style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Convidar personal', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'O personal recebe um e-mail para criar a própria senha.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  label: 'Nome',
                  controller: _nameController,
                  prefixIcon: Icons.person,
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'E-mail',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Informe um e-mail válido'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'ENVIAR CONVITE',
                  icon: Icons.send,
                  isLoading: _sending,
                  onPressed: _sending ? null : _invite,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Personais', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          trainers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro: $e', style: AppTextStyles.bodyMedium),
            data: (list) => list.isEmpty
                ? Text('Nenhum personal ainda.', style: AppTextStyles.bodyMedium)
                : Column(
                    children: [
                      for (final t in list)
                        Card(
                          color: AppColors.surface,
                          child: SwitchListTile(
                            title: Text(t.name, style: AppTextStyles.bodyLarge),
                            subtitle: Text(
                              t.active ? t.email : '${t.email} · desativado',
                              style: AppTextStyles.bodySmall,
                            ),
                            value: t.active,
                            onChanged: (v) => _toggleTrainer(t.uid, v),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 32),
          Text('Cadastro aberto', style: AppTextStyles.headlineSmall),
          Card(
            color: AppColors.surface,
            child: SwitchListTile(
              title: Text('Permitir cadastro sem convite',
                  style: AppTextStyles.bodyLarge),
              subtitle: Text(
                'Deixe ligado só na fase de teste. Desligado, só entra quem '
                'for convidado.',
                style: AppTextStyles.bodySmall,
              ),
              value: selfSignup.value ?? true,
              onChanged: selfSignup.hasValue
                  ? (v) => ref.read(adminRepositoryProvider).setSelfSignup(v)
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          Text('Mensagens (Fale com a gente)', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          ref.watch(feedbackListProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Text('Erro: $e', style: AppTextStyles.bodyMedium),
                data: (list) => list.isEmpty
                    ? Text('Nenhuma mensagem ainda.',
                        style: AppTextStyles.bodyMedium)
                    : Column(
                        children: [
                          for (final f in list)
                            Card(
                              color: AppColors.surface,
                              child: CheckboxListTile(
                                value: f.resolved,
                                onChanged: (v) => ref
                                    .read(feedbackRepositoryProvider)
                                    .setResolved(f.id, v ?? false),
                                title: Text('${f.type} · ${f.name}',
                                    style: AppTextStyles.bodyLarge),
                                subtitle: Text(
                                  '${f.message}\n${f.email} · '
                                  '${f.createdAt.day.toString().padLeft(2, '0')}/'
                                  '${f.createdAt.month.toString().padLeft(2, '0')}'
                                  '${f.resolved ? ' · resolvida' : ''}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                isThreeLine: true,
                              ),
                            ),
                        ],
                      ),
              ),
        ],
      ),
    );
  }
}
