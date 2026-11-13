import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/whatsapp.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trainer/domain/entities/student_entity.dart';
import '../../data/payment_repository.dart';

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _day = DateFormat('dd/MM/yyyy');

/// Cor de cada situação de mensalidade.
Color paymentStatusColor(PaymentStatus s) => switch (s) {
      PaymentStatus.paid => AppColors.success,
      PaymentStatus.pending => AppColors.warning,
      PaymentStatus.overdue => AppColors.error,
      PaymentStatus.exempt => AppColors.info,
    };

/// Texto curto do vencimento: "vence hoje", "vence em 3 dias", "atrasado há 4 dias".
String dueLabel(StudentEntity s) {
  final days = s.daysUntilDue;
  if (s.paymentStatus == PaymentStatus.exempt) return 'Isento';
  if (days == null) return 'Sem vencimento definido';
  if (days == 0) return 'Vence hoje';
  if (days == 1) return 'Vence amanhã';
  if (days > 1) return 'Vence em $days dias (${_day.format(s.nextPaymentDate!)})';
  final late = -days;
  return 'Atrasado há $late dia${late == 1 ? '' : 's'} (${_day.format(s.nextPaymentDate!)})';
}

/// Abre o WhatsApp com uma mensagem de lembrete da mensalidade.
Future<void> chargeOnWhatsApp(BuildContext context, StudentEntity s,
    {String? trainerName}) async {
  final name = firstName(s.name);
  final amount = s.monthlyFee == null
      ? ''
      : ' de ${_money.format(s.monthlyFee! * s.planMonths)}';
  final due = s.nextPaymentDate == null ? '' : ' (vencimento ${_day.format(s.nextPaymentDate!)})';
  final days = s.daysUntilDue ?? 0;
  final intro = days < 0
      ? 'Consta em aberto a sua mensalidade$amount$due.'
      : 'Passando para lembrar da sua mensalidade$amount$due.';
  final sign = (trainerName == null || trainerName.isEmpty) ? '' : '\n$trainerName';
  final text = 'Olá, $name! Tudo bem? $intro '
      'Qualquer dúvida é só me chamar. Obrigado!$sign';
  await openWhatsApp(context, s.phone, text);
}

/// Abre o formulário de registro de pagamento. Retorna true se registrou.
Future<bool> showRegisterPaymentSheet(
    BuildContext context, StudentEntity student) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RegisterPaymentSheet(student: student),
  );
  return result ?? false;
}

class _RegisterPaymentSheet extends ConsumerStatefulWidget {
  const _RegisterPaymentSheet({required this.student});
  final StudentEntity student;

  @override
  ConsumerState<_RegisterPaymentSheet> createState() =>
      _RegisterPaymentSheetState();
}

class _RegisterPaymentSheetState extends ConsumerState<_RegisterPaymentSheet> {
  late final TextEditingController _amount;
  final _notes = TextEditingController();
  late int _months;
  late DateTime _paidAt;
  String _method = kPaymentMethods.first;
  bool _saving = false;

  StudentEntity get s => widget.student;

  @override
  void initState() {
    super.initState();
    _months = s.planMonths;
    final now = DateTime.now();
    _paidAt = DateTime(now.year, now.month, now.day);
    _amount = TextEditingController(text: _suggested(_months));
  }

  String _suggested(int months) => s.monthlyFee == null || s.monthlyFee == 0
      ? ''
      : (s.monthlyFee! * months).toStringAsFixed(2);

  DateTime get _newDue {
    final base = s.nextPaymentDate ?? _paidAt;
    return addMonths(DateTime(base.year, base.month, base.day), _months);
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o valor recebido.')));
      return;
    }
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(paymentRepositoryProvider).register(
            student: s,
            trainerId: user.id,
            amount: amount,
            paidAt: _paidAt,
            months: _months,
            method: _method,
            notes: _notes.text,
          );
      nav.pop(true);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
            'Pagamento registrado. Próximo vencimento: ${_day.format(_newDue)}'),
      ));
    } catch (e) {
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text('Não foi possível registrar: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = {1, 3, 6, 12, _months}.toList()..sort();
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Registrar pagamento',
                      style: AppTextStyles.headlineMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Text(s.name,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyLarge,
              decoration: _input('Valor recebido (R\$)', Icons.attach_money),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _input('Pago em', Icons.event),
                      child: Text(_day.format(_paidAt),
                          style: AppTextStyles.bodyLarge),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: _input('Meses pagos', Icons.date_range),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _months,
                        isDense: true,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: AppTextStyles.bodyLarge,
                        items: [
                          for (final m in months)
                            DropdownMenuItem(
                                value: m,
                                child: Text(m == 1 ? '1 mês' : '$m meses')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _months = v;
                            final sug = _suggested(v);
                            if (sug.isNotEmpty) _amount.text = sug;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Forma de pagamento',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in kPaymentMethods)
                  ChoiceChip(
                    label: Text(m),
                    selected: _method == m,
                    selectedColor: AppColors.teal,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                        color: _method == m
                            ? Colors.white
                            : AppColors.textSecondary),
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              style: AppTextStyles.bodyLarge,
              decoration: _input('Observação (opcional)', Icons.notes),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Próximo vencimento passa a ser ${_day.format(_newDue)}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.lightTeal),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: const Text('CONFIRMAR PAGAMENTO'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.surfaceLight),
        ),
      );
}

/// Linha de um pagamento no histórico.
class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.payment,
    this.showStudent = false,
    this.onDelete,
    this.onTap,
  });

  final PaymentEntity payment;
  final bool showStudent;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final period = p.monthsCovered == 1 ? '1 mês' : '${p.monthsCovered} meses';
    final subtitle = [
      _day.format(p.paidAt),
      p.method,
      period,
      if (p.notes != null) p.notes!,
    ].join(' · ');
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: CircleAvatar(
        backgroundColor: AppColors.surfaceLight,
        child: Icon(Icons.arrow_downward, color: AppColors.success, size: 20),
      ),
      title: Text(showStudent ? p.studentName : _money.format(p.amount),
          style: AppTextStyles.bodyLarge),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
      trailing: showStudent
          ? Text(_money.format(p.amount),
              style:
                  AppTextStyles.headlineSmall.copyWith(color: AppColors.success))
          : (onDelete == null
              ? null
              : IconButton(
                  tooltip: 'Apagar pagamento',
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.textTertiary),
                  onPressed: onDelete,
                )),
    );
  }
}

/// Confirma e apaga um pagamento (o vencimento volta, se for o último).
Future<void> confirmDeletePayment(BuildContext context, WidgetRef ref,
    PaymentEntity payment, StudentEntity student) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Apagar pagamento?'),
      content: Text(
          '${_money.format(payment.amount)} pago em ${_day.format(payment.paidAt)}.\n'
          'Se for o último pagamento registrado, o vencimento volta a ser '
          '${payment.previousDueDate == null ? 'o anterior' : _day.format(payment.previousDueDate!)}.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar',
                style: TextStyle(color: AppColors.error))),
      ],
    ),
  );
  if (ok != true) return;
  await ref.read(paymentRepositoryProvider).delete(payment, student);
}
