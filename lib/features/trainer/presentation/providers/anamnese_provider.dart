import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnamneseState {
  final List<String> questions;
  final Map<String, Map<int, String>> studentAnswers; // studentId -> {questionIndex: answer}

  const AnamneseState({
    this.questions = const [
      'Quais seus objetivos principais?',
      'Doenças crônicas ou histórico médico?',
      'Lesões atuais ou passadas?',
      'Nível de atividade física / Rotina diária',
      'Observações gerais'
    ],
    this.studentAnswers = const {},
  });

  AnamneseState copyWith({
    List<String>? questions,
    Map<String, Map<int, String>>? studentAnswers,
  }) {
    return AnamneseState(
      questions: questions ?? this.questions,
      studentAnswers: studentAnswers ?? this.studentAnswers,
    );
  }
}

class AnamneseNotifier extends Notifier<AnamneseState> {
  @override
  AnamneseState build() {
    return _mockState();
  }

  void saveQuestions(List<String> newQuestions) {
    state = state.copyWith(questions: newQuestions);
  }

  // Método usado pelo aluno para salvar as respostas (será usado na visão do aluno futuramente)
  void saveAnswers(String studentId, Map<int, String> answers) {
    final updatedAnswers = Map<String, Map<int, String>>.from(state.studentAnswers);
    updatedAnswers[studentId] = answers;
    state = state.copyWith(studentAnswers: updatedAnswers);
  }

  AnamneseState _mockState() {
    // Simulando respostas de alguns alunos mockados do dashboard
    final mockAnswers = {
      '1': {
        0: 'Hipertrofia e melhora no condicionamento.',
        1: 'Nenhum problema crônico.',
        2: 'Dor leve no ombro esquerdo de vez em quando.',
        3: 'Trabalho sentado o dia todo. Treino 4x na semana.',
        4: 'Nenhuma observação.',
      },
      '2': {
        0: 'Emagrecimento.',
        1: 'Asma leve.',
        2: 'Nenhuma lesão.',
        3: 'Sedentária, começando agora.',
        4: 'Gostaria de foco em exercícios aeróbicos no início.',
      }
    };

    return AnamneseState(studentAnswers: mockAnswers);
  }
}

final anamneseProvider = NotifierProvider<AnamneseNotifier, AnamneseState>(() {
  return AnamneseNotifier();
});
