import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../screens/select_city_sheet.dart';

class SearchFormCard extends StatelessWidget {
  const SearchFormCard({super.key});

  @override
  Widget build(BuildContext context) {
    final homeBloc = context.read<HomeBloc>();

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Toggle Switch Khứ hồi
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.base,
                  AppDimensions.sm,
                  AppDimensions.base,
                  AppDimensions.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync_alt_rounded,
                            size: 20,
                            color: state.isRoundTrip
                                ? DiscoveryColors.primary
                                : DiscoveryColors.neutral500,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Khứ hồi',
                              style: DiscoveryTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: state.isRoundTrip
                                    ? DiscoveryColors.primary
                                    : DiscoveryColors.neutral700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Bật tắt vé khứ hồi',
                      toggled: state.isRoundTrip,
                      child: Switch.adaptive(
                        value: state.isRoundTrip,
                        activeThumbColor: DiscoveryColors.primary,
                        activeTrackColor: DiscoveryColors.primaryLight,
                        onChanged: (val) =>
                            homeBloc.add(ToggleRoundTripEvent(val)),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Departure & Destination City Selectors
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.base,
                  AppDimensions.xs,
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

                    // Swap Button
                    Positioned(
                      right: 0,
                      child: Tooltip(
                        message: 'Đổi chiều điểm đi và điểm đến',
                        child: Semantics(
                          button: true,
                          label: 'Đổi chiều điểm đi và điểm đến',
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 2,
                            shadowColor: Colors.black26,
                            child: InkWell(
                              onTap: () =>
                                  homeBloc.add(const SwapCitiesEvent()),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 44,
                                height: 44,
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
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: DiscoveryColors.neutral200),

              // 3. Date Selection & CTA Button Section
              Padding(
                padding: const EdgeInsets.all(AppDimensions.base),
                child: Column(
                  children: [
                    // Date pickers: Single or Round trip
                    if (!state.isRoundTrip)
                      _buildDateField(
                        context: context,
                        label: 'Ngày đi',
                        date: state.departureDate,
                        onTap: () => _pickDate(
                          context,
                          initialDate: state.departureDate,
                          firstDate: DateTime.now(),
                          onDateSelected: (date) {
                            homeBloc.add(SelectDepartureDateEvent(date));
                          },
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 320;
                          final depField = _buildDateField(
                            context: context,
                            label: 'Ngày đi',
                            date: state.departureDate,
                            onTap: () => _pickDate(
                              context,
                              initialDate: state.departureDate,
                              firstDate: DateTime.now(),
                              onDateSelected: (date) {
                                homeBloc.add(SelectDepartureDateEvent(date));
                                if (state.returnDate != null &&
                                    state.returnDate!.isBefore(date)) {
                                  homeBloc.add(
                                    SelectReturnDateEvent(
                                      date.add(const Duration(days: 1)),
                                    ),
                                  );
                                }
                              },
                            ),
                          );

                          final retDate = state.returnDate ??
                              state.departureDate.add(const Duration(days: 2));
                          final retField = _buildDateField(
                            context: context,
                            label: 'Ngày về',
                            date: retDate,
                            onTap: () => _pickDate(
                              context,
                              initialDate: retDate,
                              firstDate: state.departureDate,
                              onDateSelected: (date) {
                                homeBloc.add(SelectReturnDateEvent(date));
                              },
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                depField,
                                const SizedBox(height: AppDimensions.sm),
                                retField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: depField),
                              const SizedBox(width: AppDimensions.sm),
                              Expanded(child: retField),
                            ],
                          );
                        },
                      ),

                    const SizedBox(height: AppDimensions.base),

                    // Primary Search Button
                    DiscoveryButton(
                      text: 'Tìm chuyến',
                      type: ButtonType.secondary,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      width: double.infinity,
                      height: 50,
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

                        final returnDateStr =
                            state.isRoundTrip && state.returnDate != null
                                ? '${state.returnDate!.year}-${state.returnDate!.month.toString().padLeft(2, '0')}-${state.returnDate!.day.toString().padLeft(2, '0')}'
                                : null;

                        final extraMap = <String, dynamic>{
                          'fromCity': departureCity,
                          'toCity': destinationCity,
                          'date': state.departureDate,
                          'ticketCount': state.ticketCount,
                          'isRoundTrip': state.isRoundTrip,
                        };
                        if (state.isRoundTrip && state.returnDate != null) {
                          extraMap['returnDate'] = state.returnDate;
                        }

                        final returnQuery = returnDateStr != null
                            ? '&returnDate=$returnDateStr&isRoundTrip=true'
                            : '';

                        context.push(
                          '/search-trips?fromCityId=$fromId&fromCityName=$fromName&toCityId=$toId&toCityName=$toName&date=$dateStr&ticketCount=${state.ticketCount}$returnQuery',
                          extra: extraMap,
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

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
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
              size: 20,
              color: DiscoveryColors.primary,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatFullDate(date),
                    style: DiscoveryTextStyles.titleSmall.copyWith(
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

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required ValueChanged<DateTime> onDateSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
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
}
