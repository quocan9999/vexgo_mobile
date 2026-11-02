import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_typography.dart';
import '../design/discovery_theme.dart';

/// Compact branded header for root tabs. AppBar owns the status-bar safe area.
class TabPageHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  const TabPageHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: showBackButton,
    centerTitle: false,
    titleSpacing: 20,
    toolbarHeight: kToolbarHeight,
    backgroundColor: DiscoveryColors.header,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    iconTheme: const IconThemeData(color: Colors.white),
    actionsIconTheme: const IconThemeData(color: Colors.white),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    actions: actions == null ? null : [...actions!, const SizedBox(width: 8)],
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Preserve a reachable action at narrow widths or large system text sizes.
class TabHeaderAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const TabHeaderAction({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (compact) {
      return IconButton(
        tooltip: label,
        onPressed: onPressed,
        color: Colors.white,
        disabledColor: Colors.white54,
        icon: Icon(icon),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
