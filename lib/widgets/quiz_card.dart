import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../utils/app_theme.dart';

class QuizCard extends StatefulWidget {
  /// 1-based index of the current question, for the "Question 1 of 3" label.
  final int questionNumber;
  final int totalQuestions;

  /// Whether there's another question after this one in the quiz bank.
  final bool hasNextQuestion;

  /// Called when the child taps "Next Question" after answering correctly.
  final VoidCallback onNextQuestion;

  const QuizCard({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
    required this.hasNextQuestion,
    required this.onNextQuestion,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onOptionTap(BuildContext context, String option) {
    final quiz = context.read<QuizProvider>();
    quiz.selectOption(option);

    if (quiz.state == QuizState.wrong) {
      HapticFeedback.mediumImpact();
      _shakeController.forward(from: 0).whenComplete(() {
        // Give the child a beat to register the shake before re-enabling
        // the card, then reset so they can try again.
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) quiz.resetForRetry();
        });
      });
    } else if (quiz.state == QuizState.correct) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quiz, _) {
        final question = quiz.question;
        if (question == null) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: quiz.state == QuizState.wrong
                    ? AppColors.error.withOpacity(0.5)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${widget.questionNumber} of ${widget.totalQuestions}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.quiz_rounded, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(question.question, style: AppTextStyles.heading.copyWith(fontSize: 19)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // *** This is the data-driven part: we map over options.
                // Works identically for length 3, 4, 5, or N. ***
                ...question.options.map((option) => _OptionTile(
                      option: option,
                      onTap: () => _onOptionTap(context, option),
                    )),
                if (quiz.state == QuizState.correct) ...[
                  const _SuccessBanner(),
                  const SizedBox(height: 14),
                  _buildNextAction(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shown only in the QuizState.correct state. Either advances to the next
  /// question in the bank, or - on the last question - shows a finishing
  /// "All done!" message instead of a dead-end button.
  Widget _buildNextAction() {
    if (widget.hasNextQuestion) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onNextQuestion,
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: Text('Next Question', style: AppTextStyles.button),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        "All done — great job today! 🎉",
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final VoidCallback onTap;
  const _OptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quiz, _) {
        final isSelected = quiz.selectedOption == option;
        final isCorrectAnswer = quiz.question?.answer == option;
        final revealCorrect = quiz.state == QuizState.correct && isCorrectAnswer;
        final markWrong = isSelected && quiz.state == QuizState.wrong;

        Color bg = AppColors.background;
        Color border = Colors.transparent;
        Color text = AppColors.textDark;

        if (revealCorrect) {
          bg = AppColors.success.withOpacity(0.15);
          border = AppColors.success;
          text = AppColors.success;
        } else if (markWrong) {
          bg = AppColors.error.withOpacity(0.12);
          border = AppColors.error;
          text = AppColors.error;
        }

        final bool disabled = quiz.state == QuizState.correct;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(fontWeight: FontWeight.w700, color: text, fontSize: 15.5),
                    ),
                  ),
                  if (revealCorrect)
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  if (markWrong)
                    const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: const [
          Icon(Icons.celebration_rounded, color: AppColors.success),
          SizedBox(width: 8),
          Text(
            'Yay! You got it right!',
            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
