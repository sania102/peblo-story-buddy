import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/buddy_widget.dart';
import '../widgets/story_card.dart';
import '../widgets/quiz_card.dart';
import '../widgets/confetti_overlay.dart';
import '../utils/app_theme.dart';

const String kStoryText =
    "Once upon a time, a clever little robot named Pip lost his shiny blue gear in the Whispering Woods...";

// Simulates what would normally arrive from a backend call, one question at
// a time. The renderer (QuizCard + QuizQuestion) has zero knowledge of this
// list - swap it for a real `await api.getNextQuestion()` call and nothing
// else changes. Deliberately mixed option counts (4, 3, 5) to prove the
// renderer in quiz_card.dart truly doesn't care how many options it's given.
const List<Map<String, dynamic>> kQuizBank = [
  {
    "question": "What colour was Pip the Robot's lost gear?",
    "options": ["Red", "Green", "Blue", "Yellow"],
    "answer": "Blue",
  },
  {
    "question": "Where did Pip lose the gear?",
    "options": ["Whispering Woods", "Sunny Meadow", "Crystal Cave"],
    "answer": "Whispering Woods",
  },
  {
    "question": "What kind of character is Pip?",
    "options": ["A dragon", "A clever robot", "A wizard", "A fish", "A bird"],
    "answer": "A clever robot",
  },
];

class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  bool _quizRevealed = false;
  bool _playConfetti = false;
  AudioState? _lastAudioState;
  int _questionIndex = 0;

  bool get _hasNextQuestion => _questionIndex < kQuizBank.length - 1;

  void _goToNextQuestion(QuizProvider quiz) {
    setState(() {
      _questionIndex++;
      _playConfetti = false;
    });
    quiz.loadQuestion(kQuizBank[_questionIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
          onPressed: () {},
          tooltip: 'Menu',
        ),
        title: Text('AI Story Buddy', style: AppTextStyles.appBarTitle),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: AppColors.primary, size: 28),
            onPressed: () {},
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  // The audio->quiz transition lives here: a Consumer listens
                  // to AudioProvider, and the *moment* state flips to
                  // `finished`, we reveal the quiz with an AnimatedSwitcher-
                  // style fade+slide instead of an abrupt cut. We track
                  // _lastAudioState manually (rather than rebuilding the
                  // reveal flag every frame) so re-entering `finished` state
                  // doesn't replay the reveal animation unnecessarily.
                  Consumer<AudioProvider>(
                    builder: (context, audio, _) {
                      if (audio.state == AudioState.finished &&
                          _lastAudioState != AudioState.finished &&
                          !_quizRevealed) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => _quizRevealed = true);
                        });
                      }
                      _lastAudioState = audio.state;
                      return StoryCard(storyText: kStoryText);
                    },
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, animation) {
                      final offsetAnim = Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offsetAnim, child: child),
                      );
                    },
                    child: _quizRevealed
                        ? Consumer<QuizProvider>(
                            key: ValueKey('quiz_$_questionIndex'),
                            builder: (context, quiz, _) {
                              if (quiz.question == null) {
                                quiz.loadQuestion(kQuizBank[_questionIndex]);
                              }
                              // Trigger confetti exactly once per correct answer.
                              if (quiz.state == QuizState.correct && !_playConfetti) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setState(() => _playConfetti = true);
                                });
                              }
                              return QuizCard(
                                questionNumber: _questionIndex + 1,
                                totalQuestions: kQuizBank.length,
                                hasNextQuestion: _hasNextQuestion,
                                onNextQuestion: () => _goToNextQuestion(quiz),
                              );
                            },
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: ConfettiOverlay(
                play: _playConfetti,
                onComplete: () => setState(() => _playConfetti = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Consumer2<AudioProvider, QuizProvider>(
          builder: (context, audio, quiz, _) {
            BuddyMood mood = BuddyMood.idle;
            if (audio.state == AudioState.playing) mood = BuddyMood.listening;
            if (quiz.state == QuizState.correct) mood = BuddyMood.happy;
            if (audio.state == AudioState.error || quiz.state == QuizState.wrong) {
              mood = BuddyMood.sad;
            }
            return BuddyWidget(mood: mood);
          },
        ),
        const SizedBox(height: 12),
        Text('Story Time with Pip!', style: AppTextStyles.heading),
      ],
    );
  }
}
