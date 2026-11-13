import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';

/// Modelo de mensagem de WhatsApp do personal. `{nome}` vira o primeiro
/// nome do aluno e `{personal}` o nome do personal.
class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.title,
    required this.text,
  });

  final String id;
  final String title;
  final String text;

  MessageTemplate copyWith({String? title, String? text}) =>
      MessageTemplate(id: id, title: title ?? this.title, text: text ?? this.text);

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'text': text};

  static MessageTemplate fromMap(Map<String, dynamic> m) => MessageTemplate(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        text: m['text'] as String? ?? '',
      );

  /// Texto final para um aluno.
  String fill({required String studentName, required String trainerName}) {
    final first = studentName.trim().split(RegExp(r'\s+')).first;
    return text
        .replaceAll('{nome}', first)
        .replaceAll('{personal}', trainerName)
        .trim();
  }
}

/// Ids fixos usados por outras telas (Atualizações).
abstract final class TemplateIds {
  static const welcome = 'boas_vindas';
  static const birthday = 'aniversario';
  static const missYou = 'sumido';
  static const referral = 'indicacao';
  static const assessment = 'avaliacao';
  static const promo = 'promocao';
}

const kDefaultTemplates = <MessageTemplate>[
  MessageTemplate(
    id: TemplateIds.welcome,
    title: 'Boas-vindas',
    text: 'Olá, {nome}! Seja muito bem-vindo(a) ao time! 💪 '
        'Seu treino já está no app. Qualquer dúvida é só me chamar.\n{personal}',
  ),
  MessageTemplate(
    id: TemplateIds.birthday,
    title: 'Aniversário',
    text: 'Parabéns, {nome}! 🎉 Muita saúde, energia e conquistas nesse novo '
        'ciclo. Conte comigo nos treinos!\n{personal}',
  ),
  MessageTemplate(
    id: TemplateIds.missYou,
    title: 'Senti sua falta',
    text: 'Oi, {nome}! Tudo bem? Senti sua falta nos treinos. Bora voltar? '
        'Se precisar ajustar algo no treino, me avisa!\n{personal}',
  ),
  MessageTemplate(
    id: TemplateIds.referral,
    title: 'Indicação',
    text: 'Oi, {nome}! Conhece alguém que quer começar a treinar? '
        'Indicando um amigo, vocês dois ganham um benefício especial. '
        'Me chama para saber mais!\n{personal}',
  ),
  MessageTemplate(
    id: TemplateIds.assessment,
    title: 'Lembrete de avaliação',
    text: 'Oi, {nome}! Está na hora da sua reavaliação física para '
        'acompanharmos sua evolução. Qual o melhor dia para você?\n{personal}',
  ),
  MessageTemplate(
    id: TemplateIds.promo,
    title: 'Promoção',
    text: 'Oi, {nome}! Tenho uma condição especial este mês para '
        'renovação do plano. Quer saber os detalhes?\n{personal}',
  ),
];

/// Modelos em `trainers/{uid}/meta/marketing` (padrões até o personal editar).
class MessageTemplateRepository {
  MessageTemplateRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.doc('trainers/$uid/meta/marketing');

  Stream<List<MessageTemplate>> watch(String uid) =>
      _doc(uid).snapshots().map((s) {
        final raw = s.data()?['templates'];
        if (raw is! List || raw.isEmpty) return kDefaultTemplates;
        return raw
            .whereType<Map>()
            .map((m) => MessageTemplate.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      });

  Future<void> save(String uid, List<MessageTemplate> templates) =>
      _doc(uid).set({
        'templates': templates.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

final messageTemplateRepositoryProvider =
    Provider<MessageTemplateRepository>((ref) => MessageTemplateRepository());

final messageTemplatesProvider = StreamProvider<List<MessageTemplate>>((ref) {
  final user = ref.watch(authProvider).user;
  if (user == null || !user.isTrainer) return Stream.value(kDefaultTemplates);
  return ref.watch(messageTemplateRepositoryProvider).watch(user.id);
});

/// Modelo pelo id (cai no padrão se o personal apagou).
MessageTemplate templateById(List<MessageTemplate> list, String id) =>
    list.where((t) => t.id == id).firstOrNull ??
    kDefaultTemplates.firstWhere((t) => t.id == id);
