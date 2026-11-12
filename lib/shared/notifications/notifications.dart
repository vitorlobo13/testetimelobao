import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'push_service.dart';

/// Notificação mostrada dentro do app (`users/{uid}/notifications`).
/// As Cloud Functions criam; o usuário só lê, marca como lida ou apaga.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime createdAt;
}

CollectionReference<Map<String, dynamic>> _collection(String uid) =>
    FirebaseFirestore.instance.collection('users/$uid/notifications');

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authProvider.select((a) => a.user?.id));
  if (uid == null) return Stream.value(const []);
  return _collection(uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = d.data();
            final created = data['createdAt'];
            return AppNotification(
              id: d.id,
              title: data['title'] as String? ?? '',
              body: data['body'] as String? ?? '',
              type: data['type'] as String? ?? '',
              read: data['read'] as bool? ?? false,
              createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
            );
          }).toList());
});

/// Sino com contador de não lidas; abre a lista de notificações.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
            .watch(notificationsProvider)
            .value
            ?.where((n) => !n.read)
            .length ??
        0;
    return IconButton(
      tooltip: 'Notificações',
      color: AppColors.textPrimary,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        backgroundColor: AppColors.error,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider.select((a) => a.user?.id));
    final notifications = ref.watch(notificationsProvider);

    Future<void> markAllRead(List<AppNotification> list) async {
      if (uid == null) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final n in list.where((n) => !n.read)) {
        batch.update(_collection(uid).doc(n.id), {'read': true});
      }
      await batch.commit();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('NOTIFICAÇÕES', style: AppTextStyles.headlineMedium),
        actions: [
          if (notifications.value?.any((n) => !n.read) ?? false)
            TextButton(
              onPressed: () => markAllRead(notifications.value!),
              child: const Text('Marcar todas como lidas'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Text('Nenhuma notificação por aqui.',
                    style: AppTextStyles.bodyMedium),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.surfaceLight),
                itemBuilder: (context, i) {
                  final n = list[i];
                  return Dismissible(
                    key: ValueKey(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: AppColors.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      if (uid != null) _collection(uid).doc(n.id).delete();
                    },
                    child: ListTile(
                      tileColor: n.read ? null : AppColors.teal.withValues(alpha: 0.08),
                      leading: Icon(
                        n.type == 'session_completed'
                            ? Icons.emoji_events
                            : Icons.fitness_center,
                        color: n.read ? AppColors.textTertiary : AppColors.lightTeal,
                      ),
                      title: Text(n.title, style: AppTextStyles.bodyLarge),
                      subtitle: Text(
                        '${n.body}\n${DateFormat("dd/MM 'às' HH:mm").format(n.createdAt)}',
                        style: AppTextStyles.bodySmall,
                      ),
                      isThreeLine: true,
                      onTap: () {
                        if (uid != null && !n.read) {
                          _collection(uid).doc(n.id).update({'read': true});
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService());

/// Cartão "Receber avisos no celular". Some quando o push já está ativo.
/// Se a permissão já foi dada antes, só renova o registro do aparelho.
class PushPromptCard extends ConsumerStatefulWidget {
  const PushPromptCard({super.key});

  @override
  ConsumerState<PushPromptCard> createState() => _PushPromptCardState();
}

class _PushPromptCardState extends ConsumerState<PushPromptCard> {
  bool _visible = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_check);
  }

  Future<void> _check() async {
    final uid = ref.read(authProvider).user?.id;
    final push = ref.read(pushServiceProvider);
    if (uid == null || !await push.isSupported()) return;
    if (await push.isGranted()) {
      await push.registerToken(uid);
      return;
    }
    if (mounted) setState(() => _visible = true);
  }

  Future<void> _enable() async {
    final uid = ref.read(authProvider).user?.id;
    if (uid == null) return;
    setState(() => _busy = true);
    final ok = await ref.read(pushServiceProvider).enable(uid);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _visible = !ok;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Pronto! Você vai receber os avisos neste aparelho.'
          : 'As notificações foram bloqueadas. Libere nas configurações do navegador.'),
      backgroundColor: ok ? AppColors.success : AppColors.warning,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.lightTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Receber avisos no celular', style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  'No iPhone, adicione o app à tela inicial antes de ativar.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _enable,
            child: _busy
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('ATIVAR'),
          ),
          IconButton(
            tooltip: 'Agora não',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _visible = false),
          ),
        ],
      ),
    );
  }
}
