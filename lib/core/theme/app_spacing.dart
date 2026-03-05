/// Anytime 앱 간격 & 크기 상수
///
/// 일관된 레이아웃을 위한 spacing 시스템 (8px 기반)
class AppSpacing {
  AppSpacing._();

  // Base Spacing - 8px grid
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Page Padding
  static const double pageHorizontal = 24.0;
  static const double pageTop = 16.0;
  static const double pageBottom = 24.0;

  // TV Widget
  static const double tvHeight = 160.0;
  static const double tvBorderRadius = 16.0;
  static const double tvBorderWidth = 1.0;

  // TV Eyes
  static const double eyeWidth = 8.0;
  static const double eyeHeight = 18.0;
  static const double eyeGap = 20.0;
  static const double eyeBorderRadius = 4.0;

  // TV Equalizer (Speaking)
  static const double eqBarWidth = 5.0;
  static const double eqBarCount = 5;

  // TV Pending Bubble
  static const double pendingBubbleWidth = 40.0;
  static const double pendingBubbleHeight = 32.0;

  // TV Thinking Dots
  static const double thinkingDotSize = 10.0;

  // LED
  static const double ledSize = 5.0;

  // Swipe Indicator
  static const double swipeDotSize = 4.0;
  static const double swipeDotSpacing = 8.0;

  // Input
  static const double inputHeight = 48.0;

  // Card
  static const double cardBorderRadius = 12.0;
  static const double cardPadding = 16.0;

  // Profile Avatar
  static const double avatarSize = 80.0;
  static const double avatarOptionSize = 60.0;

  // History
  static const double timelineWidth = 1.0;

  // Animation Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration blink = Duration(seconds: 4);
  static const Duration eqAnimation = Duration(milliseconds: 500);
  static const Duration pendingBounce = Duration(milliseconds: 1500);
  static const Duration thinkingBounce = Duration(milliseconds: 1400);
}
