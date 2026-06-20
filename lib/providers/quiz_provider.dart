import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';

enum QuizState { unanswered, wrong, correct }

class QuizProvider extends ChangeNotifier {
  QuizQuestion? _question;
  QuizState _state = QuizState.unanswered;
  String? _selectedOption;
  int _attempts = 0;

  QuizQuestion? get question => _question;
  QuizState get state => _state;
  String? get selectedOption => _selectedOption;
  int get attempts => _attempts;

  /// Load any quiz question - this is the one method the rest of the app
  /// calls, and it works identically whether the JSON has 3, 4, or 5
  /// options. Nothing downstream needs to know the option count ahead of
  /// time.
  void loadQuestion(Map<String, dynamic> json) {
    _question = QuizQuestion.fromJson(json);
    _state = QuizState.unanswered;
    _selectedOption = null;
    _attempts = 0;
    notifyListeners();
  }

  void selectOption(String option) {
    if (_question == null || _state == QuizState.correct) return;

    _selectedOption = option;
    _attempts++;

    if (option == _question!.answer) {
      _state = QuizState.correct;
    } else {
      _state = QuizState.wrong;
    }
    notifyListeners();
  }

  /// Called after the shake animation finishes so the child can try again
  /// without the card looking "stuck" on the wrong state.
  void resetForRetry() {
    if (_state == QuizState.wrong) {
      _state = QuizState.unanswered;
      _selectedOption = null;
      notifyListeners();
    }
  }

  void reset() {
    _question = null;
    _state = QuizState.unanswered;
    _selectedOption = null;
    _attempts = 0;
    notifyListeners();
  }
}
