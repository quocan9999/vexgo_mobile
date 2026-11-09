import 'package:equatable/equatable.dart';
import '../../../../core/network/api_exceptions.dart';

/// A definite HTTP rejection, not an unknown create outcome. It never schedules
/// an automatic retry or invents a server-provided unlock timestamp.
class BookingRateLimit extends Equatable {
  final bool unpaidBookings;
  final bool existingOrder;
  const BookingRateLimit({
    required this.unpaidBookings,
    required this.existingOrder,
  });
  factory BookingRateLimit.fromError(
    ApiException error, {
    required bool existingOrder,
  }) => BookingRateLimit(
    unpaidBookings:
        error.statusCode == 429 &&
        error.errorCode == 'TOO_MANY_UNPAID_BOOKINGS',
    existingOrder: existingOrder,
  );
  String get title => unpaidBookings
      ? 'Cần kiểm tra các đơn trước'
      : 'Bạn đang thao tác quá nhanh';
  String get message => unpaidBookings
      ? 'Số điện thoại hoặc tài khoản đang có nhiều đơn chưa thanh toán hoặc lượt giữ chỗ hết hạn. Vui lòng kiểm tra các đơn trước hoặc quay lại sau 30 phút theo hướng dẫn của hệ thống.'
      : 'Hệ thống đang tạm giới hạn số lần thao tác. Vui lòng chờ một lúc rồi thử lại.';
  @override
  List<Object?> get props => [unpaidBookings, existingOrder];
}
