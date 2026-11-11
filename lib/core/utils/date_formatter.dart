import '../localization/locale_controller.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDuration(int? minutes, {String fallback = ''}) {
    if (minutes == null || minutes <= 0) return fallback;
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    final strings = LocaleController.strings;
    if (hours == 0) return strings.uiDurationMinutes(remainder);
    if (remainder == 0) return strings.uiDurationHours(hours);
    return strings.uiDurationHoursMinutes(hours, remainder);
  }

  static String formatFullDate(DateTime date) {
    final List<String> weekdays = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    final String weekday = LocaleController.instance.value.languageCode == 'en'
        ? const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ][date.weekday - 1]
        : weekdays[date.weekday - 1];
    final String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    return '$weekday, $formattedDate';
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  static String formatDayMonthYear(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String getWeekdayName(DateTime date) {
    final List<String> weekdays = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'CN',
    ];
    return LocaleController.instance.value.languageCode == 'en'
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday -
              1]
        : weekdays[date.weekday - 1];
  }
}
