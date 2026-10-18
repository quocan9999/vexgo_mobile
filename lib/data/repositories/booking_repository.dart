import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/utils/json_loader.dart';
import '../../core/utils/payment_provider_mapper.dart';
import '../datasources/remote/booking_remote_data_source.dart';
import '../datasources/remote/payment_remote_data_source.dart';
import '../datasources/remote/ticket_remote_data_source.dart';
import '../models/booking_model.dart';
import '../models/booking_quote_model.dart';
import '../models/notification_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/promotion_validation_model.dart';
import '../models/ticket_model.dart';
import '../models/voucher_model.dart';

/// Keeps recovery identifiers when a later checkout stage fails. Never permits
/// a network retry to silently recreate a committed booking.
class CheckoutProgressException implements Exception {
  final String message;
  final int? bookingId;
  final int? paymentId;
  final bool bookingOutcomeUnknown;
  final bool blockedByBackend;
  const CheckoutProgressException(
    this.message, {
    this.bookingId,
    this.paymentId,
    this.bookingOutcomeUnknown = false,
    this.blockedByBackend = false,
  });
  @override
  String toString() => message;
}

/// Booking endpoints contain ticket summaries. Boarding passes must come from
/// the full ticket endpoint, including settlement and cancellation information.
Future<List<TicketModel>> resolvePaidBookingTickets(
  BookingRepository repository,
  int bookingId,
) async {
  final booking = await repository.getBookingById(bookingId);
  if (booking == null ||
      booking.bookingId != bookingId ||
      booking.tickets.isEmpty ||
      (booking.ticketCount > 0 &&
          booking.ticketCount != booking.tickets.length)) {
    throw StateError(
      'Chưa tải được đầy đủ vé của đơn đặt chỗ. Vui lòng kiểm tra lại.',
    );
  }
  final tickets = <TicketModel>[];
  final ids = <String>{};
  for (final summary in booking.tickets) {
    if ((int.tryParse(summary.id) ?? 0) <= 0 || !ids.add(summary.id)) {
      throw StateError('Thông tin mã vé từ máy chủ không hợp lệ.');
    }
    final ticket = await repository.getTicketById(summary.id);
    if (ticket == null ||
        ticket.id != summary.id ||
        ticket.bookingId?.toString() != bookingId.toString() ||
        !ticket.hasFullDetails ||
        !ticket.canShowQr) {
      throw StateError(
        'Máy chủ chưa xác nhận vé đã thanh toán đầy đủ. Vui lòng kiểm tra lại.',
      );
    }
    tickets.add(ticket);
  }
  return List.unmodifiable(tickets);
}

Future<TicketModel> _createVerifiedBookingTicket({
  required BookingRepository repository,
  required BookingRemoteDataSource bookings,
  required PaymentRemoteDataSource payments,
  required TicketTripSummary trip,
  required List<String> seats,
  required String paymentMethod,
  required PassengerInfo passenger,
  List<int>? seatIds,
  String? holdToken,
  String? promotionCode,
}) async {
  final tripId = int.tryParse(trip.id);
  final ids = seatIds ?? seats.map(int.tryParse).whereType<int>().toList();
  if (tripId == null ||
      tripId <= 0 ||
      ids.isEmpty ||
      ids.length != seats.length ||
      ids.any((id) => id <= 0)) {
    throw ArgumentError('Thông tin chuyến đi hoặc danh sách ghế không hợp lệ.');
  }
  // Resolve the provider before creating any order.
  final provider = PaymentProviderMapper.toBackendProvider(paymentMethod);
  BookingModel? booking;
  PaymentTransactionModel? payment;
  try {
    booking = await bookings.createBooking(
      tripId: tripId,
      seatIds: ids,
      pickupPoint: trip.pickupPoint,
      dropoffPoint: trip.dropoffPoint,
      contact: passenger,
      holdToken: holdToken,
      promotionCode: promotionCode,
    );
    payment = await payments.createPayment(
      bookingId: booking.bookingId,
      provider: provider,
    );
    if (!ApiConfig.isDemoMode && payment.isDemo) {
      throw CheckoutProgressException(
        'BLOCKED_BY_BACKEND: Máy chủ chỉ hỗ trợ cổng thanh toán thử nghiệm.',
        bookingId: booking.bookingId,
        paymentId: payment.paymentId,
        blockedByBackend: true,
      );
    }
    final status = await payments.getPaymentStatus(payment.paymentId);
    if (status.paymentId != payment.paymentId ||
        status.bookingId != booking.bookingId ||
        status.amount != payment.amount ||
        (!ApiConfig.isDemoMode && status.isDemo)) {
      throw StateError('Thông tin giao dịch thanh toán không khớp.');
    }
    if (!status.isSuccess) {
      throw PaymentPendingException(
        message: status.isPending
            ? 'Giao dịch thanh toán chưa hoàn tất.'
            : 'Giao dịch không thành công. Kiểm tra đơn hiện tại trước khi thử lại.',
        paymentId: payment.paymentId,
        bookingId: booking.bookingId,
        paymentUrl: payment.paymentUrl ?? status.paymentUrl,
        qrCodeUrl: payment.qrCodeUrl ?? status.qrCodeUrl,
        deeplink: payment.deeplink ?? status.deeplink,
      );
    }
    return (await resolvePaidBookingTickets(
      repository,
      booking.bookingId,
    )).first;
  } on PaymentPendingException {
    rethrow;
  } on CheckoutProgressException {
    rethrow;
  } catch (error) {
    if (booking != null ||
        error is NetworkException ||
        (error is ApiException && error.statusCode >= 500)) {
      throw CheckoutProgressException(
        'Chưa xác minh được kết quả đặt vé. Vui lòng kiểm tra đơn hiện tại trước khi thử lại.',
        bookingId: booking?.bookingId,
        paymentId: payment?.paymentId,
        bookingOutcomeUnknown: booking == null,
      );
    }
    rethrow;
  }
}

abstract class BookingRepository {
  Future<List<VoucherModel>> getVouchers();
  Future<List<TicketModel>> getMyTickets();
  Future<TicketModel?> getTicketById(String id);
  Future<List<NotificationModel>> getNotifications();
  Future<TicketModel> createBooking({
    required TicketTripSummary trip,
    required List<String> seats,
    required int totalAmount,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required PassengerInfo passenger,
    List<int>? seatIds,
    String? holdToken,
    String? promotionCode,
  });

  // Person B Commerce & Fulfillment methods
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
  });

  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  });

  Future<BookingModel> createApiBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  });

  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider,
  });

  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId);

  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  });

  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  });

  Future<BookingModel?> getBookingById(dynamic bookingId);
}

class MockBookingRepository implements BookingRepository {
  List<VoucherModel>? _cachedVouchers;
  List<TicketModel>? _cachedTickets;
  List<NotificationModel>? _cachedNotifications;

  @override
  Future<BookingModel?> getBookingById(dynamic bookingId) async => null;

  @override
  Future<List<VoucherModel>> getVouchers() async {
    if (_cachedVouchers != null) return _cachedVouchers!;
    final List<Map<String, dynamic>> rawList = await JsonLoader.loadJsonList(
      'assets/mock_data/vouchers.json',
    );
    _cachedVouchers = rawList
        .map((item) => VoucherModel.fromJson(item))
        .toList();
    return _cachedVouchers!;
  }

  @override
  Future<List<TicketModel>> getMyTickets() async {
    if (_cachedTickets != null) return _cachedTickets!;
    final List<Map<String, dynamic>> rawList = await JsonLoader.loadJsonList(
      'assets/mock_data/my_tickets.json',
    );
    _cachedTickets = rawList.map((item) => TicketModel.fromJson(item)).toList();
    return _cachedTickets!;
  }

  @override
  Future<TicketModel?> getTicketById(String id) async {
    final tickets = await getMyTickets();
    try {
      return tickets.firstWhere((t) => t.id == id || t.ticketCode == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    if (_cachedNotifications != null) return _cachedNotifications!;
    final List<Map<String, dynamic>> rawList = await JsonLoader.loadJsonList(
      'assets/mock_data/notifications.json',
    );
    _cachedNotifications = rawList
        .map((item) => NotificationModel.fromJson(item))
        .toList();
    return _cachedNotifications!;
  }

  @override
  Future<TicketModel> createBooking({
    required TicketTripSummary trip,
    required List<String> seats,
    required int totalAmount,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required PassengerInfo passenger,
    List<int>? seatIds,
    String? holdToken,
    String? promotionCode,
  }) async {
    final tickets = await getMyTickets();
    final newCode = 'VXG-${100000 + tickets.length * 123 + 45}';
    final now = DateTime.now();
    final bookingDateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final newTicket = TicketModel(
      id: 'TKT_$newCode',
      ticketCode: newCode,
      status: TicketStatus.upcoming,
      bookingDate: bookingDateStr,
      trip: trip,
      seats: seats,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      paymentMethod: paymentMethod,
      passenger: passenger,
      licensePlate: '51B-${200 + tickets.length}.99',
      driverPhone: '0909 888 777',
    );

    _cachedTickets = [newTicket, ...tickets];
    return newTicket;
  }

  @override
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
  }) async {
    const unitPrice = 280000;
    final seatCount = seatIds.length;
    final originalTotal = unitPrice * seatCount;
    int discount = 0;
    if (promotionCode != null && promotionCode.toUpperCase() == 'SUMMER26') {
      discount = (originalTotal * 0.1).toInt();
    } else if (promotionCode != null &&
        promotionCode.toUpperCase() == 'VEXGO50') {
      discount = 50000;
    }
    return BookingQuoteModel(
      unitPrice: unitPrice,
      seatCount: seatCount,
      originalTotal: originalTotal,
      discountAmount: discount,
      finalTotal: originalTotal - discount,
      appliedPromotionCode: discount > 0 ? promotionCode : null,
      promotionDescription: discount > 0
          ? 'Mã giảm giá áp dụng thành công'
          : null,
    );
  }

  @override
  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  }) async {
    if (code.toUpperCase() == 'SUMMER26') {
      return const PromotionValidationModel(
        code: 'SUMMER26',
        isValid: true,
        discountAmount: 50000,
        discountPercent: 10,
        description: 'Giảm 10% tối đa 50.000đ',
      );
    }
    if (code.toUpperCase() == 'VEXGO50') {
      return const PromotionValidationModel(
        code: 'VEXGO50',
        isValid: true,
        discountAmount: 50000,
        description: 'Giảm trực tiếp 50.000đ',
      );
    }
    return const PromotionValidationModel(
      code: '',
      isValid: false,
      discountAmount: 0,
      reason: 'Mã khuyến mãi không hợp lệ hoặc đã hết hạn.',
    );
  }

  @override
  Future<BookingModel> createApiBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  }) async {
    final quote = await getBookingQuote(
      tripId: tripId,
      seatIds: seatIds,
      promotionCode: promotionCode,
    );
    final bookingId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return BookingModel(
      bookingId: bookingId,
      bookingCode: 'VXG-$bookingId',
      tripId: tripId,
      status: BookingStatus.pending,
      contact: contact,
      pickupPoint: pickupPoint,
      dropoffPoint: dropoffPoint,
      seats: seatIds.map((id) => 'Ghế $id').toList(),
      seatIds: seatIds,
      totalAmount: quote.finalTotal,
      originalAmount: quote.originalTotal,
      discountAmount: quote.discountAmount,
      promotionCode: promotionCode,
      holdToken: holdToken,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider,
  }) async {
    final prov = provider.toUpperCase();
    final paymentId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return PaymentTransactionModel(
      paymentId: paymentId,
      bookingId: bookingId,
      provider: prov == 'VNPAY'
          ? PaymentProvider.vnpay
          : (prov == 'ZALOPAY'
                ? PaymentProvider.zalopay
                : PaymentProvider.momo),
      amount: 450000,
      paymentUrl: 'https://test-payment.$prov.vn/pay?id=$paymentId',
      deeplink: '$prov://app?pay=$paymentId',
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId) async {
    return PaymentTransactionModel(
      paymentId: (paymentId is num) ? paymentId.toInt() : 123,
      bookingId: 456,
      provider: PaymentProvider.momo,
      amount: 450000,
      status: PaymentStatus.success,
      paidAt: DateTime.now(),
    );
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    final tickets = await getMyTickets();
    final index = tickets.indexWhere((t) => t.ticketCode == ticketCode);
    if (index >= 0) {
      final t = tickets[index];
      final fee = (t.finalAmount * expectedCancelFeeRate).round();
      final refund = t.finalAmount - fee;
      final updated = t.copyWith(
        status: TicketStatus.cancelled,
        cancelReason: reason,
        refundAmount: refund,
      );
      _cachedTickets![index] = updated;
      return {'success': true, 'refundAmount': refund, 'cancelFee': fee};
    }
    return {'success': true};
  }

  @override
  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    final tickets = await getMyTickets();
    try {
      return tickets.firstWhere((t) => t.ticketCode == ticketCode);
    } catch (_) {
      rethrow;
    }
  }
}

/// Hybrid booking repository: calls backend APIs, fallbacks to mock if offline
class HybridBookingRepository implements BookingRepository {
  final BookingRemoteDataSource remoteBookingDataSource;
  final PaymentRemoteDataSource remotePaymentDataSource;
  final TicketRemoteDataSource remoteTicketDataSource;
  final MockBookingRepository mockFallback;

  HybridBookingRepository({
    BookingRemoteDataSource? remoteBookingDataSource,
    PaymentRemoteDataSource? remotePaymentDataSource,
    TicketRemoteDataSource? remoteTicketDataSource,
    MockBookingRepository? mockFallback,
  }) : remoteBookingDataSource =
           remoteBookingDataSource ??
           BookingRemoteDataSourceImpl(client: ApiClient()),
       remotePaymentDataSource =
           remotePaymentDataSource ??
           PaymentRemoteDataSourceImpl(client: ApiClient()),
       remoteTicketDataSource =
           remoteTicketDataSource ??
           TicketRemoteDataSourceImpl(client: ApiClient()),
       mockFallback = mockFallback ?? MockBookingRepository();

  @override
  Future<List<VoucherModel>> getVouchers() => mockFallback.getVouchers();

  @override
  Future<List<TicketModel>> getMyTickets() async {
    try {
      final tickets = await remoteTicketDataSource.getCustomerTickets();
      if (tickets.isNotEmpty || !ApiConfig.isDemoMode) {
        return tickets;
      }
      return await mockFallback.getMyTickets();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridBookingRepository] Remote getMyTickets failed: $e');
      }
      if (ApiConfig.isDemoMode) {
        return await mockFallback.getMyTickets();
      }
      rethrow;
    }
  }

  @override
  Future<TicketModel?> getTicketById(String id) async {
    try {
      final parsedId = int.tryParse(id);
      if (parsedId != null) {
        return await remoteTicketDataSource.getCustomerTicketById(parsedId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridBookingRepository] Remote getTicketById failed: $e');
      }
      if (!ApiConfig.isDemoMode) {
        rethrow;
      }
    }
    if (ApiConfig.isDemoMode) {
      return mockFallback.getTicketById(id);
    }
    return null;
  }

  @override
  Future<List<NotificationModel>> getNotifications() =>
      mockFallback.getNotifications();

  @override
  Future<TicketModel> createBooking({
    required TicketTripSummary trip,
    required List<String> seats,
    required int totalAmount,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required PassengerInfo passenger,
    List<int>? seatIds,
    String? holdToken,
    String? promotionCode,
  }) async {
    return _createVerifiedBookingTicket(
      repository: this,
      bookings: remoteBookingDataSource,
      payments: remotePaymentDataSource,
      trip: trip,
      seats: seats,
      paymentMethod: paymentMethod,
      passenger: passenger,
      seatIds: seatIds,
      holdToken: holdToken,
      promotionCode: promotionCode,
    );
  }

  @override
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
  }) async {
    try {
      return await remoteBookingDataSource.getBookingQuote(
        tripId: tripId,
        seatIds: seatIds,
        promotionCode: promotionCode,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridBookingRepository] Remote quote failed: $e');
      }
      if (ApiConfig.isDemoMode) {
        return mockFallback.getBookingQuote(
          tripId: tripId,
          seatIds: seatIds,
          promotionCode: promotionCode,
        );
      }
      rethrow;
    }
  }

  @override
  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  }) async {
    try {
      return await remoteBookingDataSource.validatePromotion(
        code: code,
        tripId: tripId,
        seatCount: seatCount,
        totalAmount: totalAmount,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[HybridBookingRepository] Remote promo validation failed: $e',
        );
      }
      if (ApiConfig.isDemoMode) {
        return mockFallback.validatePromotion(
          code: code,
          tripId: tripId,
          seatCount: seatCount,
          totalAmount: totalAmount,
        );
      }
      rethrow;
    }
  }

  @override
  Future<BookingModel> createApiBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  }) async {
    if (tripId <= 0) {
      throw ArgumentError('Mã chuyến đi không hợp lệ ($tripId)');
    }
    if (seatIds.isEmpty || seatIds.any((id) => id <= 0)) {
      throw ArgumentError('Danh sách ghế không hợp lệ ($seatIds)');
    }
    try {
      return await remoteBookingDataSource.createBooking(
        tripId: tripId,
        seatIds: seatIds,
        pickupPoint: pickupPoint,
        dropoffPoint: dropoffPoint,
        contact: contact,
        promotionCode: promotionCode,
        holdToken: holdToken,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[HybridBookingRepository] Remote create booking failed: $e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider,
  }) async {
    try {
      return await remotePaymentDataSource.createPayment(
        bookingId: bookingId,
        provider: PaymentProviderMapper.toBackendProvider(provider),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[HybridBookingRepository] Remote create payment failed: $e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId) async {
    try {
      return await remotePaymentDataSource.getPaymentStatus(paymentId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[HybridBookingRepository] Remote get payment status failed: $e',
        );
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    try {
      final res = await remoteTicketDataSource.cancelTicket(
        ticketCode: ticketCode,
        phoneNumber: phoneNumber,
        reason: reason,
        expectedCancelFeeRate: expectedCancelFeeRate,
      );
      if (ApiConfig.isDemoMode) {
        try {
          await mockFallback.cancelTicket(
            ticketCode: ticketCode,
            phoneNumber: phoneNumber,
            reason: reason,
            expectedCancelFeeRate: expectedCancelFeeRate,
          );
        } catch (_) {}
      }
      return res;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridBookingRepository] Remote cancelTicket failed: $e');
      }
      if (ApiConfig.isDemoMode) {
        return await mockFallback.cancelTicket(
          ticketCode: ticketCode,
          phoneNumber: phoneNumber,
          reason: reason,
          expectedCancelFeeRate: expectedCancelFeeRate,
        );
      }
      rethrow;
    }
  }

  @override
  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    try {
      return await remoteTicketDataSource.lookupTicket(
        ticketCode: ticketCode,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      if (ApiConfig.isDemoMode) {
        return await mockFallback.lookupTicket(
          ticketCode: ticketCode,
          phoneNumber: phoneNumber,
        );
      }
      rethrow;
    }
  }

  @override
  Future<BookingModel?> getBookingById(dynamic bookingId) async {
    try {
      return await remoteBookingDataSource.getBookingById(bookingId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[HybridBookingRepository] Remote getBookingById failed: $e',
        );
      }
      rethrow;
    }
  }
}

/// Real booking repository: pure remote backend calls, no mock fallbacks
class RealBookingRepository implements BookingRepository {
  final BookingRemoteDataSource remoteBookingDataSource;
  final PaymentRemoteDataSource remotePaymentDataSource;
  final TicketRemoteDataSource remoteTicketDataSource;

  RealBookingRepository({
    BookingRemoteDataSource? remoteBookingDataSource,
    PaymentRemoteDataSource? remotePaymentDataSource,
    TicketRemoteDataSource? remoteTicketDataSource,
  }) : remoteBookingDataSource =
           remoteBookingDataSource ??
           BookingRemoteDataSourceImpl(client: ApiClient()),
       remotePaymentDataSource =
           remotePaymentDataSource ??
           PaymentRemoteDataSourceImpl(client: ApiClient()),
       remoteTicketDataSource =
           remoteTicketDataSource ??
           TicketRemoteDataSourceImpl(client: ApiClient());

  @override
  Future<List<VoucherModel>> getVouchers() async => const [];

  @override
  Future<List<TicketModel>> getMyTickets() async {
    return await remoteTicketDataSource.getCustomerTickets();
  }

  @override
  Future<TicketModel?> getTicketById(String id) async {
    final parsedId = int.tryParse(id);
    if (parsedId == null) return null;
    return await remoteTicketDataSource.getCustomerTicketById(parsedId);
  }

  @override
  Future<List<NotificationModel>> getNotifications() async => const [];

  @override
  Future<TicketModel> createBooking({
    required TicketTripSummary trip,
    required List<String> seats,
    required int totalAmount,
    required int discountAmount,
    required int finalAmount,
    required String paymentMethod,
    required PassengerInfo passenger,
    List<int>? seatIds,
    String? holdToken,
    String? promotionCode,
  }) async {
    return _createVerifiedBookingTicket(
      repository: this,
      bookings: remoteBookingDataSource,
      payments: remotePaymentDataSource,
      trip: trip,
      seats: seats,
      paymentMethod: paymentMethod,
      passenger: passenger,
      seatIds: seatIds,
      holdToken: holdToken,
      promotionCode: promotionCode,
    );
  }

  @override
  Future<BookingQuoteModel> getBookingQuote({
    required int tripId,
    required List<int> seatIds,
    String? promotionCode,
  }) {
    return remoteBookingDataSource.getBookingQuote(
      tripId: tripId,
      seatIds: seatIds,
      promotionCode: promotionCode,
    );
  }

  @override
  Future<PromotionValidationModel> validatePromotion({
    required String code,
    required int tripId,
    required int seatCount,
    required int totalAmount,
  }) {
    return remoteBookingDataSource.validatePromotion(
      code: code,
      tripId: tripId,
      seatCount: seatCount,
      totalAmount: totalAmount,
    );
  }

  @override
  Future<BookingModel> createApiBooking({
    required int tripId,
    required List<int> seatIds,
    required String pickupPoint,
    required String dropoffPoint,
    required PassengerInfo contact,
    String? promotionCode,
    String? holdToken,
  }) {
    if (tripId <= 0) {
      throw ArgumentError('Mã chuyến đi không hợp lệ ($tripId)');
    }
    if (seatIds.isEmpty || seatIds.any((id) => id <= 0)) {
      throw ArgumentError('Danh sách ghế không hợp lệ ($seatIds)');
    }
    return remoteBookingDataSource.createBooking(
      tripId: tripId,
      seatIds: seatIds,
      pickupPoint: pickupPoint,
      dropoffPoint: dropoffPoint,
      contact: contact,
      promotionCode: promotionCode,
      holdToken: holdToken,
    );
  }

  @override
  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider,
  }) {
    return remotePaymentDataSource.createPayment(
      bookingId: bookingId,
      provider: PaymentProviderMapper.toBackendProvider(provider),
    );
  }

  @override
  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId) {
    return remotePaymentDataSource.getPaymentStatus(paymentId);
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) {
    return remoteTicketDataSource.cancelTicket(
      ticketCode: ticketCode,
      phoneNumber: phoneNumber,
      reason: reason,
      expectedCancelFeeRate: expectedCancelFeeRate,
    );
  }

  @override
  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) {
    return remoteTicketDataSource.lookupTicket(
      ticketCode: ticketCode,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Future<BookingModel?> getBookingById(dynamic bookingId) async {
    try {
      return await remoteBookingDataSource.getBookingById(bookingId);
    } catch (_) {
      rethrow;
    }
  }
}
