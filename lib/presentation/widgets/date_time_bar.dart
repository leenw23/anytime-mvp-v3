import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../core/theme/theme.dart';

class DateTimeBar extends StatelessWidget {
  final DateTime dateTime;

  const DateTimeBar({super.key, required this.dateTime});

  String _formattedDate() {
    try {
      final dayFormat = DateFormat('MM.dd', 'ko');
      final dayOfWeek = DateFormat('E', 'en').format(dateTime).toUpperCase();
      return '${dayFormat.format(dateTime)} $dayOfWeek';
    } catch (_) {
      return '${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  String _formattedTime() {
    try {
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBottomBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formattedDate(),
              style: AppTypography.dateTime,
            ),
            Text(
              _formattedTime(),
              style: AppTypography.dateTime,
            ),
          ],
        ),
      ),
    );
  }
}

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

Future<void> initKoreanLocale() => initializeDateFormatting('ko');
