import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../trainer/domain/entities/student_entity.dart';
import '../../data/invite_repository.dart';

/// Gera o link de convite do aluno e oferece WhatsApp / copiar.
Future<void> showInviteShareSheet(
  BuildContext context,
  StudentEntity student, {
  InviteRepository? repository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _InviteShareSheet(
      student: student,
      repository: repository ?? InviteRepository(),
    ),
  );
}

class _InviteShareSheet extends StatefulWidget {
  const _InviteShareSheet({required this.student, required this.repository});

  final StudentEntity student;
  final InviteRepository repository;

  @override
  State<_InviteShareSheet> createState() => _InviteShareSheetState();
}

class _InviteShareSheetState extends State<_InviteShareSheet> {
  late final Future<InviteLink> _invite =
      widget.repository.createInvite(widget.student.id);

  String _message(String url) {
    final firstName = widget.student.name.trim().split(' ').first;
    return 'Olá, $firstName! Seu acesso ao app do Time Lobão está pronto. '
        'Toque no link para criar sua conta e ver seus treinos: $url';
  }

  Future<void> _openWhatsApp(String url) async {
    final digits = (widget.student.phone ?? '').replaceAll(RegExp(r'\D'), '');
    // Telefone brasileiro sem DDI recebe o 55 na frente.
    final phone = digits.isEmpty
        ? ''
        : (digits.length <= 11 ? '55$digits' : digits);
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(_message(url))}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              );
            }
            final invite = snapshot.data!;
            final validUntil =
                DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(invite.expiresAt.toLocal());
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CONVIDAR ${widget.student.name.toUpperCase()}',
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
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTeal),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.chat),
                  label: const Text('ENVIAR PELO WHATSAPP'),
                  onPressed: () => _openWhatsApp(invite.url),
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
