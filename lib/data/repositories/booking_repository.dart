import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/utils/json_loader.dart';
import '../../core/utils/payment_provider_mapper.dart';
import '../datasources/remote/booking_remote_data_source.dart';
import '../datasources/remote/payment_remote_data_source.dart';
import '../models/booking_model.dart';
import '../models/booking_quote_model.dart';
import '../models/notification_model.dart';
import '../models/payment_transaction_model.dart';
import '../models/promotion_validation_model.dart';
import '../models/ticket_model.dart';
import '../models/voucher_model.dart';

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
}

class MockBookingRepository implements BookingRepository {
  List<VoucherModel>? _cachedVouchers;
  List<TicketModel>? _cachedTickets;
  List<NotificationModel>? _cachedNotifications;

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
}

/// Hybrid booking repository: calls backend APIs, fallbacks to mock if offline
class HybridBookingRepository implements BookingRepository {
  final BookingRemoteDataSource remoteBookingDataSource;
  final PaymentRemoteDataSource remotePaymentDataSource;
  final MockBookingRepository mockFallback;

  HybridBookingRepository({
    BookingRemoteDataSource? remoteBookingDataSource,
    PaymentRemoteDataSource? remotePaymentDataSource,
    MockBookingRepository? mockFallback,
  }) : remoteBookingDataSource =
           remoteBookingDataSource ??
           BookingRemoteDataSourceImpl(client: ApiClient()),
       remotePaymentDataSource =
           remotePaymentDataSource ??
           PaymentRemoteDataSourceImpl(client: ApiClient()),
       mockFallback = mockFallback ?? MockBookingRepository();

  @override
  Future<List<VoucherModel>> getVouchers() => mockFallback.getVouchers();

  @override
  Future<List<TicketModel>> getMyTickets() => mockFallback.getMyTickets();

  @override
  Future<TicketModel?> getTicketById(String id) =>
      mockFallback.getTicketById(id);

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
    final tripId = int.tryParse(trip.id);
    if (tripId == null || tripId <= 0) {
      throw ArgumentError('Mã chuyến đi không hợp lệ (${trip.id})');
    }

    final resolvedSeatIds =
        seatIds ?? seats.map((s) => int.tryParse(s)).whereType<int>().toList();

    if (resolvedSeatIds.length != seats.length ||
        resolvedSeatIds.isEmpty ||
        resolvedSeatIds.any((id) => id <= 0)) {
      throw ArgumentError('Danh sách ghế không hợp lệ ($seats)');
    }

    try {
      final booking = await remoteBookingDataSource.createBooking(
        tripId: tripId,
        seatIds: resolvedSeatIds,
        pickupPoint: trip.pickupPoint,
        dropoffPoint: trip.dropoffPoint,
        contact: passenger,
        holdToken: holdToken,
        promotionCode: promotionCode,
      );

      // Create and verify payment transaction in MySQL
      final backendProvider = PaymentProviderMapper.toBackendProvider(
        paymentMethod,
      );
      final payment = await remotePaymentDataSource.createPayment(
        bookingId: booking.bookingId,
        provider: backendProvider,
      );

      final paymentStatus = await remotePaymentDataSource.getPaymentStatus(
        payment.paymentId,
      );

      final resolvedPaymentId = paymentStatus.paymentId > 0
          ? paymentStatus.paymentId
          : payment.paymentId;

      if (paymentStatus.isFailed) {
        throw PaymentFailedException(
          message:
              paymentStatus.failureReason ?? 'Giao dịch thanh toán thất bại.',
          failureReason: paymentStatus.failureReason,
          paymentId: resolvedPaymentId,
        );
      }

      if (paymentStatus.isPending) {
        throw PaymentPendingException(
          message: 'Giao dịch thanh toán đang được xử lý hoặc chưa hoàn tất.',
          paymentId: resolvedPaymentId,
          paymentUrl: paymentStatus.paymentUrl,
          qrCodeUrl: paymentStatus.qrCodeUrl,
          deeplink: paymentStatus.deeplink,
        );
      }

      if (!paymentStatus.isSuccess) {
        throw PaymentFailedException(
          message:
              'Trạng thái thanh toán không hợp lệ: ${paymentStatus.status.name}',
          paymentId: resolvedPaymentId,
        );
      }

      final now = DateTime.now();
      final bookingDateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Use authoritative pricing calculated by backend BookingModel
      final authoritativeTotal = booking.originalAmount > 0
          ? booking.originalAmount
          : (booking.totalAmount + booking.discountAmount);
      final authoritativeDiscount = booking.discountAmount;
      final authoritativeFinal = booking.totalAmount;

      final newTicket = TicketModel(
        id: 'TKT_${booking.bookingCode}',
        ticketCode: booking.bookingCode,
        status: TicketStatus.upcoming,
        bookingDate: bookingDateStr,
        trip: trip,
        seats: booking.seats.isNotEmpty ? booking.seats : seats,
        totalAmount: authoritativeTotal,
        discountAmount: authoritativeDiscount,
        finalAmount: authoritativeFinal,
        paymentMethod: paymentMethod,
        passenger: passenger,
        licensePlate: null,
        driverPhone: null,
      );

      return newTicket;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HybridBookingRepository] Remote booking failed: $e');
      }
      rethrow;
    }
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
        debugPrint(
          '[HybridBookingRepository] Remote quote failed, fallback to mock: $e',
        );
      }
      return mockFallback.getBookingQuote(
        tripId: tripId,
        seatIds: seatIds,
        promotionCode: promotionCode,
      );
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
          '[HybridBookingRepository] Remote promo validation failed, fallback to mock: $e',
        );
      }
      return mockFallback.validatePromotion(
        code: code,
        tripId: tripId,
        seatCount: seatCount,
        totalAmount: totalAmount,
      );
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
}
