import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

/// Pending state — bouncing speech bubble with 3 dots
class TvPending extends StatefulWidget {
  const TvPending({super.key});

  @override
  State<TvPending> createState() => _TvPendingState();
}

class _TvPendingState extends State<TvPending>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: AppSpacing.pendingBounce,
    )..repeat(reverse: false);

    // 0%,100% translateY(0); 50% translateY(-8px) — ease-in-out, infinite
    _translateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _translateY,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bubble body
          Container(
            width: AppSpacing.pendingBubbleWidth,
            height: AppSpacing.pendingBubbleHeight,
            decoration: BoxDecoration(
              color: AppColors.pendingBubble,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _BubbleDot(),
                SizedBox(width: 4),
                _BubbleDot(),
                SizedBox(width: 4),
                _BubbleDot(),
              ],
            ),
          ),
          // Triangle tail
          CustomPaint(
            size: const Size(10, 6),
            painter: _BubbleTailPainter(),
          ),
        ],
      ),
    );
  }
}

class _BubbleDot extends StatelessWidget {
  const _BubbleDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        // Slightly darker than bubble
        color: const Color(0xE6CC9A50),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.pendingBubble
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2 - 4, 0)
      ..lineTo(size.width / 2 + 4, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
