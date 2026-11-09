import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';

class ServiceGuaranteeSection extends StatelessWidget {
  const ServiceGuaranteeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final guarantees = [
      {
        'icon': Icons.verified_user_rounded,
        'title': context.l10n.uiGuaranteedSeats,
        'desc': context.l10n.uiLabel150RefundIfTheOperatorDoesNotHonour,
        'color': AppColors.primary,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': context.l10n.uiLabel247CustomerSupport,
        'desc': context.l10n.uiOurSupportTeamIsHereToHelpThroughout,
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.price_check_rounded,
        'title': context.l10n.uiGreatOffersTransparentFares,
        'desc': context.l10n.uiClearlyListedOperatorFaresWithNoHiddenCharges,
        'color': AppColors.success,
      },
      {
        'icon': Icons.qr_code_2_rounded,
        'title': context.l10n.uiConvenientETickets,
        'desc': context.l10n.uiBoardWithAScanOfTheQrCode,
        'color': const Color(0xFF7928CA),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.uiTheVexgoServicePromise,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...guarantees.map((g) {
            final color = g['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Icon(g['icon'] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g['title'] as String,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g['desc'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
