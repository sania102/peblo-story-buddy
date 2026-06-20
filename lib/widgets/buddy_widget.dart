import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum BuddyMood { idle, listening, happy, sad }

/// A simple vector-drawn buddy (no PNG/Lottie asset dependency, so the repo
/// is self-contained and doesn't need an art drop to demo). Swap this out
/// for a real illustration/Lottie file later - the API (mood + bounce) stays
/// the same either way, so design can hand over assets without touching
/// any other widget.
class BuddyWidget extends StatefulWidget {
  final BuddyMood mood;
  const BuddyWidget({super.key, required this.mood});

  @override
  State<BuddyWidget> createState() => _BuddyWidgetState();
}

class _BuddyWidgetState extends State<BuddyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldBounce = widget.mood != BuddyMood.sad;

    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final bounce = shouldBounce ? _bounceController.value * 8 : 0.0;
        return Transform.translate(
          offset: Offset(0, -bounce),
          child: child,
        );
      },
      child: AnimatedScale(
        scale: widget.mood == BuddyMood.happy ? 1.12 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: _buildFace(),
      ),
    );
  }

  Widget _buildFace() {
    final Color bodyColor = widget.mood == BuddyMood.sad
        ? AppColors.textMuted
        : AppColors.primary;

    return SizedBox(
      width: 132,
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Antenna - a small detail that reads as "robot" at a glance,
          // matching Pip's character without needing an illustrated asset.
          Positioned(
            top: 0,
            child: Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 0),
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: bodyColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bodyColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(top: 38, left: 26, child: _eye()),
                  Positioned(top: 38, right: 26, child: _eye()),
                  Positioned(bottom: 30, child: _mouth()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eye() => Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

  Widget _mouth() {
    switch (widget.mood) {
      case BuddyMood.happy:
        return Container(
          width: 36,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
        );
      case BuddyMood.sad:
        return Container(
          width: 30,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        );
      case BuddyMood.listening:
        return Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        );
      case BuddyMood.idle:
        return Container(
          width: 24,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    }
  }
}
