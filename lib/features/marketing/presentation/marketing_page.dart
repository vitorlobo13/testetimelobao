import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/utils/whatsapp.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../trainer/domain/entities/student_entity.dart';
import '../../trainer/presentation/providers/trainer_provider.dart';
import '../data/message_templates.dart';

/// Público de uma campanha.
enum Audience { active, inactive, birthdayMonth, overdue }

extension on Audience {
  String get label => switch (this) {
        Audience.active => 'Todos os ativos',
        Audience.inactive => 'Sem treinar há 14+ dias',
        Audience.birthdayMonth => 'Aniversariantes do mês',
        Audience.overdue => 'Mensalidade atrasada',
      };

  bool matches(StudentEntity s, DateTime now) {
    final current = s.linkStatus != LinkStatus.archived && s.isActive;
    if (!current) return false;
    switch (this) {
      case Audience.active:
        return true;
      case Audience.inactive:
        final lw = s.lastWorkoutDate;
        return s.hasAccount &&
            (lw == null || now.difference(lw).inDays >= 14);
      case Audience.birthdayMonth:
        return s.birthDate?.month == now.month;
      case Audience.overdue:
        return s.isBillable && s.isPaymentOverdue;
    }
  }
}

/// Marketing: modelos de mensagem e campanhas pelo WhatsApp.
class MarketingPage extends StatelessWidget {
  const MarketingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('MARKETING', style: AppTextStyles.displaySmall),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.teal,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: [
              Tab(icon: Icon(Icons.campaign), text: 'Campanha'),
              Tab(icon: Icon(Icons.edit_note), text: 'Modelos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_CampaignTab(), _TemplatesTab()],
        ),
      ),
    );
  }
}

// ── Campanha ──────────────────────────────────────────────────────────────

class _CampaignTab extends ConsumerStatefulWidget {
  const _CampaignTab();

  @override
  ConsumerState<_CampaignTab> createState() => _CampaignTabState();
}

class _CampaignTabState extends ConsumerState<_CampaignTab> {
  String _templateId = TemplateIds.promo;
  Audience _audience = Audience.active;
  final _sent = <String>{}; // alunos já abertos no WhatsApp nesta campanha

  @override
  Widget build(BuildContext context) {
    final templates =
        ref.watch(messageTemplatesProvider).value ?? kDefaultTemplates;
    final template = templateById(templates, _templateId);
    final trainer = ref.watch(authProvider).user?.name ?? '';
    final now = DateTime.now();
    final students = ref
        .watch(trainerDashboardProvider)
        .students
        .where((s) => _audience.matches(s, now))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final withPhone = students
        .where((s) => (s.phone ?? '').replaceAll(RegExp(r'\D'), '').isNotEmpty)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _label('1. Mensagem'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in templates)
              _chip(t.title, _templateId == t.id,
                  () => setState(() {
                        _templateId = t.id;
                        _sent.clear();
                      })),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3D2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            template.fill(studentName: 'Ana Souza', trainerName: trainer),
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text('Prévia com o nome "Ana". Edite os textos na aba Modelos.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 20),
        _label('2. Para quem'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final a in Audience.values)
              _chip(a.label, _audience == a,
                  () => setState(() {
                        _audience = a;
                        _sent.clear();
                      })),
          ],
        ),
        const SizedBox(height: 20),
        _label('3. Enviar (${_sent.length}/${students.length})'),
        Text(
          'O WhatsApp não permite envio em massa: toque em cada aluno para '
          'abrir a conversa com a mensagem pronta.'
          '${withPhone < students.length ? ' ${students.length - withPhone} aluno(s) sem telefone.' : ''}',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Nenhum aluno neste grupo.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          )
        else
          for (final s in students)
            _StudentSendTile(
              student: s,
              sent: _sent.contains(s.id),
              onSend: () async {
                await openWhatsApp(context, s.phone,
                    template.fill(studentName: s.name, trainerName: trainer));
                if (mounted && (s.phone ?? '').isNotEmpty) {
                  setState(() => _sent.add(s.id));
                }
              },
            ),
      ],
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(),
            style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      );
}

Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.teal,
      backgroundColor: AppColors.surface,
      labelStyle:
          TextStyle(color: selected ? Colors.white : AppColors.textSecondary),
      onSelected: (_) => onTap(),
    );

class _StudentSendTile extends StatelessWidget {
  const _StudentSendTile(
      {required this.student, required this.sent, required this.onSend});
  final StudentEntity student;
  final bool sent;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final hasPhone =
        (student.phone ?? '').replaceAll(RegExp(r'\D'), '').isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(sent ? Icons.check_circle : Icons.person_outline,
            color: sent ? AppColors.success : AppColors.textSecondary),
        title: Text(student.name, style: AppTextStyles.bodyLarge),
        subtitle: Text(hasPhone ? student.phone! : 'Sem telefone cadastrado',
            style: AppTextStyles.bodySmall),
        trailing: TextButton.icon(
          onPressed: hasPhone ? onSend : null,
          icon: const Icon(Icons.chat, size: 18),
          label: Text(sent ? 'Reenviar' : 'Enviar'),
        ),
      ),
    );
  }
}

// ── Modelos ───────────────────────────────────────────────────────────────

class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  bool _isDefault(String id) => kDefaultTemplates.any((t) => t.id == id);

  Future<void> _save(WidgetRef ref, List<MessageTemplate> list) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    await ref.read(messageTemplateRepositoryProvider).save(user.id, list);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref,
      List<MessageTemplate> list, MessageTemplate? t) async {
    final result = await showDialog<MessageTemplate>(
      context: context,
      builder: (_) => _TemplateDialog(template: t),
    );
    if (result == null) return;
    final next = [...list];
    final i = next.indexWhere((x) => x.id == result.id);
    if (i >= 0) {
      next[i] = result;
    } else {
      next.add(result);
    }
    await _save(ref, next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(messageTemplatesProvider).value ?? kDefaultTemplates;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Use {nome} para o primeiro nome do aluno e {personal} para o seu nome. '
          'Os modelos "Aniversário" e "Senti sua falta" também são usados nas Atualizações.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        for (final t in list)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: () => _edit(context, ref, list, t),
              title: Text(t.title, style: AppTextStyles.bodyLarge),
              subtitle: Text(t.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall),
              trailing: _isDefault(t.id)
                  ? const Icon(Icons.edit, color: AppColors.textTertiary)
                  : IconButton(
                      tooltip: 'Apagar modelo',
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.textTertiary),
                      onPressed: () =>
                          _save(ref, list.where((x) => x.id != t.id).toList()),
                    ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.surfaceLight)),
          onPressed: () => _edit(context, ref, list, null),
          icon: const Icon(Icons.add),
          label: const Text('Novo modelo'),
        ),
        TextButton(
          onPressed: () => _save(ref, kDefaultTemplates),
          child: const Text('Restaurar modelos padrão'),
        ),
      ],
    );
  }
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.template});
  final MessageTemplate? template;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  late final _title = TextEditingController(text: widget.template?.title ?? '');
  late final _text = TextEditingController(text: widget.template?.text ?? 'Oi, {nome}! ');

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.template == null ? 'Novo modelo' : 'Editar modelo'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _title,
                style: AppTextStyles.bodyLarge,
                decoration: _dec('Título')),
            const SizedBox(height: 12),
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 8,
              style: AppTextStyles.bodyMedium,
              decoration: _dec('Mensagem'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            if (_title.text.trim().isEmpty || _text.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              MessageTemplate(
                id: widget.template?.id ??
                    'custom_${DateTime.now().millisecondsSinceEpoch}',
                title: _title.text.trim(),
                text: _text.text.trim(),
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
