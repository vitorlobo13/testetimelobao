import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/feedback_repository.dart';

/// Perguntas frequentes do personal.
const _faq = <(String, String)>[
  (
    'Como cadastro um aluno?',
    'Toque em "Novo Aluno" na tela inicial, preencha os dados e salve. Em seguida '
        'o app mostra o convite: envie pelo WhatsApp. O aluno abre o link, cria a '
        'senha e já entra vinculado a você. O convite vale 7 dias; se vencer, gere '
        'outro na ficha do aluno (ícone de convite no topo).'
  ),
  (
    'Como prescrevo um treino?',
    'Na ficha do aluno, toque em "Prescrever treino". Você pode começar do zero, '
        'importar um modelo da Biblioteca de Treinos, definir a validade e montar '
        'conjugados (bi/tri-set). O aluno recebe um aviso quando o treino novo fica ativo.'
  ),
  (
    'Como reaproveito um treino em outro aluno?',
    'Na aba Treinos da ficha, use "Duplicar para outro aluno" no treino ativo ou '
        '"Usar como base" em um treino antigo.'
  ),
  (
    'O que é a tela de Atualizações?',
    'É o ícone ao lado do sininho. Ela lista o que você precisa fazer em cada aluno: '
        'treinos vencendo, alunos sem treino ou sem treinar, aniversários, avaliações '
        'a refazer e mensalidades atrasadas. Os itens somem sozinhos quando você '
        'resolve. Os prazos são ajustados em Configurações.'
  ),
  (
    'Como registro um pagamento?',
    'Em Gestão Financeira (ou na aba Pagamentos do aluno) toque em "Recebido". O '
        'próximo vencimento avança sozinho conforme o plano. Se registrar errado, '
        'apague o pagamento: o vencimento volta ao que era.'
  ),
  (
    'Como cobro um aluno atrasado?',
    'Toque em "Cobrar": o WhatsApp abre com uma mensagem pronta com valor e '
        'vencimento. O app não faz cobrança automática, só controle.'
  ),
  (
    'Como envio mensagens para vários alunos?',
    'Em Marketing, escolha um modelo de mensagem e o grupo de alunos. O WhatsApp '
        'não permite envio em massa, então você toca em cada aluno e a conversa abre '
        'com a mensagem já personalizada.'
  ),
  (
    'Como recebo avisos no celular?',
    'Toque em "Ativar" no cartão "Receber avisos no celular". No iPhone, antes '
        'adicione o app à tela inicial (Safari → Compartilhar → Adicionar à Tela de '
        'Início) e ative por lá.'
  ),
  (
    'Um aluno foi para outro personal. E agora?',
    'Quando ele aceita o convite de outro personal, o vínculo com você é arquivado: '
        'ele some das suas listas, mas o histórico fica guardado.'
  ),
  (
    'Como excluo os dados de um aluno?',
    'Na ficha do aluno, menu ⋮ → Excluir. Todos os dados dele (treinos, avaliações, '
        'dietas, pagamentos) são apagados de forma definitiva, como prevê a LGPD.'
  ),
];

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('AJUDA E SUPORTE', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('PERGUNTAS FREQUENTES',
              style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (final (q, a) in _faq)
                    ExpansionTile(
                      iconColor: AppColors.lightTeal,
                      collapsedIconColor: AppColors.textSecondary,
                      title: Text(q, style: AppTextStyles.bodyLarge),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(a,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _FeedbackForm(),
        ],
      ),
    );
  }
}

class _FeedbackForm extends ConsumerStatefulWidget {
  const _FeedbackForm();

  @override
  ConsumerState<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends ConsumerState<_FeedbackForm> {
  final _message = TextEditingController();
  String _type = kFeedbackTypes.first;
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_message.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escreva sua mensagem.')));
      return;
    }
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(feedbackRepositoryProvider).send(
            uid: user.id,
            name: user.name,
            email: user.email,
            role: user.userType.name,
            type: _type,
            message: _message.text,
          );
      _message.clear();
      messenger.showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Mensagem enviada. Obrigado!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Não foi possível enviar: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.support_agent, color: AppColors.lightTeal),
            const SizedBox(width: 8),
            Text('Fale com a gente', style: AppTextStyles.headlineSmall),
          ]),
          const SizedBox(height: 4),
          Text('Dúvidas, erros ou ideias para o app. A equipe responde pelo WhatsApp.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final t in kFeedbackTypes)
                ChoiceChip(
                  label: Text(t),
                  selected: _type == t,
                  selectedColor: AppColors.teal,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                      color: _type == t
                          ? Colors.white
                          : AppColors.textSecondary),
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 8,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Conte o que aconteceu ou o que gostaria de ter no app',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: const Text('ENVIAR'),
            ),
          ),
        ],
      ),
    );
  }
}
