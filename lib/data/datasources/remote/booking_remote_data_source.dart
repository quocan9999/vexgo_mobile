import '../../models/booking_model.dart';
import '../../models/booking_quote_model.dart';
import '../../models/promotion_validation_model.dart';
import '../../models/ticket_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/token_storage.dart';

abstract class BookingRemoteDataSource {
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
    String? contactPhone,
  });

  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  });

  Future<BookingModel> createBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  });

  Future<BookingModel> getBookingById(dynamic bookingId);
  Future<List<BookingModel>> getMyBookings({int page = 1, int pageSize = 10});
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient client;
  final Map<String, PassengerInfo> _checkoutContacts = {};
  final Map<String, String> _checkoutCodes = {};
  final Map<String, bool> _guestCheckouts = {};
  bool isGuestCheckout(int bookingId) =>
      _guestCheckouts[bookingId.toString()] == true;

  BookingRemoteDataSourceImpl({required this.client});

  @override
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
    String? contactPhone,
  }) async {
    final body = {
      'tripId': tripId,
      'seatIds': seatIds,
      if (contactPhone != null && contactPhone.trim().isNotEmpty)
        'contactPhone': contactPhone.trim(),
      if (promotionCode != null && promotionCode.isNotEmpty)
        'promotionCode': promotionCode,
    };

    final res = await client.post(
      ApiConfig.bookingQuote,
      body: body,
      optionalAuth: true,
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return BookingQuoteModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid booking quote response');
  }

  @override
  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  }) async {
    final body = {
      'code': code,
      'tripId': tripId,
      'seatCount': seatCount,
      'totalAmount': totalAmount,
    };

    final res = await client.post(ApiConfig.promotionsValidate, body: body);
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return PromotionValidationModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid promotion validation response');
  }

  @override
  Future<BookingModel> createBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  }) async {
    if (holdToken == null || holdToken.isEmpty) {
      throw ArgumentError('Cần mã giữ ghế còn hiệu lực để tạo đơn.');
    }
    final guest = !await TokenStorage.hasAccessToken();

    final body = {
      'tripId': tripId,
      'seatIds': seatIds,
      'pickupPoint': pickupPoint,
      'dropoffPoint': dropoffPoint,
      'contact': contact.toJson(),
      if (promotionCode != null && promotionCode.isNotEmpty)
        'promotionCode': promotionCode,
      'holdToken': holdToken,
    };

    final res = await client.post(
      ApiConfig.bookings,
      body: body,
      optionalAuth: true,
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      final booking = BookingModel.fromJson(data as Map<String, dynamic>);
      _checkoutContacts[booking.bookingId.toString()] = contact;
      _checkoutCodes[booking.bookingId.toString()] = booking.bookingCode;
      _guestCheckouts[booking.bookingId.toString()] = guest;
      return booking;
    }
    throw Exception('Invalid create booking response');
  }

  @override
  Future<BookingModel> getBookingById(dynamic bookingId) async {
    final guest =
        _guestCheckouts[bookingId.toString()] ??
        !await TokenStorage.hasAccessToken();
    final contact = _checkoutContacts[bookingId.toString()];
    final code = _checkoutCodes[bookingId.toString()];
    if (guest && (contact == null || code == null || code.isEmpty)) {
      throw StateError(
        'Thiếu mã đặt vé và số điện thoại để tra cứu đơn khách.',
      );
    }
    final res = await client.get(
      guest
          ? '${ApiConfig.bookingDetail(bookingId)}/detail'
          : ApiConfig.bookingDetail(bookingId),
      requiresAuth: !guest,
      headers: guest
          ? {'x-booking-code': code!, 'x-booking-phone': contact!.phone}
          : null,
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return BookingModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid booking detail response');
  }

  @override
  Future<List<BookingModel>> getMyBookings({
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = {'page': page, 'pageSize': pageSize};
    final res = await client.get(
      ApiConfig.bookings,
      queryParams: query,
      requiresAuth: true,
    );
    if (res is Map<String, dynamic> && res['data'] is List) {
      final list = res['data'] as List;
      return list
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
