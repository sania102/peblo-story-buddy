import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'providers/quiz_provider.dart';
import 'screens/story_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const PebloStoryBuddyApp());
}

class PebloStoryBuddyApp extends StatelessWidget {
  const PebloStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider (not .value) so the provider's lifecycle is
        // owned and disposed by the widget tree - this is what guarantees
        // AudioProvider.dispose() (which stops the TTS engine and detaches
        // handlers) actually runs instead of leaking.
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: 'Peblo Story Buddy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          fontFamily: 'Roboto',
        ),
        home: const StoryScreen(),
      ),
    );
  }
}
