import 'dart:math' show Random;
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Speaking state — 5 animated equalizer bars with steps(4) effect
class TvEqualizer extends StatefulWidget {
  const TvEqualizer({super.key});

  @override
  State<TvEqualizer> createState() => _TvEqualizerState();
}

class _TvEqualizerState extends State<TvEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Target heights for each bar (min 15, max 40)
  static const int _barCount = 5;
  static const double _minHeight = 15.0;
  static const double _maxHeight = 40.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppSpacing.eqAnimation,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns stepped height for bar i based on animation value (0..1)
  double _steppedHeight(int barIndex, double t) {
    // 4 discrete steps
    const int steps = 4;
    final int step = (t * steps).floor().clamp(0, steps - 1);
    // Different height ranges per bar using seeded random
    final List<double> heights = _barHeights[barIndex];
    return heights[step];
  }

  /// Pre-computed 4-step height sequences per bar
  late final List<List<double>> _barHeights = List.generate(_barCount, (i) {
    final rng = Random(i * 13 + 7);
    return List.generate(
      4,
      (_) => _minHeight + rng.nextDouble() * (_maxHeight - _minHeight),
    );
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_barCount, (i) {
            // Stagger: each bar uses a phase-shifted controller value
            final double phase = (i / _barCount) * 0.5;
            final double t = ((_controller.value + phase) % 1.0);
            final double height = _steppedHeight(i, t);

            return Padding(
              padding: EdgeInsets.only(right: i < _barCount - 1 ? 3.0 : 0.0),
              child: Container(
                width: AppSpacing.eqBarWidth,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.equalizerBar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
