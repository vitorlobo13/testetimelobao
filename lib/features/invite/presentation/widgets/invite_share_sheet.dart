import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/whatsapp.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../trainer/domain/entities/student_entity.dart';
import '../../data/invite_repository.dart';

/// Gera o link de convite do aluno e oferece WhatsApp / copiar.
Future<void> showInviteShareSheet(
  BuildContext context,
  StudentEntity student, {
  InviteRepository? repository,
}) {
  final repo = repository ?? InviteRepository();
  return _showSheet(
    context,
    name: student.name,
    phone: student.phone,
    invite: repo.createInvite(student.id),
  );
}

/// Chave do convite que estava aberto quando o WhatsApp foi chamado.
const _pendingKey = 'pending_invite_share';

/// No iPhone, voltar do WhatsApp pode recarregar o app do zero. Se havia um
/// convite aberto há pouco, reabre o mesmo convite (sem gerar outro link).
Future<void> resumePendingInviteShare(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_pendingKey);
  if (raw == null) return;
  await prefs.remove(_pendingKey);
  if (raw.length != 5) return;
  final savedAt = DateTime.tryParse(raw[4]);
  final expiresAt = DateTime.tryParse(raw[3]);
  if (savedAt == null || expiresAt == null) return;
  final recent =
      DateTime.now().difference(savedAt) < const Duration(minutes: 30);
  if (!recent || expiresAt.isBefore(DateTime.now())) return;
  if (!context.mounted) return;
  await _showSheet(
    context,
    name: raw[0],
    phone: raw[1].isEmpty ? null : raw[1],
    invite: Future.value(InviteLink(url: raw[2], expiresAt: expiresAt)),
  );
}

Future<void> _showSheet(
  BuildContext context, {
  required String name,
  required String? phone,
  required Future<InviteLink> invite,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _InviteShareSheet(name: name, phone: phone, invite: invite),
  );
}

class _InviteShareSheet extends StatefulWidget {
  const _InviteShareSheet({
    required this.name,
    required this.phone,
    required this.invite,
  });

  final String name;
  final String? phone;
  final Future<InviteLink> invite;

  @override
  State<_InviteShareSheet> createState() => _InviteShareSheetState();
}

class _InviteShareSheetState extends State<_InviteShareSheet> {
  late final Future<InviteLink> _invite = widget.invite;

  @override
  void dispose() {
    // Fechou o convite normalmente: nada para reabrir depois.
    SharedPreferences.getInstance().then((p) => p.remove(_pendingKey));
    super.dispose();
  }

  String _message(String url) {
    final firstName = widget.name.trim().split(' ').first;
    return 'Olá, $firstName! Seu acesso ao app do Time Lobo Lopes está pronto. '
        'Toque no link para criar sua conta e ver seus treinos: $url';
  }

  Future<void> _openWhatsApp(InviteLink invite) async {
    final url = invite.url;
    // Guarda o convite aberto, para reabri-lo se o app recarregar na volta.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pendingKey, [
      widget.name,
      widget.phone ?? '',
      url,
      invite.expiresAt.toIso8601String(),
      DateTime.now().toIso8601String(),
    ]);
    await launchWhatsApp(widget.phone, _message(url));
  }

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: _message(url)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Convite copiado!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: FutureBuilder<InviteLink>(
          future: _invite,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Text(
                error is FirebaseFunctionsException
                    ? (error.message ?? 'Erro ao gerar convite.')
                    : 'Erro ao gerar convite: $error',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              );
            }
            final invite = snapshot.data!;
            final validUntil = DateFormat("dd/MM 'às' HH:mm", 'pt_BR')
                .format(invite.expiresAt.toLocal());
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Convidar ${widget.name}',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'O aluno abre o link, cria a senha e já vê os treinos. '
                  'Válido até $validUntil.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  invite.url,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.lightTeal),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('ENVIAR PELO WHATSAPP'),
                  onPressed: () => _openWhatsApp(invite),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('COPIAR CONVITE'),
                  onPressed: () => _copy(invite.url),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
