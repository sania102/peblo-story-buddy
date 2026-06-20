/// QuizQuestion is intentionally option-count agnostic.
///
/// The brief requires the renderer to handle 3, 4, or 5 options (or any count)
/// without code changes. We enforce that by NEVER indexing options positionally
/// in the UI layer (no option1/option2/option3 fields) - we always iterate over
/// a List<String>. This model is the single source of truth for "what shape does
/// a quiz question have", so if the backend team changes the JSON shape later,
/// only this file needs to change.
class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    if (rawOptions is! List || rawOptions.isEmpty) {
      throw FormatException('Quiz JSON missing a non-empty "options" list');
    }

    final options = rawOptions.map((e) => e.toString()).toList();
    final question = json['question']?.toString() ?? '';
    final answer = json['answer']?.toString() ?? '';

    if (question.isEmpty) {
      throw const FormatException('Quiz JSON missing "question" field');
    }
    if (!options.contains(answer)) {
      // Defensive check: if backend sends an answer that isn't actually one
      // of the options, fail loudly in dev rather than silently making the
      // quiz unwinnable.
      throw FormatException(
        'Quiz JSON "answer" ($answer) is not present in "options" list',
      );
    }

    return QuizQuestion(
      question: question,
      options: options,
      answer: answer,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answer': answer,
      };
}
