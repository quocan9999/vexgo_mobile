import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF0060C4); // VexGo Trust Blue
  static const Color primaryDark = Color(0xFF00458E);
  static const Color primaryLight = Color(0xFFE8F1FC);
  static const Color primaryGradientStart = Color(0xFF0072E5);
  static const Color primaryGradientEnd = Color(0xFF004CA0);

  // Accent / CTA Colors
  static const Color secondary = Color(0xFFFF6F00); // Energy Orange
  static const Color secondaryLight = Color(0xFFFFF3E0);
  static const Color secondaryDark = Color(0xFFE65100);

  // Seat Status Colors
  static const Color seatAvailable = Colors.white;
  static const Color seatAvailableBorder = Color(0xFF98A2B3);
  static const Color seatSelected = Color(0xFF0060C4);
  static const Color seatBooked = Color(0xFFD0D5DD);
  static const Color seatVip = Color(0xFFFFB300);

  // Neutral / Grayscale
  static const Color neutral900 = Color(0xFF101828);
  static const Color neutral800 = Color(0xFF1D2939);
  static const Color neutral700 = Color(0xFF344054);
  static const Color neutral600 = Color(0xFF475467);
  static const Color neutral500 = Color(0xFF667085);
  static const Color neutral400 = Color(0xFF98A2B3);
  static const Color neutral300 = Color(0xFFD0D5DD);
  static const Color neutral200 = Color(0xFFEAECF0);
  static const Color neutral100 = Color(0xFFF2F4F7);
  static const Color neutral50 = Color(0xFFF9FAFB);

  // Semantic Status
  static const Color success = Color(0xFF12B76A);
  static const Color successLight = Color(0xFFECFDF3);
  static const Color successDark = Color(0xFF027A48);

  static const Color warning = Color(0xFFF79009);
  static const Color warningLight = Color(0xFFFFFAEB);
  static const Color warningDark = Color(0xFFB54708);

  static const Color error = Color(0xFFD92D20);
  static const Color errorLight = Color(0xFFFEF3F2);
  static const Color errorDark = Color(0xFF912018);

  static const Color info = Color(0xFF026AA2);
  static const Color infoLight = Color(0xFFF0F9FF);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color divider = Color(0xFFEAECF0);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
