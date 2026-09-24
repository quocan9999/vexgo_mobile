import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double? width;
  final double height;
  final double? borderRadius;

  const CustomButton({
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
      if (onPressed == null) return AppColors.neutral300;
      switch (type) {
        case ButtonType.primary:
          return AppColors.primary;
        case ButtonType.secondary:
          return AppColors.secondary;
        case ButtonType.outline:
        case ButtonType.text:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      if (onPressed == null) return AppColors.neutral500;
      switch (type) {
        case ButtonType.primary:
        case ButtonType.secondary:
          return Colors.white;
        case ButtonType.outline:
          return AppColors.primary;
        case ButtonType.text:
          return AppColors.primary;
      }
    }

    BorderSide? getBorder() {
      if (type == ButtonType.outline) {
        return BorderSide(
          color: onPressed == null ? AppColors.neutral300 : AppColors.primary,
          width: 1.5,
        );
      }
      return BorderSide.none;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: getBgColor(),
          foregroundColor: getTextColor(),
          disabledBackgroundColor: AppColors.neutral300,
          disabledForegroundColor: AppColors.neutral500,
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
                      style: AppTextStyles.button.copyWith(
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
