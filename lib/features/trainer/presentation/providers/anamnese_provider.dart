import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/assessment_repository.dart';

final anamneseRepositoryProvider =
    Provider<AnamneseRepository>((ref) => AnamneseRepository());

/// Anamnese de um aluno (perguntas enviadas + respostas), em tempo real.
final studentAnamneseProvider =
    StreamProvider.family<StudentAnamnese?, String>(
  (ref, linkId) => ref.watch(anamneseRepositoryProvider).watch(linkId),
);

class AnamneseState {
  /// Formulário padrão do personal (o que é enviado aos alunos).
  final List<String> questions;

  const AnamneseState({this.questions = AnamneseRepository.defaultQuestions});

  AnamneseState copyWith({List<String>? questions}) =>
      AnamneseState(questions: questions ?? this.questions);
}

/// Formulário de anamnese do personal (`trainers/{uid}/meta/anamnese`).
class AnamneseNotifier extends Notifier<AnamneseState> {
  StreamSubscription<List<String>>? _sub;

  AnamneseRepository get _repo => ref.read(anamneseRepositoryProvider);

  String? get _trainerId {
    final user = ref.read(authProvider).user;
    return (user != null && user.isTrainer) ? user.id : null;
  }

  @override
  AnamneseState build() {
    ref.onDispose(() => _sub?.cancel());
    final trainerId = _trainerId;
    if (trainerId != null) {
      _sub = _repo
          .watchTemplate(trainerId)
          .listen((q) => state = state.copyWith(questions: q));
    }
    return const AnamneseState();
  }

  Future<void> saveQuestions(List<String> newQuestions) async {
    final trainerId = _trainerId;
    if (trainerId == null) return;
    state = state.copyWith(questions: newQuestions);
    await _repo.saveTemplate(trainerId, newQuestions);
  }

  /// Envia o formulário atual para o aluno responder no app dele.
  Future<void> sendToStudent(String linkId) =>
      _repo.sendToStudent(linkId, state.questions);

  /// Salva respostas (aluno no app, ou personal preenchendo com o aluno).
  Future<void> saveAnswers(String linkId, Map<int, String> answers) =>
      _repo.saveAnswers(linkId, answers);
}

final anamneseProvider = NotifierProvider<AnamneseNotifier, AnamneseState>(() {
  return AnamneseNotifier();
});
