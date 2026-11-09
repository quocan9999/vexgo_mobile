import '../localization/locale_controller.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static NumberFormat get _formatter => NumberFormat.currency(
    locale: LocaleController.instance.value.languageCode == 'en'
        ? 'en_US'
        : 'vi_VN',
    symbol: LocaleController.instance.value.languageCode == 'en' ? 'VND ' : 'đ',
    decimalDigits: 0,
  );

  static String format(num? amount) {
    return _formatter.format(amount ?? 0).replaceAll('₫', 'đ');
  }

  static String formatSimple(num? amount) {
    if (amount == null) return '0';
    return NumberFormat(
      '#,###',
      LocaleController.instance.value.languageCode == 'en' ? 'en_US' : 'vi_VN',
    ).format(amount);
  }
}
