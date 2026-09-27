import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/core/widgets/rating_badge.dart';
import 'package:vexgo_app/data/models/trip_model.dart';

class TripDetailSheet extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onSelectTrip;

  const TripDetailSheet({
    super.key,
    required this.trip,
    required this.onSelectTrip,
  });

  static void show(
    BuildContext context, {
    required TripModel trip,
    required VoidCallback onSelectTrip,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripDetailSheet(
        trip: trip,
        onSelectTrip: onSelectTrip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
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
                margin: const EdgeInsets.only(top: AppDimensions.md, bottom: AppDimensions.xs),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),

            // Top Header: Operator & Price
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base,
                vertical: AppDimensions.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.operatorName,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            RatingBadge(rating: trip.rating, reviewCount: trip.reviewCount),
                            const SizedBox(width: AppDimensions.xs),
                            Flexible(
                              child: Text(
                                '• ${trip.vehicleType}',
                                style: AppTextStyles.caption.copyWith(color: AppColors.neutral600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab bar
            const TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.neutral500,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              tabs: [
                Tab(text: 'Hình ảnh xe'),
                Tab(text: 'Tiện ích'),
                Tab(text: 'Đón / Trả'),
                Tab(text: 'Chính sách hủy'),
              ],
            ),

            // Tab view content
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Hình ảnh xe
                  _buildImagesTab(),

                  // Tab 2: Tiện ích
                  _buildAmenitiesTab(),

                  // Tab 3: Điểm đón / trả
                  _buildPickupDropoffTab(),

                  // Tab 4: Chính sách hủy
                  _buildPolicyTab(),
                ],
              ),
            ),

            // Bottom CTA Bar
            Container(
              padding: const EdgeInsets.all(AppDimensions.base),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Giá chỉ từ',
                          style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                        ),
                        Text(
                          CurrencyFormatter.format(trip.discountPrice),
                          style: AppTextStyles.price.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppDimensions.base),
                    Expanded(
                      child: CustomButton(
                        text: 'CHỌN CHUYẾN NÀY',
                        type: ButtonType.secondary,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSelectTrip();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.base),
      children: [
        if (trip.images.isNotEmpty)
          ...trip.images.map((imgUrl) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                color: AppColors.neutral100,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.directions_bus_rounded, size: 50, color: AppColors.primary),
                ),
              ),
            );
          })
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.xxl),
              child: Text('Chưa có hình ảnh thực tế cho chuyến xe này'),
            ),
          ),
      ],
    );
  }

  Widget _buildAmenitiesTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.base),
      children: trip.amenities.map((amenity) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.xs + 2),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 16),
              ),
              const SizedBox(width: AppDimensions.md),
              Text(
                amenity,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPickupDropoffTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.base),
      children: [
        // Pickup
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Điểm đón • ${trip.departureTime}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(trip.pickupPoint, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(trip.pickupAddress, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                ],
              ),
            ),
          ],
        ),

        // Dropoff
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Điểm trả • ${trip.arrivalTime}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(trip.dropoffPoint, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(trip.dropoffAddress, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPolicyTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.base),
      children: [
        _buildPolicyRow('Trước giờ khởi hành 24 tiếng', 'Phí hủy 10% (Hoàn 90% giá vé)'),
        _buildPolicyRow('Trước giờ khởi hành 12 - 24 tiếng', 'Phí hủy 30% (Hoàn 70% giá vé)'),
        _buildPolicyRow('Trước giờ khởi hành 6 - 12 tiếng', 'Phí hủy 50% (Hoàn 50% giá vé)'),
        _buildPolicyRow('Dưới 6 tiếng trước giờ chạy', 'Không hỗ trợ hoàn hủy vé'),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  'Lưu ý: Vào dịp Lễ/Tết chính sách hoàn hủy vé sẽ tuân theo quy định riêng của nhà xe.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.neutral800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyRow(String time, String rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(rule, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
