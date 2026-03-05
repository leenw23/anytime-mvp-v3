import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Thinking state — 3 sequentially bouncing dots
class TvThinking extends StatefulWidget {
  const TvThinking({super.key});

  @override
  State<TvThinking> createState() => _TvThinkingState();
}

class _TvThinkingState extends State<TvThinking>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppSpacing.thinkingBounce,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Compute translateY for a dot given its delay offset (0..1 fraction)
  double _translateY(double controllerValue, double delayFraction) {
    // Shift the animation value by the delay (phase shift, wrapping)
    final double t = (controllerValue - delayFraction) % 1.0;
    // Normalized t that is negative means we're in the "before start" region
    final double normalT = t < 0 ? t + 1.0 : t;

    // CSS: 0%→0, 30%→-12, 60%→0, 100%→0
    // Piecewise interpolation:
    if (normalT < 0.3) {
      // 0→30%: 0 to -12
      return -12.0 * (normalT / 0.3) * _easeInOut(normalT / 0.3);
    } else if (normalT < 0.6) {
      // 30→60%: -12 to 0
      final double localT = (normalT - 0.3) / 0.3;
      return -12.0 * (1.0 - _easeInOut(localT));
    } else {
      // 60→100%: stay at 0
      return 0.0;
    }
  }

  double _easeInOut(double t) {
    // Simple cubic ease-in-out
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  Widget build(BuildContext context) {
    final delays = [0.0, 0.2 / 1.4, 0.4 / 1.4];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final double ty = _translateY(_controller.value, delays[i]);
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 8.0 : 0.0),
              child: Transform.translate(
                offset: Offset(0, ty),
                child: Container(
                  width: AppSpacing.thinkingDotSize,
                  height: AppSpacing.thinkingDotSize,
                  decoration: BoxDecoration(
                    color: AppColors.thinkingDot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
