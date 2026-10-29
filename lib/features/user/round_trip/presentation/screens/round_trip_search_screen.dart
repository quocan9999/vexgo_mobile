import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_search_cubit.dart';
import '../widgets/round_trip_trip_card.dart';

class RoundTripSearchScreen extends StatelessWidget {
  final Map<String, String> query;
  final Map<String, dynamic> extra;

  const RoundTripSearchScreen({
    super.key,
    required this.query,
    this.extra = const {},
  });

  @override
  Widget build(BuildContext context) {
    RoundTripRequest? request;
    String? requestError;
    try {
      request = RoundTripRequest.fromRoute(query: query, extra: extra);
    } catch (e) {
      requestError = e is ArgumentError
          ? (e.message?.toString() ?? 'Thông tin tìm kiếm không hợp lệ.')
          : 'Thông tin tìm kiếm không hợp lệ.';
    }

    if (request == null) {
      return DiscoveryTheme(
        child: Scaffold(
          backgroundColor: DiscoveryColors.background,
          appBar: AppBar(
            backgroundColor: DiscoveryColors.header,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.home),
            ),
            title: Text(
              'Tìm chuyến khứ hồi',
              style: DiscoveryTextStyles.titleMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 56,
                    color: DiscoveryColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tìm chuyến',
                    style: DiscoveryTextStyles.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requestError ??
                        'Dữ liệu tuyến đường hoặc ngày đi/về không hợp lệ.',
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DiscoveryColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Về Trang chủ'),
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DiscoveryTheme(
      child: BlocProvider<RoundTripSearchCubit>(
        create: (context) =>
            RoundTripSearchCubit(context.read<TripRepository>())
              ..search(request!),
        child: _RoundTripSearchView(request: request),
      ),
    );
  }
}

class _RoundTripSearchView extends StatelessWidget {
  final RoundTripRequest request;

  const _RoundTripSearchView({required this.request});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoundTripSearchCubit>();

    return BlocConsumer<RoundTripSearchCubit, RoundTripSearchState>(
      listener: (context, state) {},
      builder: (context, state) {
        final departureDateStr = DateFormatter.formatFullDate(
          request.departureDate,
        );
        final returnDateStr = DateFormatter.formatFullDate(request.returnDate);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: DiscoveryColors.background,
            appBar: AppBar(
              backgroundColor: DiscoveryColors.header,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.origin.name} ⇄ ${request.destination.name}',
                    style: DiscoveryTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$departureDateStr - $returnDateStr • ${request.ticketCount} vé',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              bottom: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
                labelStyle: DiscoveryTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: DiscoveryTextStyles.bodyMedium,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            state.outbound != null
                                ? 'Lượt đi (Đã chọn)'
                                : 'Lượt đi',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            state.inbound != null
                                ? 'Lượt về (Đã chọn)'
                                : 'Lượt về',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildLegTab(
                  context,
                  leg: TripLeg.outbound,
                  title:
                      'Lượt đi: ${request.origin.name} → ${request.destination.name}',
                  dateStr: departureDateStr,
                  loading: state.outboundLoading,
                  error: state.outboundError,
                  trips: state.outboundTrips,
                  selectedTrip: state.outbound,
                  onSelect: (trip) {
                    final ok = cubit.select(TripLeg.outbound, trip);
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chuyến đi không tương thích với chuyến về đã chọn.',
                          ),
                          backgroundColor: DiscoveryColors.error,
                        ),
                      );
                    }
                  },
                  onClear: () => cubit.clearSelection(TripLeg.outbound),
                  onRetry: () => cubit.search(request),
                ),
                _buildLegTab(
                  context,
                  leg: TripLeg.inbound,
                  title:
                      'Lượt về: ${request.destination.name} → ${request.origin.name}',
                  dateStr: returnDateStr,
                  loading: state.inboundLoading,
                  error: state.inboundError,
                  trips: state.inboundTrips,
                  selectedTrip: state.inbound,
                  onSelect: (trip) {
                    final ok = cubit.select(TripLeg.inbound, trip);
                    if (!ok) {
                      final reason = state.outbound == null
                          ? 'Vui lòng chọn chuyến đi trước hoặc kiểm tra giờ khởi hành.'
                          : 'Chuyến về phải khởi hành sau khi chuyến đi đến nơi (kể cả chuyến qua đêm).';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(reason),
                          backgroundColor: DiscoveryColors.error,
                        ),
                      );
                    }
                  },
                  onClear: () => cubit.clearSelection(TripLeg.inbound),
                  onRetry: () => cubit.search(request),
                ),
              ],
            ),
            bottomNavigationBar: _buildBottomBar(context, state),
          ),
        );
      },
    );
  }

  Widget _buildLegTab(
    BuildContext context, {
    required TripLeg leg,
    required String title,
    required String dateStr,
    required bool loading,
    required String? error,
    required List<TripModel> trips,
    required TripModel? selectedTrip,
    required ValueChanged<TripModel> onSelect,
    required VoidCallback onClear,
    required VoidCallback onRetry,
  }) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: DiscoveryColors.primary),
            const SizedBox(height: 16),
            Text(
              'Đang tìm kiếm chuyến ${leg == TripLeg.outbound ? 'đi' : 'về'}...',
              style: DiscoveryTextStyles.bodyMedium.copyWith(
                color: DiscoveryColors.neutral600,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: DiscoveryColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: DiscoveryColors.neutral800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Lưu ý: Tải lại sẽ làm mới cả hai chặng và đặt lại lựa chọn.',
                style: DiscoveryTextStyles.caption.copyWith(
                  color: DiscoveryColors.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
    }

    if (trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_bus_filled_outlined,
                size: 56,
                color: DiscoveryColors.neutral400,
              ),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy chuyến ${leg == TripLeg.outbound ? 'đi' : 'về'}',
                style: DiscoveryTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Không có chuyến nào khởi hành vào ngày $dateStr hoặc đã hết chỗ cho ${request.ticketCount} vé.',
                style: DiscoveryTextStyles.bodySmall.copyWith(
                  color: DiscoveryColors.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (selectedTrip != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: DiscoveryColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DiscoveryColors.primary),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: DiscoveryColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đã chọn ${leg == TripLeg.outbound ? 'lượt đi' : 'lượt về'}:',
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${selectedTrip.operatorName} • ${selectedTrip.departureTime} - ${selectedTrip.arrivalTime}',
                        style: DiscoveryTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text(
                    'Đổi chuyến',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        for (final trip in trips)
          RoundTripTripCard(
            trip: trip,
            isSelected: selectedTrip?.id == trip.id,
            onSelect: () => onSelect(trip),
          ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, RoundTripSearchState state) {
    final canContinue = state.canContinue;
    final out = state.outbound;
    final back = state.inbound;

    int? estTotal;
    if (out != null && back != null) {
      estTotal = (out.discountPrice + back.discountPrice) * request.ticketCount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: DiscoveryColors.neutral200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: out != null
                            ? DiscoveryColors.successDark
                            : DiscoveryColors.neutral400,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          out != null
                              ? 'Đi: ${out.operatorName} (${out.departureTime})'
                              : 'Đi: Chưa chọn',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: out != null
                                ? DiscoveryColors.neutral800
                                : DiscoveryColors.neutral500,
                            fontWeight: out != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: back != null
                            ? DiscoveryColors.successDark
                            : DiscoveryColors.neutral400,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          back != null
                              ? 'Về: ${back.operatorName} (${back.departureTime})'
                              : 'Về: Chưa chọn',
                          style: DiscoveryTextStyles.caption.copyWith(
                            color: back != null
                                ? DiscoveryColors.neutral800
                                : DiscoveryColors.neutral500,
                            fontWeight: back != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (estTotal != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tạm tính: ${CurrencyFormatter.format(estTotal)}',
                      style: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              key: const ValueKey('round-trip-continue-btn'),
              onPressed: canContinue
                  ? () {
                      final sel = state.selection;
                      if (sel != null) {
                        context.push(AppRoutes.roundTripBooking, extra: sel);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DiscoveryColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DiscoveryColors.neutral300,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Tiếp tục',
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
