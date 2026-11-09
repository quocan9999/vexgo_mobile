import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';

class LoyaltyHistorySheet extends StatelessWidget {
  final UserModel user;

  const LoyaltyHistorySheet({super.key, required this.user});

  static void show(BuildContext context, {required UserModel user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoyaltyHistorySheet(user: user),
    );
  }

  void _redeemReward(
    BuildContext context, {
    required int points,
    required String title,
  }) {
    context.read<AuthBloc>().add(
      RedeemPointsEvent(points: points, rewardTitle: title),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vouchersToRedeem = [
      {
        'title': context.l10n.uiVnd30000VoucherForAnyTrip,
        'points': 60,
        'code': 'VEXGO30K',
      },
      {
        'title': context.l10n.uiVnd50000VoucherForDaLatVung,
        'points': 100,
        'code': 'VEXGO50K',
      },
      {
        'title': context.l10n.uiVnd100000VoucherForNorthSouthTrips,
        'points': 200,
        'code': 'VEXGO100K',
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXl),
          topRight: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: AppDimensions.md,
                bottom: AppDimensions.xs,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimensions.xs),
                      Expanded(
                        child: Text(
                          context.l10n.uiVexgoRewardPoints7b38b8,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.base),
              children: [
                // Points Balance Banner
                Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.uiAvailableToRedeem,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.uiPoints746cfa(user.diemTichLuy),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        child: Text(
                          context.l10n.uiTierba8164(user.tierName),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.lg),

                // Section 1: Redeem Rewards
                Text(
                  context.l10n.uiRedeemPointsForVouchers,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                ...vouchersToRedeem.map((voucher) {
                  final cost = voucher['points'] as int;
                  final canRedeem = user.diemTichLuy >= cost;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: canRedeem
                                ? AppColors.secondaryLight
                                : AppColors.neutral100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            color: canRedeem
                                ? AppColors.secondary
                                : AppColors.neutral400,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                voucher['title'] as String,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.uiPointsRequired(cost),
                                style: AppTextStyles.caption.copyWith(
                                  color: canRedeem
                                      ? AppColors.secondary
                                      : AppColors.neutral400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        CustomButton(
                          text: context.l10n.uiRedeem,
                          height: 32,
                          type: canRedeem
                              ? ButtonType.secondary
                              : ButtonType.outline,
                          onPressed: canRedeem
                              ? () => _redeemReward(
                                  context,
                                  points: cost,
                                  title: voucher['title'] as String,
                                )
                              : null,
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: AppDimensions.md),
                const Divider(),
                const SizedBox(height: AppDimensions.sm),

                // Section 2: Point History
                Text(
                  context.l10n.uiPointsHistory,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutral500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                if (user.pointHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.xl,
                    ),
                    child: Center(
                      child: Text(
                        context.l10n.uiNoPointsTransactionsYet,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                  )
                else
                  ...user.pointHistory.map((tx) {
                    final isEarn = tx.points > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isEarn
                                  ? AppColors.successLight
                                  : AppColors.errorLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isEarn ? Icons.add_rounded : Icons.remove_rounded,
                              color: isEarn
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.title,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatFullDate(tx.createdAt),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.neutral400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Text(
                            context.l10n.uiPoints05f590(
                              isEarn ? '+' : '',
                              tx.points,
                            ),
                            style: AppTextStyles.titleSmall.copyWith(
                              color: isEarn
                                  ? AppColors.success
                                  : AppColors.error,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
