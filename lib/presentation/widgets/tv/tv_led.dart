import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// LED indicator — small circle, green when active, pulsing accent when pending
class TvLed extends StatefulWidget {
  final bool isActive;
  final bool isPending;

  const TvLed({
    super.key,
    required this.isActive,
    required this.isPending,
  });

  @override
  State<TvLed> createState() => _TvLedState();
}

class _TvLedState extends State<TvLed> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isPending) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TvLed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPending && !oldWidget.isPending) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isPending && oldWidget.isPending) {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color ledColor;
    if (widget.isActive) {
      ledColor = AppColors.ledActive;
    } else if (widget.isPending) {
      ledColor = AppColors.ledPending;
    } else {
      ledColor = AppColors.ledActive.withValues(alpha: 0.2);
    }

    Widget led = Container(
      width: AppSpacing.ledSize,
      height: AppSpacing.ledSize,
      decoration: BoxDecoration(
        color: ledColor,
        shape: BoxShape.circle,
      ),
    );

    if (widget.isPending) {
      led = AnimatedBuilder(
        animation: _pulseOpacity,
        builder: (context, child) => Opacity(
          opacity: _pulseOpacity.value,
          child: child,
        ),
        child: led,
      );
    }

    return led;
  }
}
