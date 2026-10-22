import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../screens/select_city_sheet.dart';
import 'package:vexgo_app/data/models/city_model.dart';

class SearchFormCard extends StatelessWidget {
  const SearchFormCard({super.key});

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required ValueChanged<DateTime> onDateSelected,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 120)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: DiscoveryColors.primary,
              onPrimary: Colors.white,
              onSurface: DiscoveryColors.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final homeBloc = context.read<HomeBloc>();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: DiscoveryColors.neutral200),
          ),
          child: Column(
            children: [
              // Departure & Destination City Selectors
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.base,
                  AppDimensions.base,
                  AppDimensions.base,
                  AppDimensions.sm,
                ),
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Column(
                      children: [
                        // Departure City
                        _buildCityRow(
                          context,
                          icon: Icons.trip_origin_rounded,
                          iconColor: DiscoveryColors.primary,
                          label: 'Điểm xuất phát',
                          cityName: state.departureCity?.name ?? 'Chọn điểm đi',
                          province: state.departureCity?.region,
                          onTap: () async {
                            final selected = await SelectCitySheet.show(
                              context,
                              title: 'Chọn điểm xuất phát',
                              cities: state.cities,
                              currentCity: state.departureCity,
                            );
                            if (selected != null) {
                              homeBloc.add(SelectDepartureCityEvent(selected));
                            }
                          },
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 36, right: 48),
                          child: const Divider(
                            height: 1,
                            color: DiscoveryColors.neutral200,
                          ),
                        ),

                        // Destination City
                        _buildCityRow(
                          context,
                          icon: Icons.location_on_rounded,
                          iconColor: DiscoveryColors.secondary,
                          label: 'Điểm đến',
                          cityName:
                              state.destinationCity?.name ?? 'Chọn điểm đến',
                          province: state.destinationCity?.region,
                          onTap: () async {
                            final selected = await SelectCitySheet.show(
                              context,
                              title: 'Chọn điểm đến',
                              cities: state.cities,
                              currentCity: state.destinationCity,
                            );
                            if (selected != null) {
                              homeBloc.add(
                                SelectDestinationCityEvent(selected),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    // Swap Cities Button
                    Positioned(
                      right: 4,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => homeBloc.add(const SwapCitiesEvent()),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DiscoveryColors.neutral200,
                              ),
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: DiscoveryColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: DiscoveryColors.neutral200),

              // Date Selection Section
              Padding(
                padding: const EdgeInsets.all(AppDimensions.base),
                child: Column(
                  children: [
                    // One-way / Round-trip selector
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTripTypeChip(
                          label: 'Một chiều',
                          isSelected: !state.isRoundTrip,
                          onTap: () =>
                              homeBloc.add(const ToggleRoundTripEvent(false)),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        _buildTripTypeChip(
                          label: 'Khứ hồi',
                          isSelected: state.isRoundTrip,
                          onTap: () =>
                              homeBloc.add(const ToggleRoundTripEvent(true)),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.md),

                    // Departure Date Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(
                              context,
                              initialDate: state.departureDate,
                              firstDate: DateTime.now(),
                              onDateSelected: (date) =>
                                  homeBloc.add(SelectDepartureDateEvent(date)),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppDimensions.sm + 2,
                              ),
                              decoration: BoxDecoration(
                                color: DiscoveryColors.neutral50,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                                border: Border.all(
                                  color: DiscoveryColors.neutral200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: DiscoveryColors.primary,
                                  ),
                                  const SizedBox(width: AppDimensions.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ngày đi',
                                          style: DiscoveryTextStyles.caption
                                              .copyWith(
                                                color:
                                                    DiscoveryColors.neutral500,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormatter.formatFullDate(
                                            state.departureDate,
                                          ),
                                          style: DiscoveryTextStyles.titleSmall
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Return Date (if Round-trip)
                        if (state.isRoundTrip) ...[
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(
                                context,
                                initialDate:
                                    state.returnDate ??
                                    state.departureDate.add(
                                      const Duration(days: 1),
                                    ),
                                firstDate: state.departureDate,
                                onDateSelected: (date) =>
                                    homeBloc.add(SelectReturnDateEvent(date)),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  AppDimensions.sm + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: DiscoveryColors.neutral50,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: DiscoveryColors.neutral200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_repeat_rounded,
                                      size: 18,
                                      color: DiscoveryColors.secondary,
                                    ),
                                    const SizedBox(width: AppDimensions.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ngày về',
                                            style: DiscoveryTextStyles.caption
                                                .copyWith(
                                                  color: DiscoveryColors
                                                      .neutral500,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            state.returnDate != null
                                                ? DateFormatter.formatFullDate(
                                                    state.returnDate!,
                                                  )
                                                : 'Chọn ngày về',
                                            style: DiscoveryTextStyles
                                                .titleSmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppDimensions.sm),

                    // Quick date chips: Hôm nay, Ngày mai
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickDateChip(
                          label: 'Hôm nay',
                          isSelected: _isSameDay(
                            state.departureDate,
                            DateTime.now(),
                          ),
                          onTap: () => homeBloc.add(
                            SelectDepartureDateEvent(DateTime.now()),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        _buildQuickDateChip(
                          label: 'Ngày mai',
                          isSelected: _isSameDay(
                            state.departureDate,
                            DateTime.now().add(const Duration(days: 1)),
                          ),
                          onTap: () => homeBloc.add(
                            SelectDepartureDateEvent(
                              DateTime.now().add(const Duration(days: 1)),
                            ),
                          ),
                        ),

                        // Number of tickets
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DiscoveryColors.neutral100,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Giảm số vé',
                                onPressed: () => homeBloc.add(
                                  UpdateTicketCountEvent(state.ticketCount - 1),
                                ),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: DiscoveryColors.neutral700,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '${state.ticketCount} vé',
                                  style: DiscoveryTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DiscoveryColors.neutral900,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Tăng số vé',
                                onPressed: () => homeBloc.add(
                                  UpdateTicketCountEvent(state.ticketCount + 1),
                                ),
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: DiscoveryColors.neutral700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.base),

                    // Primary Search Button
                    DiscoveryButton(
                      text: 'Tìm chuyến',
                      type: ButtonType.secondary,
                      prefixIcon: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      width: double.infinity,
                      onPressed: () {
                        final fromId = state.departureCity?.id ?? 'HCM';
                        final fromName =
                            state.departureCity?.name ?? 'TP. Hồ Chí Minh';
                        final toId = state.destinationCity?.id ?? 'DL';
                        final toName = state.destinationCity?.name ?? 'Đà Lạt';
                        final d = state.departureDate;
                        final dateStr =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

                        final departureCity =
                            state.departureCity ??
                            CityModel(
                              id: fromId,
                              name: fromName,
                              region: '',
                              isPopular: false,
                            );
                        final destinationCity =
                            state.destinationCity ??
                            CityModel(
                              id: toId,
                              name: toName,
                              region: '',
                              isPopular: false,
                            );

                        context.push(
                          '/search-trips?fromCityId=$fromId&fromCityName=$fromName&toCityId=$toId&toCityName=$toName&date=$dateStr&ticketCount=${state.ticketCount}',
                          extra: {
                            'fromCity': departureCity,
                            'toCity': destinationCity,
                            'date': state.departureDate,
                            'ticketCount': state.ticketCount,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String cityName,
    String? province,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cityName,
                    style: DiscoveryTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (province != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 48),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DiscoveryColors.neutral100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  province,
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? DiscoveryColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected
                ? DiscoveryColors.primary
                : DiscoveryColors.neutral300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: DiscoveryTextStyles.caption.copyWith(
            color: isSelected
                ? DiscoveryColors.primary
                : DiscoveryColors.neutral600,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? DiscoveryColors.primary
              : DiscoveryColors.neutral100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: DiscoveryTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : DiscoveryColors.neutral700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
