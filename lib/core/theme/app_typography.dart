import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Anytime 앱 타이포그래피
///
/// Galmuri11 픽셀 폰트 기반
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Galmuri11';

  // 제목
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // 메시지 (Chat)
  static const TextStyle message = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.7,
  );

  static const TextStyle userMessage = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    height: 1.7,
  );

  // 본문
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    height: 1.5,
  );

  // 입력
  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textDimmer,
    height: 1.5,
  );

  // 라벨
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    height: 1.3,
  );

  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    height: 1.2,
  );

  // 날짜/시간
  static const TextStyle dateTime = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    height: 1.2,
  );

  // 캡션
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textDimmer,
    height: 1.3,
  );

  // 버튼
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // 태그 (profile page)
  static const TextStyle tag = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // 히스토리 카드
  static const TextStyle historyCard = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle historyDate = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textDim,
    height: 1.3,
  );
}
