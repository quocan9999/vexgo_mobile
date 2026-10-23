import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import '../../bloc/trip_detail_cubit.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/widgets/rating_badge.dart';
import 'package:vexgo_app/data/models/trip_model.dart';

class TripDetailSheet extends StatelessWidget {
  final TripModel trip;
  final ValueChanged<TripModel> onSelectTrip;

  const TripDetailSheet({
    super.key,
    required this.trip,
    required this.onSelectTrip,
  });

  static void show(
    BuildContext context, {
    required TripModel trip,
    required ValueChanged<TripModel> onSelectTrip,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RepositoryProvider<TripRepository>.value(
        value: context.read<TripRepository>(),
        child: TripDetailSheet(trip: trip, onSelectTrip: onSelectTrip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TripDetailCubit(
      repository: context.read<TripRepository>(),
      tripId: trip.id,
    )..load(),
    child: BlocBuilder<TripDetailCubit, TripDetailState>(
      builder: (context, state) {
        if (state.status != TripDetailStatus.loaded) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.95),
            child: Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Center(
                child: state.status == TripDetailStatus.loading
                    ? const CircularProgressIndicator(
                        color: DiscoveryColors.primary,
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimensions.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: DiscoveryColors.errorLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: DiscoveryColors.error,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.md),
                            Text(
                              'Không thể tải chi tiết chuyến',
                              style: DiscoveryTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.xs),
                            Text(
                              state.error ?? 'Đã xảy ra lỗi khi tải dữ liệu.',
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.neutral600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppDimensions.lg),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppDimensions.md,
                              runSpacing: AppDimensions.sm,
                              children: [
                                Semantics(
                                  button: true,
                                  label: 'Đóng chi tiết chuyến',
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(96, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMd,
                                        ),
                                      ),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Đóng'),
                                  ),
                                ),
                                Semantics(
                                  button: true,
                                  label: 'Thử lại tải chi tiết chuyến',
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DiscoveryColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(108, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusMd,
                                        ),
                                      ),
                                    ),
                                    onPressed: context.read<TripDetailCubit>().load,
                                    child: const Text('Thử lại'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          );
        }
        return _TripDetailContent(
          trip: state.trip!,
          onSelectTrip: onSelectTrip,
        );
      },
    ),
  );
}

class _TripDetailContent extends StatelessWidget {
  final TripModel trip;
  final ValueChanged<TripModel> onSelectTrip;
  const _TripDetailContent({required this.trip, required this.onSelectTrip});

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
                margin: const EdgeInsets.only(
                  top: AppDimensions.md,
                  bottom: AppDimensions.xs,
                ),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DiscoveryColors.neutral300,
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
                      color: DiscoveryColors.primaryLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: DiscoveryColors.primary,
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
                          style: DiscoveryTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppDimensions.xs,
                          runSpacing: 2,
                          children: [
                            if (trip.rating != null)
                              RatingBadge(
                                rating: trip.rating!,
                                reviewCount: trip.reviewCount,
                              ),
                            Text(
                              '• ${trip.vehicleType}',
                              style: DiscoveryTextStyles.caption.copyWith(
                                color: DiscoveryColors.neutral600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelColor: DiscoveryColors.primary,
                unselectedLabelColor: DiscoveryColors.neutral500,
                indicatorColor: DiscoveryColors.primary,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Hình ảnh xe'),
                  Tab(text: 'Tiện ích'),
                  Tab(text: 'Đón / Trả'),
                  Tab(text: 'Chính sách hủy'),
                ],
              ),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                    final isNarrow = constraints.maxWidth < 300 || textScale > 1.2;

                    final priceCol = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Giá chỉ từ',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: DiscoveryColors.neutral500,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(trip.discountPrice),
                          style: DiscoveryTextStyles.price.copyWith(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    );

                    final ctaBtn = DiscoveryButton(
                      text: trip.availableSeats > 0
                          ? 'CHỌN CHUYẾN NÀY'
                          : 'CHUYẾN XE ĐÃ HẾT CHỖ',
                      type: ButtonType.secondary,
                      width: isNarrow ? double.infinity : null,
                      onPressed: trip.availableSeats <= 0
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onSelectTrip(trip);
                            },
                    );

                    if (isNarrow) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          priceCol,
                          const SizedBox(height: AppDimensions.sm),
                          ctaBtn,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        priceCol,
                        const SizedBox(width: AppDimensions.base),
                        Expanded(child: ctaBtn),
                      ],
                    );
                  },
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
                color: DiscoveryColors.neutral100,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 50,
                    color: DiscoveryColors.primary,
                  ),
                ),
              ),
            );
          })
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                    color: DiscoveryColors.neutral400,
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    'Chưa có hình ảnh thực tế cho chuyến xe này',
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmenitiesTab() {
    if (trip.amenities.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 40,
                  color: DiscoveryColors.neutral400,
                ),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  'Chưa có thông tin tiện ích cho chuyến xe này',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
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
                  color: DiscoveryColors.successLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: DiscoveryColors.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Text(
                  amenity,
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    color: DiscoveryColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 60,
                  color: DiscoveryColors.primaryLight,
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
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          color: DiscoveryColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trip.pickupPoint,
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trip.pickupAddress,
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral500,
                    ),
                  ),
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
                color: DiscoveryColors.secondary,
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
                        style: DiscoveryTextStyles.titleSmall.copyWith(
                          color: DiscoveryColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trip.dropoffPoint,
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trip.dropoffAddress,
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral500,
                    ),
                  ),
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
        _buildPolicyRow(
          'Điều kiện hủy vé',
          'Mở chi tiết vé để xem điều kiện, phí hủy và số tiền hoàn do hệ thống xác nhận trước khi hủy.',
        ),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: DiscoveryColors.warningLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: DiscoveryColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  'Lưu ý: Vào dịp Lễ/Tết chính sách hoàn hủy vé sẽ tuân theo quy định riêng của nhà xe.',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral800,
                  ),
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
          const Icon(Icons.circle, size: 8, color: DiscoveryColors.primary),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rule,
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
