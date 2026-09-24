import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle h1 = GoogleFonts.beVietnamPro(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.3,
  );

  static TextStyle h2 = GoogleFonts.beVietnamPro(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.neutral900,
    height: 1.3,
  );

  static TextStyle h3 = GoogleFonts.beVietnamPro(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.35,
  );

  static TextStyle h4 = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );

  // Subtitles / Titles
  static TextStyle titleMedium = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );

  static TextStyle titleSmall = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.neutral900,
    height: 1.4,
  );

  // Body text
  static TextStyle bodyLarge = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral800,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral700,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral500,
    height: 1.4,
  );

  // Caption & Overline
  static TextStyle caption = GoogleFonts.beVietnamPro(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.neutral500,
  );

  // Button text
  static TextStyle button = GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  // Price text
  static TextStyle price = GoogleFonts.beVietnamPro(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.secondary,
  );

  static TextStyle priceOriginal = GoogleFonts.beVietnamPro(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.neutral400,
    decoration: TextDecoration.lineThrough,
  );
}
