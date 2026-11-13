import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../domain/services/trainer_updates.dart';
import '../providers/trainer_settings_provider.dart';

/// Configurações do personal: perfil, prazos das Atualizações e conta.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _savingProfile = false;

  UpdateSettings? _draft; // prazos em edição (null = ainda não mexeu)
  bool _savingDeadlines = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _snack(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: error ? AppColors.error : AppColors.success,
        content: Text(text),
      ));

  Future<void> _saveProfile() async {
    if (_name.text.trim().length < 2) {
      _snack('Informe seu nome.', error: true);
      return;
    }
    setState(() => _savingProfile = true);
    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(name: _name.text, phone: _phone.text);
      _snack('Perfil atualizado.');
    } catch (e) {
      _snack('Não foi possível salvar: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _saveDeadlines(UpdateSettings value) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _savingDeadlines = true);
    try {
      await ref
          .read(trainerSettingsRepositoryProvider)
          .saveUpdateSettings(user.id, value);
      setState(() => _draft = null);
      _snack('Prazos salvos. As Atualizações já usam os novos valores.');
    } catch (e) {
      _snack('Não foi possível salvar: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingDeadlines = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final saved = ref.watch(updateSettingsProvider).value ?? const UpdateSettings();
    final d = _draft ?? saved;
    final changed = _draft != null &&
        _draft!.toMap().toString() != saved.toMap().toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('CONFIGURAÇÕES', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Perfil ──────────────────────────────────────────────
          _Section(
            title: 'Meu perfil',
            icon: Icons.person_outline,
            children: [
              const Center(child: ProfileAvatar(radius: 44)),
              const SizedBox(height: 6),
              Center(
                child: Text('Toque na foto para trocar',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
              ),
              const SizedBox(height: 16),
              _field(_name, 'Nome', Icons.badge_outlined),
              const SizedBox(height: 12),
              _field(_phone, 'Telefone (WhatsApp)', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.textTertiary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(user?.email ?? '',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'O nome aparece nos convites e nas mensagens de WhatsApp.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 12),
              _button('SALVAR PERFIL', Icons.save, _savingProfile,
                  _saveProfile),
            ],
          ),

          // ── Prazos das Atualizações ─────────────────────────────
          _Section(
            title: 'Prazos das Atualizações',
            icon: Icons.fact_check_outlined,
            children: [
              Text(
                'Quando cada aviso deve aparecer na tela de Atualizações.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              _Stepper(
                label: 'Avisar treino vencendo',
                suffix: 'dias antes',
                value: d.workoutExpiringDays,
                min: 1,
                max: 30,
                onChanged: (v) => setState(() => _draft = UpdateSettings(
                    workoutExpiringDays: v,
                    birthdaySoonDays: d.birthdaySoonDays,
                    assessmentEveryDays: d.assessmentEveryDays,
                    inactiveDays: d.inactiveDays)),
              ),
              _Stepper(
                label: 'Mostrar aniversários',
                suffix: 'dias antes',
                value: d.birthdaySoonDays,
                min: 1,
                max: 30,
                onChanged: (v) => setState(() => _draft = UpdateSettings(
                    workoutExpiringDays: d.workoutExpiringDays,
                    birthdaySoonDays: v,
                    assessmentEveryDays: d.assessmentEveryDays,
                    inactiveDays: d.inactiveDays)),
              ),
              _Stepper(
                label: 'Refazer avaliação a cada',
                suffix: 'dias',
                value: d.assessmentEveryDays,
                min: 15,
                max: 365,
                step: 15,
                onChanged: (v) => setState(() => _draft = UpdateSettings(
                    workoutExpiringDays: d.workoutExpiringDays,
                    birthdaySoonDays: d.birthdaySoonDays,
                    assessmentEveryDays: v,
                    inactiveDays: d.inactiveDays)),
              ),
              _Stepper(
                label: 'Aluno sem treinar há',
                suffix: 'dias',
                value: d.inactiveDays,
                min: 2,
                max: 60,
                onChanged: (v) => setState(() => _draft = UpdateSettings(
                    workoutExpiringDays: d.workoutExpiringDays,
                    birthdaySoonDays: d.birthdaySoonDays,
                    assessmentEveryDays: d.assessmentEveryDays,
                    inactiveDays: v)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _savingDeadlines
                        ? null
                        : () => setState(
                            () => _draft = const UpdateSettings()),
                    child: const Text('Restaurar padrão'),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    child: _button('SALVAR', Icons.save,
                        _savingDeadlines,
                        changed ? () => _saveDeadlines(_draft!) : null),
                  ),
                ],
              ),
            ],
          ),

          // ── Conta ───────────────────────────────────────────────
          _Section(
            title: 'Conta',
            icon: Icons.lock_outline,
            children: [
              _tile(Icons.password, 'Alterar senha',
                  () => showDialog(
                      context: context,
                      builder: (_) => const _ChangePasswordDialog())),
              _tile(Icons.logout, 'Sair do app', () async {
                Navigator.of(context).popUntil((r) => r.isFirst);
                await ref.read(authProvider.notifier).logout();
              }, color: AppColors.error),
            ],
          ),

          const SizedBox(height: 8),
          Center(
            child: Text('Time Lobão · versão de testes',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
          {TextInputType? keyboard}) =>
      TextField(
        controller: c,
        keyboardType: keyboard,
        style: AppTextStyles.bodyLarge,
        decoration: _decoration(label, icon),
      );

  Widget _button(String text, IconData icon, bool busy, VoidCallback? onTap) =>
      SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: busy ? null : onTap,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(icon, size: 18),
          label: Text(text),
        ),
      );

  Widget _tile(IconData icon, String text, VoidCallback onTap,
          {Color color = AppColors.textPrimary}) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(text, style: AppTextStyles.bodyLarge.copyWith(color: color)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        onTap: onTap,
      );
}

InputDecoration _decoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceLight),
      ),
    );

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: AppColors.lightTeal, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// Linha "rótulo  [−] valor [+]" (sem digitação).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.suffix,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final String suffix;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyLarge),
                Text('$value $suffix',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.lightTeal)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Diminuir',
            onPressed: value - step >= min ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.textPrimary,
          ),
          SizedBox(
            width: 36,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall),
          ),
          IconButton(
            tooltip: 'Aumentar',
            onPressed: value + step <= max ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_new.text.length < 8) {
      setState(() => _error = 'A nova senha precisa de pelo menos 8 caracteres.');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'As senhas novas não conferem.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authProvider.notifier).changePassword(
          currentPassword: _current.text, newPassword: _new.text);
      nav.pop();
      messenger.showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Senha alterada.')));
    } on AuthFailure catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Widget _pass(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          obscureText: true,
          style: AppTextStyles.bodyLarge,
          decoration: _decoration(label, Icons.lock_outline),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Alterar senha'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pass(_current, 'Senha atual'),
            _pass(_new, 'Nova senha'),
            _pass(_confirm, 'Repita a nova senha'),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        TextButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Salvando...' : 'Alterar')),
      ],
    );
  }
}
