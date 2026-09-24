import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/rating_badge.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_state.dart';

class FeaturedOperatorsSection extends StatelessWidget {
  const FeaturedOperatorsSection({super.key});

  void _showOperatorInfo(BuildContext context, OperatorModel op) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusXl),
              topRight: Radius.circular(AppDimensions.radiusXl),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.base),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(op.name, style: AppTextStyles.h3),
                        const SizedBox(height: 2),
                        RatingBadge(rating: op.rating, reviewCount: op.reviewCount),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
              const Divider(),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: AppDimensions.sm),
                  Text('Hotline: ', style: AppTextStyles.bodyMedium),
                  Flexible(
                    child: Text(
                      op.hotline,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.neutral500, size: 20),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'Chính sách: ${op.policy}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (prev, curr) =>
          prev.operators != curr.operators || prev.status != curr.status,
      builder: (context, state) {
        final operators = state.operators;
        if (operators.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Nhà xe uy tín đối tác',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Xem thêm',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
                itemCount: operators.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.md),
                itemBuilder: (context, index) {
                  final op = operators[index];
                  return InkWell(
                    onTap: () => _showOperatorInfo(context, op),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: Container(
                      width: 185,
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                        border: Border.all(color: AppColors.neutral200),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                                ),
                                child: const Icon(
                                  Icons.directions_bus_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.sm),
                              Expanded(
                                child: Text(
                                  op.shortName,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          RatingBadge(rating: op.rating, reviewCount: op.reviewCount),
                          const SizedBox(height: AppDimensions.xs),
                          Text(
                            'Hotline: ${op.hotline}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.neutral500,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
