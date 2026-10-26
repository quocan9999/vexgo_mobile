import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/token_storage.dart';
import '../datasources/remote/booking_receipt_remote_data_source.dart';
import '../models/booking_receipt_model.dart';

abstract class BookingReceiptRepository {
  factory BookingReceiptRepository.forCurrentMode() => ApiConfig.isDemoMode
      ? const UnavailableBookingReceiptRepository()
      : RealBookingReceiptRepository();
  Future<BookingReceipt> lookup({required String code, required String phone});
}

/// Offline tickets are not evidence of a paid order in the live system.
class UnavailableBookingReceiptRepository implements BookingReceiptRepository {
  const UnavailableBookingReceiptRepository();

  @override
  Future<BookingReceipt> lookup({
    required String code,
    required String phone,
  }) async {
    throw const ReceiptUnavailable(
      'Tra cứu chứng từ chỉ khả dụng khi kết nối hệ thống thật.',
    );
  }
}

class RealBookingReceiptRepository implements BookingReceiptRepository {
  final BookingReceiptRemoteDataSource remote;
  RealBookingReceiptRepository({BookingReceiptRemoteDataSource? remote})
    : remote = remote ?? BookingReceiptRemoteDataSource(ApiClient());

  @override
  Future<BookingReceipt> lookup({
    required String code,
    required String phone,
  }) async {
    final session = TokenStorage.sessionVersion;
    final token = await TokenStorage.getAccessToken();
    void checkSession() {
      if (TokenStorage.sessionVersion != session) {
        throw const ReceiptUnavailable(
          'Phiên đã thay đổi. Vui lòng mở lại tra cứu.',
        );
      }
    }

    checkSession();
    final input = code.trim();
    final contact = phone.trim();
    if (input.isEmpty || contact.isEmpty) {
      throw const FormatException('Vui lòng nhập mã và số điện thoại.');
    }
    // Resolve the booking through the existing code+phone contract, never a guessed ID.
    final ticket = await remote.lookup(input, contact);
    checkSession();
    final id = BookingReceipt.positiveId(ticket['bookingId']);
    final bookingCode = BookingReceipt.text(ticket['bookingCode']);
    final ticketCode = BookingReceipt.text(ticket['ticketCode']);
    if (bookingCode.isEmpty || ticketCode.isEmpty) {
      throw const FormatException('Thiếu liên kết vé với đơn đặt vé.');
    }
    final raw = await remote.detail(
      id,
      bookingCode,
      contact,
      authenticated: token != null && token.isNotEmpty,
    );
    checkSession();
    final receipt = BookingReceipt.fromJson(raw);
    if (receipt.bookingId != id ||
        receipt.bookingCode != bookingCode ||
        !receipt.tickets.any((item) => item.code == ticketCode) ||
        ![ticketCode, bookingCode, receipt.orderCode].contains(input)) {
      throw const FormatException('Chứng từ trả về không khớp với yêu cầu.');
    }
    return receipt;
  }
}
