import 'package:flutter/material.dart';

/// CRT scanline overlay — semi-transparent horizontal lines every 2px
class TvScanlines extends StatelessWidget {
  const TvScanlines({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanlinesPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  static const Color _lineColor = Color(0x14000000); // rgba(0,0,0,0.08)

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw 1px horizontal line every 2px (line at y=0, 2, 4, ...)
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
