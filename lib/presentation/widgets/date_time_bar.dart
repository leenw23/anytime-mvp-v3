import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/theme/theme.dart';

/// DateTime separator bar shown in chat messages
///
/// Displays formatted date/time: "3월 5일 수요일 오후 2:30" format
class DateTimeBar extends StatelessWidget {
  final DateTime dateTime;

  const DateTimeBar({super.key, required this.dateTime});

  String _formattedDate() {
    // Format: "3월 5일 수요일 오후 2:30"
    try {
      final formatter = DateFormat('M월 d일 EEEE a h:mm', 'ko');
      return formatter.format(dateTime);
    } catch (_) {
      // Fallback if locale not initialized
      return dateTime.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CustomPaint(
        painter: _DashedBottomBorderPainter(),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _formattedDate(),
            style: AppTypography.dateTime,
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed line along the bottom of its child
class _DashedBottomBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double startX = 0;
    final double y = size.height;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(0, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Initialize Korean locale — call once at app startup, e.g. in main()
Future<void> initKoreanLocale() => initializeDateFormatting('ko');
