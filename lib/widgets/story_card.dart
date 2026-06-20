import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../utils/app_theme.dart';

class StoryCard extends StatelessWidget {
  final String storyText;
  const StoryCard({super.key, required this.storyText});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(24),
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
              Text(storyText, style: AppTextStyles.storyText),
              const SizedBox(height: 18),
              _buildActionRow(context, audio),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionRow(BuildContext context, AudioProvider audio) {
    switch (audio.state) {
      case AudioState.loading:
        return Row(
          children: const [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Getting the story ready...',
              style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        );

      case AudioState.playing:
        return Row(
          children: const [
            Icon(Icons.graphic_eq_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text(
              'Pip is telling the story...',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ],
        );

      case AudioState.error:
        return Row(
          children: [
            Expanded(
              child: Text(
                audio.errorMessage ?? 'Something went wrong. Let\'s try again!',
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => audio.retry(storyText),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );

      case AudioState.finished:
        return _readButton(audio, label: 'Read It Again', icon: Icons.replay_rounded);

      case AudioState.idle:
        return _readButton(audio, label: 'Read Me a Story', icon: Icons.menu_book_rounded);
    }
  }

  Widget _readButton(AudioProvider audio, {required String label, required IconData icon}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => audio.speak(storyText),
        icon: Icon(icon, size: 20),
        label: Text(label, style: AppTextStyles.button),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
