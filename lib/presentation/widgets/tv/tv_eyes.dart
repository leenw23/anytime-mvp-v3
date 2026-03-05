import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Idle state — two blinking eyes
class TvEyes extends StatefulWidget {
  const TvEyes({super.key});

  @override
  State<TvEyes> createState() => _TvEyesState();
}

class _TvEyesState extends State<TvEyes> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleY;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // scaleY: 1.0 → 0.1 → 1.0
    _scaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.1)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    // Trigger blink every 4 seconds
    _timer = Timer.periodic(AppSpacing.blink, (_) {
      if (mounted) _controller.forward(from: 0.0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleY,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Eye(scaleY: _scaleY.value),
            const SizedBox(width: AppSpacing.eyeGap),
            _Eye(scaleY: _scaleY.value),
          ],
        );
      },
    );
  }
}

class _Eye extends StatelessWidget {
  final double scaleY;

  const _Eye({required this.scaleY});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleY: scaleY,
      child: Container(
        width: AppSpacing.eyeWidth,
        height: AppSpacing.eyeHeight,
        decoration: BoxDecoration(
          color: AppColors.eyeColor,
          borderRadius:
              BorderRadius.circular(AppSpacing.eyeBorderRadius),
        ),
      ),
    );
  }
}
