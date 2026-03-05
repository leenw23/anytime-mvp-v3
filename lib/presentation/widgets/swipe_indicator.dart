import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class SwipeIndicator extends StatelessWidget {
  const SwipeIndicator({
    super.key,
    required this.currentIndex,
    required this.count,
  });

  final int currentIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: AppSpacing.swipeDotSpacing / 2,
          ),
          width: AppSpacing.swipeDotSize,
          height: AppSpacing.swipeDotSize,
          decoration: BoxDecoration(
            color: isActive ? AppColors.dotActive : AppColors.dotInactive,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
