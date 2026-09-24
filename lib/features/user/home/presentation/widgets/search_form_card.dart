import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../screens/select_city_sheet.dart';

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
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.neutral900,
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
            border: Border.all(color: AppColors.neutral200),
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
                          iconColor: AppColors.primary,
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
                          child: const Divider(height: 1, color: AppColors.neutral200),
                        ),

                        // Destination City
                        _buildCityRow(
                          context,
                          icon: Icons.location_on_rounded,
                          iconColor: AppColors.secondary,
                          label: 'Điểm đến',
                          cityName: state.destinationCity?.name ?? 'Chọn điểm đến',
                          province: state.destinationCity?.region,
                          onTap: () async {
                            final selected = await SelectCitySheet.show(
                              context,
                              title: 'Chọn điểm đến',
                              cities: state.cities,
                              currentCity: state.destinationCity,
                            );
                            if (selected != null) {
                              homeBloc.add(SelectDestinationCityEvent(selected));
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.neutral200),
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.neutral200),

              // Date Selection Section
              Padding(
                padding: const EdgeInsets.all(AppDimensions.base),
                child: Column(
                  children: [
                    // One-way / Round-trip selector
                    Row(
                      children: [
                        _buildTripTypeChip(
                          label: 'Một chiều',
                          isSelected: !state.isRoundTrip,
                          onTap: () => homeBloc.add(const ToggleRoundTripEvent(false)),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        _buildTripTypeChip(
                          label: 'Khứ hồi',
                          isSelected: state.isRoundTrip,
                          onTap: () => homeBloc.add(const ToggleRoundTripEvent(true)),
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
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.all(AppDimensions.sm + 2),
                              decoration: BoxDecoration(
                                color: AppColors.neutral50,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                border: Border.all(color: AppColors.neutral200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppDimensions.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ngày đi',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.neutral500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormatter.formatFullDate(state.departureDate),
                                          style: AppTextStyles.titleSmall.copyWith(
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
                                initialDate: state.returnDate ??
                                    state.departureDate.add(const Duration(days: 1)),
                                firstDate: state.departureDate,
                                onDateSelected: (date) =>
                                    homeBloc.add(SelectReturnDateEvent(date)),
                              ),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                              child: Container(
                                padding: const EdgeInsets.all(AppDimensions.sm + 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neutral50,
                                  borderRadius:
                                      BorderRadius.circular(AppDimensions.radiusMd),
                                  border: Border.all(color: AppColors.neutral200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_repeat_rounded,
                                      size: 18,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: AppDimensions.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ngày về',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.neutral500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            state.returnDate != null
                                                ? DateFormatter.formatFullDate(state.returnDate!)
                                                : 'Chọn ngày về',
                                            style: AppTextStyles.titleSmall.copyWith(
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
                    Row(
                      children: [
                        _buildQuickDateChip(
                          label: 'Hôm nay',
                          isSelected: _isSameDay(state.departureDate, DateTime.now()),
                          onTap: () => homeBloc.add(SelectDepartureDateEvent(DateTime.now())),
                        ),
                        const SizedBox(width: AppDimensions.xs),
                        _buildQuickDateChip(
                          label: 'Ngày mai',
                          isSelected: _isSameDay(
                            state.departureDate,
                            DateTime.now().add(const Duration(days: 1)),
                          ),
                          onTap: () => homeBloc.add(
                            SelectDepartureDateEvent(DateTime.now().add(const Duration(days: 1))),
                          ),
                        ),
                        const Spacer(),
                        // Number of tickets
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neutral100,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => homeBloc
                                    .add(UpdateTicketCountEvent(state.ticketCount - 1)),
                                child: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 18,
                                  color: AppColors.neutral700,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  '${state.ticketCount} vé',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => homeBloc
                                    .add(UpdateTicketCountEvent(state.ticketCount + 1)),
                                child: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                  color: AppColors.neutral700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.base),

                    // Primary Search Button
                    CustomButton(
                      text: 'Tìm Chuyến Xe Khách',
                      prefixIcon: const Icon(
                        Icons.directions_bus_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      width: double.infinity,
                      onPressed: () {
                        final fromId = state.departureCity?.id ?? 'HCM';
                        final fromName = state.departureCity?.name ?? 'TP. Hồ Chí Minh';
                        final toId = state.destinationCity?.id ?? 'DL';
                        final toName = state.destinationCity?.name ?? 'Đà Lạt';
                        final d = state.departureDate;
                        final dateStr =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

                        context.push(
                          '/search-trips?fromCityId=$fromId&fromCityName=$fromName&toCityId=$toId&toCityName=$toName&date=$dateStr&ticketCount=${state.ticketCount}',
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
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cityName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutral900,
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
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  province,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.neutral600,
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutral300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.primary : AppColors.neutral600,
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
          color: isSelected ? AppColors.primary : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.neutral700,
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
