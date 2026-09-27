import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_app_bar.dart';
import 'package:vexgo_app/core/widgets/empty_state.dart';
import 'package:vexgo_app/core/widgets/loading_shimmer.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import '../../bloc/search_trips_bloc.dart';
import '../../bloc/search_trips_event.dart';
import '../../bloc/search_trips_state.dart';
import '../widgets/date_selector_strip.dart';
import '../widgets/quick_filter_bar.dart';
import '../widgets/trip_card.dart';
import '../widgets/trip_filter_sheet.dart';
import '../widgets/trip_sort_sheet.dart';

class SearchTripsScreen extends StatelessWidget {
  final CityModel? fromCity;
  final CityModel? toCity;
  final DateTime? date;
  final int ticketCount;

  const SearchTripsScreen({
    super.key,
    this.fromCity,
    this.toCity,
    this.date,
    this.ticketCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFromCity = fromCity?.id ?? 'HCM';
    final effectiveToCity = toCity?.id ?? 'DL';
    final effectiveDate = date ?? DateTime.now().add(const Duration(days: 1));

    return BlocProvider<SearchTripsBloc>(
      create: (context) => SearchTripsBloc(
        tripRepository: context.read<TripRepository>(),
      )..add(LoadTripsEvent(
          fromCityId: effectiveFromCity,
          toCityId: effectiveToCity,
          date: effectiveDate,
        )),
      child: _SearchTripsView(
        fromCityName: fromCity?.name ?? 'TP. Hồ Chí Minh',
        toCityName: toCity?.name ?? 'Đà Lạt',
        ticketCount: ticketCount,
      ),
    );
  }
}

class _SearchTripsView extends StatelessWidget {
  final String fromCityName;
  final String toCityName;
  final int ticketCount;

  const _SearchTripsView({
    required this.fromCityName,
    required this.toCityName,
    required this.ticketCount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchTripsBloc, SearchTripsState>(
      builder: (context, state) {
        final bloc = context.read<SearchTripsBloc>();
        final dateStr = DateFormatter.formatFullDate(state.selectedDate);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: '$fromCityName - $toCityName',
            subtitle: '$dateStr • $ticketCount vé',
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.neutral900),
                tooltip: 'Bộ lọc',
                onPressed: () async {
                  final newFilter = await TripFilterSheet.show(
                    context,
                    initialFilter: state.currentFilter,
                    availableOperators: state.availableOperators,
                    availableVehicleTypes: state.availableVehicleTypes,
                    availableAmenities: state.availableAmenities,
                  );
                  if (newFilter != null) {
                    bloc.add(ApplyFilterEvent(newFilter));
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Date Selector Strip (Adjacent dates with lowest price per day)
              DateSelectorStrip(
                selectedDate: state.selectedDate,
                minPrice: state.minPriceInResults,
                onDateSelected: (newDate) {
                  bloc.add(ChangeSelectedDateEvent(newDate));
                },
              ),

              // 2. Quick Filter & Sort Sticky Bar
              QuickFilterBar(
                currentFilter: state.currentFilter,
                currentSort: state.currentSort,
                onOpenFilterSheet: () async {
                  final newFilter = await TripFilterSheet.show(
                    context,
                    initialFilter: state.currentFilter,
                    availableOperators: state.availableOperators,
                    availableVehicleTypes: state.availableVehicleTypes,
                    availableAmenities: state.availableAmenities,
                  );
                  if (newFilter != null) {
                    bloc.add(ApplyFilterEvent(newFilter));
                  }
                },
                onOpenSortSheet: () async {
                  final newSort = await TripSortSheet.show(context, state.currentSort);
                  if (newSort != null) {
                    bloc.add(ChangeSortTypeEvent(newSort));
                  }
                },
                onFilterChanged: (filter) {
                  bloc.add(ApplyFilterEvent(filter));
                },
              ),

              // 3. Results count summary
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.base,
                  AppDimensions.sm + 2,
                  AppDimensions.base,
                  AppDimensions.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      state.status == SearchTripsStatus.loading
                          ? 'Đang tìm kiếm chuyến xe...'
                          : 'Tìm thấy ${state.filteredTrips.length} chuyến xe',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (state.currentFilter.hasActiveFilters)
                      InkWell(
                        onTap: () => bloc.add(const ResetFilterEvent()),
                        child: Row(
                          children: [
                            const Icon(Icons.close_rounded, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 2),
                            Text(
                              'Xóa lọc (${state.currentFilter.activeFilterCount})',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // 4. Trip list view
              Expanded(
                child: _buildTripsList(context, state, bloc),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripsList(
    BuildContext context,
    SearchTripsState state,
    SearchTripsBloc bloc,
  ) {
    if (state.status == SearchTripsStatus.loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.base),
        itemCount: 4,
        itemBuilder: (context, index) => const TripCardShimmer(),
      );
    }

    if (state.status == SearchTripsStatus.failure) {
      return EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Có lỗi xảy ra',
        message: state.errorMessage ?? 'Không thể tải danh sách chuyến xe lúc này.',
        buttonText: 'Thử lại',
        onButtonPressed: () {
          bloc.add(LoadTripsEvent(
            fromCityId: state.fromCityId,
            toCityId: state.toCityId,
            date: state.selectedDate,
          ));
        },
      );
    }

    if (state.filteredTrips.isEmpty) {
      return EmptyState(
        icon: Icons.directions_bus_outlined,
        title: 'Không tìm thấy chuyến xe phù hợp',
        message: 'Không có chuyến xe nào thỏa mãn các tiêu chí lọc của bạn. Hãy thử thay đổi bộ lọc.',
        buttonText: 'Thiết lập lại bộ lọc',
        onButtonPressed: () => bloc.add(const ResetFilterEvent()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.base,
        vertical: AppDimensions.sm,
      ),
      itemCount: state.filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = state.filteredTrips[index];
        return TripCard(
          trip: trip,
          onSelect: () {
            context.push(
              '/seat-selection',
              extra: {
                'trip': trip,
                'date': state.selectedDate,
                'ticketCount': ticketCount,
              },
            );
          },
        );
      },
    );
  }
}
