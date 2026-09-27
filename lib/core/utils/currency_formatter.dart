import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static String format(num? amount) {
    if (amount == null) return '0 đ';
    return _formatter.format(amount).replaceAll('₫', 'đ');
  }

  static String formatSimple(num? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,###', 'vi_VN').format(amount);
  }
}
