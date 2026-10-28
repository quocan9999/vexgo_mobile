import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../models/booking_receipt_model.dart';

class BookingReceiptRemoteDataSource {
  final ApiClient client;
  BookingReceiptRemoteDataSource(this.client);

  Future<Map<String, dynamic>> lookup(String code, String phone) async {
    final response = BookingReceipt.object(
      await client.post(
        ApiConfig.ticketLookup,
        body: {'ticketCode': code, 'phoneNumber': phone},
      ),
    );
    return BookingReceipt.object(response['data']);
  }

  Future<Map<String, dynamic>> detail(
    int id,
    String code,
    String phone, {
    required bool authenticated,
  }) async {
    final response = BookingReceipt.object(
      await client.get(
        '${ApiConfig.bookingDetail(id)}/detail',
        requiresAuth: authenticated,
        headers: {'x-booking-code': code, 'x-booking-phone': phone},
      ),
    );
    return BookingReceipt.object(response['data']);
  }
}
