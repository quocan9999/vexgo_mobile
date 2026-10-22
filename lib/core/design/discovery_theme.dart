import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

class DiscoveryColors {
  DiscoveryColors._();

  // Scoped to discovery screens; global AppColors remain unchanged.
  static const header = Color(0xFFDC2626);
  static const logoAccent = Color(0xFFFBBF24);

  // Brand Colors
  static const Color primary = Color(0xFF1A56DB); // VexGo Trust Blue
  static const Color primaryDark = Color(0xFF1E429F);
  static const Color primaryLight = Color(0xFFEBF5FF);
  static const Color primaryGradientStart = Color(0xFF0072E5);
  static const Color primaryGradientEnd = Color(0xFF004CA0);

  // Accent / CTA Colors
  static const Color secondary = Color(0xFFFF5A1F); // Energy Orange
  static const Color secondaryLight = Color(0xFFFFF0EB);
  static const Color secondaryDark = Color(0xFFE04711);

  // Seat Status Colors
  static const Color seatAvailable = Colors.white;
  static const Color seatAvailableBorder = Color(0xFF98A2B3);
  static const Color seatSelected = Color(0xFF1A56DB);
  static const Color seatBooked = Color(0xFFD0D5DD);
  static const Color seatVip = Color(0xFFFFB300);

  // Neutral / Grayscale
  static const Color neutral900 = Color(0xFF0F172A);
  static const Color neutral800 = Color(0xFF1D2939);
  static const Color neutral700 = Color(0xFF344054);
  static const Color neutral600 = Color(0xFF475467);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral400 = Color(0xFF98A2B3);
  static const Color neutral300 = Color(0xFFD0D5DD);
  static const Color neutral200 = Color(0xFFE2E8F0);
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
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}

class DiscoveryTextStyles {
  DiscoveryTextStyles._();

  // Headings
  static TextStyle h1 = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: DiscoveryColors.neutral900,
    height: 1.3,
  );

  static TextStyle h2 = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: DiscoveryColors.neutral900,
    height: 1.3,
  );

  static TextStyle h3 = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: DiscoveryColors.neutral900,
    height: 1.35,
  );

  static TextStyle h4 = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: DiscoveryColors.neutral900,
    height: 1.4,
  );

  // Subtitles / Titles
  static TextStyle titleMedium = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: DiscoveryColors.neutral900,
    height: 1.4,
  );

  static TextStyle titleSmall = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: DiscoveryColors.neutral900,
    height: 1.4,
  );

  // Body text
  static TextStyle bodyLarge = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: DiscoveryColors.neutral800,
    height: 1.5,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: DiscoveryColors.neutral700,
    height: 1.5,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: DiscoveryColors.neutral500,
    height: 1.4,
  );

  // Caption & Overline
  static TextStyle caption = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: DiscoveryColors.neutral500,
  );

  // Button text
  static TextStyle button = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  // Price text
  static TextStyle price = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: DiscoveryColors.secondary,
  );

  static TextStyle priceOriginal = TextStyle(
    fontFamily: 'VexGoJakarta',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: DiscoveryColors.neutral400,
    decoration: TextDecoration.lineThrough,
  );
}

enum ButtonType { primary, secondary, outline, text }

class DiscoveryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;
  final double height;
  final double? borderRadius;

  const DiscoveryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.height = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? AppDimensions.radiusMd;

    Color getBgColor() {
      if (onPressed == null) return DiscoveryColors.neutral300;
      switch (type) {
        case ButtonType.primary:
          return DiscoveryColors.primary;
        case ButtonType.secondary:
          return DiscoveryColors.secondary;
        case ButtonType.outline:
        case ButtonType.text:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      if (onPressed == null) return DiscoveryColors.neutral500;
      switch (type) {
        case ButtonType.primary:
        case ButtonType.secondary:
          return Colors.white;
        case ButtonType.outline:
          return DiscoveryColors.primary;
        case ButtonType.text:
          return DiscoveryColors.primary;
      }
    }

    BorderSide? getBorder() {
      if (type == ButtonType.outline) {
        return BorderSide(
          color: onPressed == null
              ? DiscoveryColors.neutral300
              : DiscoveryColors.primary,
          width: 1.5,
        );
      }
      return BorderSide.none;
    }

    return SizedBox(
      width: width,
      height: height + (MediaQuery.textScalerOf(context).scale(15) - 15) * 2,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: getBgColor(),
          foregroundColor: getTextColor(),
          disabledBackgroundColor: DiscoveryColors.neutral300,
          disabledForegroundColor: DiscoveryColors.neutral500,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: getBorder() ?? BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: AppDimensions.xs),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: DiscoveryTextStyles.button.copyWith(
                        color: getTextColor(),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (suffixIcon != null) ...[
                    const SizedBox(width: AppDimensions.xs),
                    suffixIcon!,
                  ],
                ],
              ),
      ),
    );
  }
}

class DiscoveryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color backgroundColor;
  final Color titleColor;
  final double elevation;

  const DiscoveryAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor = DiscoveryColors.header,
    this.titleColor = Colors.white,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading:
          leading ??
          (automaticallyImplyLeading && Navigator.of(context).canPop()
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: titleColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: DiscoveryTextStyles.titleMedium.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: DiscoveryTextStyles.caption.copyWith(
                color: titleColor.withValues(alpha: 0.8),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Deliberately local: booking, payment and account screens retain their theme.
class DiscoveryTheme extends StatelessWidget {
  final Widget child;
  const DiscoveryTheme({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: 'VexGoJakarta'),
        colorScheme: base.colorScheme.copyWith(
          primary: DiscoveryColors.primary,
          secondary: DiscoveryColors.secondary,
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          hintStyle: DiscoveryTextStyles.bodyMedium.copyWith(
            color: DiscoveryColors.neutral500,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: DiscoveryColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
