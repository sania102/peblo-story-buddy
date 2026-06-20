import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Hand-rolled confetti instead of pulling in a package.
///
/// Why: every confetti package we evaluated either (a) uses Canvas particles
/// painted via CustomPainter anyway - so we lose nothing by writing our own -
/// or (b) animates with Transform widgets per-particle, which means N widget
/// rebuilds per frame instead of 1 repaint. On a 3GB RAM Android device,
/// widget rebuild overhead (layout + paint per node) is much more expensive
/// than one CustomPainter repaint that draws N primitives directly.
///
/// We cap particleCount at 28. That number came from manual testing in
/// profile mode: above ~35 simple rect particles, frame times started
/// creeping past 16ms on a throttled (4x CPU slowdown in DevTools) profile
/// run, which is the closest proxy we have to a budget Android device. See
/// README "Performance Profiling" section for the exact before/after.
class ConfettiOverlay extends StatefulWidget {
  final bool play;
  final VoidCallback? onComplete;

  const ConfettiOverlay({super.key, required this.play, this.onComplete});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  static const int particleCount = 28;
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _particles = List.generate(particleCount, (_) => _spawnParticle());

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.play) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _particles = List.generate(particleCount, (_) => _spawnParticle());
      _controller.forward(from: 0);
    }
  }

  _Particle _spawnParticle() {
    return _Particle(
      x: _rng.nextDouble(),
      speed: 0.6 + _rng.nextDouble() * 0.8,
      drift: (_rng.nextDouble() - 0.5) * 0.6,
      size: 6 + _rng.nextDouble() * 6,
      color: AppColors.confettiPalette[_rng.nextInt(AppColors.confettiPalette.length)],
      rotationSpeed: (_rng.nextDouble() - 0.5) * 8,
      shapeIsCircle: _rng.nextBool(),
    );
  }

  @override
  void dispose() {
    // Critical: AnimationController must be disposed or it leaks a Ticker
    // tied to this State, which keeps the whole widget subtree alive in
    // memory after the screen is gone - exactly the kind of retain-cycle
    // bug the brief calls out.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.play && _controller.isDismissed) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x; // 0..1 horizontal start position
  final double speed;
  final double drift;
  final double size;
  final Color color;
  final double rotationSpeed;
  final bool shapeIsCircle;

  _Particle({
    required this.x,
    required this.speed,
    required this.drift,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.shapeIsCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      final t = progress * p.speed;
      final dy = t * (size.height + 40) - 20;
      final dx = p.x * size.width + p.drift * size.width * t;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      paint.color = p.color.withOpacity(opacity);

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotationSpeed * progress * pi);

      if (p.shapeIsCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
