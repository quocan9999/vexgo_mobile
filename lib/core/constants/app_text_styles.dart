import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle h1 = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.3,
  );

  static TextStyle h2 = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.3,
  );

  static TextStyle h3 = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.35,
  );

  static TextStyle h4 = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );

  // Subtitles / Titles
  static TextStyle titleMedium = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );

  static TextStyle titleSmall = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );

  // Body text
  static TextStyle bodyLarge = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral800,
    height: 1.5,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral700,
    height: 1.5,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral500,
    height: 1.4,
  );

  // Caption & Overline
  static TextStyle caption = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral500,
  );

  // Button text
  static TextStyle button = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  // Price text
  static TextStyle price = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.secondary,
  );

  static TextStyle priceOriginal = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral400,
    decoration: TextDecoration.lineThrough,
  );
}
