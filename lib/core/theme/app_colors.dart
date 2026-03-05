import 'package:flutter/material.dart';

/// Anytime 앱 색상 팔레트
///
/// Prototype 기반 - Pure Black + Pixel
class AppColors {
  AppColors._();

  // ============================================
  // 기본 색상
  // ============================================

  static const Color black = Color(0xFF000000);
  static const Color white = Colors.white;
  static const Color accent = Color(0xCCFFC864);        // rgba(255,200,100,0.8)
  static const Color accentDim = Color(0x4DFFC864);     // rgba(255,200,100,0.3)

  // ============================================
  // 배경 (Background)
  // ============================================

  static const Color background = black;
  static const Color tvBackground = Color(0xFF0A0A0A);   // #0a0a0a
  static const Color tvFrame = Color(0xFF1A1A1A);         // #1a1a1a

  // ============================================
  // TV 요소
  // ============================================

  // Eyes
  static const Color eyeColor = Color(0xE6DCE6D2);       // rgba(220,230,210,0.9)

  // Pending bubble
  static const Color pendingBubble = Color(0xE6FFDC96);   // rgba(255,220,150,0.9)

  // Thinking dots
  static const Color thinkingDot = Color(0xD9C8D7E6);    // rgba(200,215,230,0.85)

  // Equalizer bars (speaking)
  static const Color equalizerBar = Color(0xCCFFC864);    // same as accent

  // LED
  static const Color ledActive = Color(0xFF4CAF50);       // green
  static const Color ledPending = Color(0xCCFFC864);      // accent

  // ============================================
  // 텍스트 (Text)
  // ============================================

  static const Color textPrimary = Colors.white;
  static const Color textDim = Color(0x59FFFFFF);         // rgba(255,255,255,0.35)
  static const Color textDimmer = Color(0x33FFFFFF);      // rgba(255,255,255,0.2)

  // ============================================
  // UI 요소
  // ============================================

  static const Color border = Color(0x14FFFFFF);          // rgba(255,255,255,0.08)
  static const Color divider = Color(0x14FFFFFF);         // same as border
  static const Color cardBackground = Color(0xFF0A0A0A);  // same as tvBackground
  static const Color inputBorder = Color(0x14FFFFFF);     // same as border
  static const Color inputBorderFocus = Color(0x59FFFFFF); // same as textDim

  // ============================================
  // 스와이프 인디케이터
  // ============================================

  static const Color dotActive = Color(0x80FFFFFF);       // rgba(255,255,255,0.5)
  static const Color dotInactive = Color(0x33FFFFFF);     // rgba(255,255,255,0.2)

  // ============================================
  // 시맨틱 컬러
  // ============================================

  static const Color newBadge = Color(0xFF90EE90);
  static const Color removed = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF90EE90);
  static const Color warning = Color(0xCCFFC864);         // accent
  static const Color error = Color(0xFFFF6B6B);
}
