import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';

class DateSelectorStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final int minPrice;

  const DateSelectorStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.minPrice = 240000,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Generate a range of 14 days from today
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: 6,
        ),
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          // Format price: e.g. 240k or 280k
          final priceK = '${(minPrice / 1000).round()}k';

          final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
          final tomorrow = today.add(const Duration(days: 1));
          final isTomorrow = date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;

          String dateTitle;
          if (isToday) {
            dateTitle = 'Hôm nay';
          } else if (isTomorrow) {
            dateTitle = 'Ngày mai';
          } else {
            const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
            final weekdayName = weekdays[date.weekday - 1];
            final dayMonth = DateFormat('dd/MM').format(date);
            dateTitle = '$weekdayName, $dayMonth';
          }

          return InkWell(
            onTap: () => onDateSelected(date),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 82,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.neutral50,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral200,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateTitle,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.neutral700,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    priceK,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.secondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
