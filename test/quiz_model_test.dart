import 'package:flutter_test/flutter_test.dart';
import 'package:peblo_story_buddy/models/quiz_model.dart';
import 'package:peblo_story_buddy/providers/quiz_provider.dart';

void main() {
  group('QuizQuestion.fromJson', () {
    test('parses the brief\'s exact 4-option payload', () {
      final q = QuizQuestion.fromJson({
        "question": "What colour was Pip the Robot's lost gear?",
        "options": ["Red", "Green", "Blue", "Yellow"],
        "answer": "Blue",
      });
      expect(q.options.length, 4);
      expect(q.answer, "Blue");
    });

    test('handles a 3-option question with zero code changes', () {
      final q = QuizQuestion.fromJson({
        "question": "Is the sky blue?",
        "options": ["Yes", "No", "Sometimes"],
        "answer": "Yes",
      });
      expect(q.options.length, 3);
    });

    test('handles a 5-option question with zero code changes', () {
      final q = QuizQuestion.fromJson({
        "question": "Pick the warmest colour",
        "options": ["Blue", "Green", "Red", "Orange", "Purple"],
        "answer": "Orange",
      });
      expect(q.options.length, 5);
    });

    test('throws if answer is not among options (bad backend data)', () {
      expect(
        () => QuizQuestion.fromJson({
          "question": "Broken?",
          "options": ["A", "B"],
          "answer": "C",
        }),
        throwsFormatException,
      );
    });

    test('throws if options list is empty', () {
      expect(
        () => QuizQuestion.fromJson({
          "question": "Broken?",
          "options": [],
          "answer": "A",
        }),
        throwsFormatException,
      );
    });
  });

  group('QuizProvider', () {
    late QuizProvider provider;

    setUp(() {
      provider = QuizProvider();
      provider.loadQuestion({
        "question": "What colour was Pip the Robot's lost gear?",
        "options": ["Red", "Green", "Blue", "Yellow"],
        "answer": "Blue",
      });
    });

    test('selecting the correct option sets state to correct', () {
      provider.selectOption('Blue');
      expect(provider.state, QuizState.correct);
    });

    test('selecting a wrong option sets state to wrong and increments attempts', () {
      provider.selectOption('Red');
      expect(provider.state, QuizState.wrong);
      expect(provider.attempts, 1);
    });

    test('resetForRetry returns to unanswered after a wrong attempt', () {
      provider.selectOption('Red');
      provider.resetForRetry();
      expect(provider.state, QuizState.unanswered);
      expect(provider.selectedOption, isNull);
    });

    test('cannot change answer after correct (locked)', () {
      provider.selectOption('Blue');
      provider.selectOption('Red'); // should be ignored
      expect(provider.state, QuizState.correct);
    });
  });
}
