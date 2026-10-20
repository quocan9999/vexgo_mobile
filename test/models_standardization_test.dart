import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_response.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/seat_hold_model.dart';
import 'package:vexgo_app/data/models/booking_quote_model.dart';
import 'package:vexgo_app/data/models/promotion_validation_model.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/payment_transaction_model.dart';

void main() {
  group('Task 1: Model & DTO Standardization Tests', () {
    // -------------------------------------------------------------------------
    // 1. ApiResponse & ApiPaginatedResponse & ApiError
    // -------------------------------------------------------------------------
    group('ApiResponse & ApiError', () {
      test('Single ApiResponse success', () {
        const response = ApiResponse<String>(data: 'Hello VexGo');
        expect(response.isSuccess, isTrue);
        expect(response.hasError, isFalse);
        expect(response.data, equals('Hello VexGo'));
      });

      test('Paginated response with ApiPaginationMeta', () {
        final metaJson = {
          'page': 1,
          'pageSize': 10,
          'totalItems': 45,
          'totalPages': 5,
        };
        final meta = ApiPaginationMeta.fromJson(metaJson);
        expect(meta.page, equals(1));
        expect(meta.pageSize, equals(10));
        expect(meta.totalItems, equals(45));
        expect(meta.totalPages, equals(5));
        expect(meta.hasNextPage, isTrue);
        expect(meta.hasPreviousPage, isFalse);

        final paginated = ApiPaginatedResponse<int>.success([1, 2, 3], meta);
        expect(paginated.isSuccess, isTrue);
        expect(paginated.data.length, equals(3));
        expect(paginated.meta.totalItems, equals(45));
      });

      test('ApiError parses string code and details per rule-api.md', () {
        final errJson = {
          'statusCode': 400,
          'error': 'VALIDATION_ERROR',
          'message': 'Dữ liệu không hợp lệ.',
          'details': [
            {'field': 'seatIds', 'message': 'Ghế không được để trống.'},
          ],
        };
        final err = ApiError.fromJson(errJson);
        expect(err.statusCode, equals(400));
        expect(err.errorCode, equals('VALIDATION_ERROR'));
        expect(err.message, equals('Dữ liệu không hợp lệ.'));
        expect(err.details.length, equals(1));
        expect(err.details.first.field, equals('seatIds'));
        expect(err.details.first.message, equals('Ghế không được để trống.'));
      });

      test('ApiError handles nested error object safely', () {
        final errJson = {
          'statusCode': 409,
          'error': {
            'code': 'SEAT_UNAVAILABLE',
            'message': 'Ghế A01 đã có người giữ',
          },
        };
        final err = ApiError.fromJson(errJson);
        expect(err.statusCode, equals(409));
        expect(err.errorCode, equals('SEAT_UNAVAILABLE'));
        expect(err.message, equals('Ghế A01 đã có người giữ'));
      });
    });

    // -------------------------------------------------------------------------
    // 2. TripModel Backend Contract Mapping
    // -------------------------------------------------------------------------
    group('TripModel Contract', () {
      test(
        'parses real backend trip JSON with tripId, busCompanyId, price',
        () {
          final backendJson = {
            'tripId': 101,
            'routeId': 20,
            'busCompanyId': 5,
            'busCompanyName': 'Phương Trang FUTA',
            'vehicleTypeName': 'Limousine 34 Phòng',
            'price': 280000,
            'availableSeats': 14,
            'totalSeats': 34,
            'departureTime': '2026-10-01T08:00:00+07:00',
            'arrivalTime': '2026-10-01T14:30:00+07:00',
            'fromCityName': 'TP. Hồ Chí Minh',
            'toCityName': 'Đà Lạt',
            'pickupPoint': 'Bến xe Miền Đông mới',
            'pickupAddress': 'TP. Thủ Đức',
            'dropoffPoint': 'Bến xe Đà Lạt',
            'dropoffAddress': '01 Tô Hiến Thành',
          };

          final trip = TripModel.fromJson(backendJson);
          expect(trip.id, equals('101'));
          expect(trip.numericTripId, equals(101));
          expect(trip.operatorId, equals('5'));
          expect(trip.numericOperatorId, equals(5));
          expect(trip.operatorName, equals('Phương Trang FUTA'));
          expect(trip.busCompanyName, equals('Phương Trang FUTA'));
          expect(trip.routeId, equals('20'));
          expect(trip.numericRouteId, equals(20));
          expect(trip.vehicleType, equals('Limousine 34 Phòng'));
          expect(trip.discountPrice, equals(280000));
          expect(trip.originalPrice, equals(280000));
          expect(trip.availableSeats, equals(14));
          expect(trip.totalSeats, equals(34));
        },
      );

      test('remains backward compatible with legacy mock JSON format', () {
        final legacyJson = {
          'id': 'TRIP_MOCK_1',
          'operatorId': 'OP_FUTA',
          'operatorName': 'Phương Trang',
          'vehicleType': 'Giường nằm 40 chỗ',
          'originalPrice': 300000,
          'discountPrice': 250000,
          'availableSeats': 8,
          'totalSeats': 40,
          'departureTime': '22:00',
          'arrivalTime': '05:00',
          'fromCityId': 'SGN',
          'fromCityName': 'Sài Gòn',
          'toCityId': 'DLT',
          'toCityName': 'Đà Lạt',
        };

        final trip = TripModel.fromJson(legacyJson);
        expect(trip.id, equals('TRIP_MOCK_1'));
        expect(trip.operatorId, equals('OP_FUTA'));
        expect(trip.operatorName, equals('Phương Trang'));
        expect(trip.originalPrice, equals(300000));
        expect(trip.discountPrice, equals(250000));
      });
    });

    // -------------------------------------------------------------------------
    // 3. SeatModel Backend Contract & Concurrency Status
    // -------------------------------------------------------------------------
    group('SeatModel Contract', () {
      test('parses Vietnamese and English seat statuses properly', () {
        final seatHeld = SeatModel.fromJson({
          'seatId': 10,
          'seatCode': 'A01',
          'floor': 1,
          'status': 'DANG_GIU',
          'price': 290000,
          'row': 1,
          'col': 1,
        });
        expect(seatHeld.id, equals('10'));
        expect(seatHeld.numericSeatId, equals(10));
        expect(seatHeld.name, equals('A01'));
        expect(seatHeld.status, equals(SeatStatus.held));
        expect(seatHeld.isHeld, isTrue);
        expect(seatHeld.isAvailable, isFalse);

        final seatBooked = SeatModel.fromJson({
          'seatId': 11,
          'seatCode': 'A02',
          'floor': 1,
          'status': 'DA_DAT',
          'price': 290000,
        });
        expect(seatBooked.status, equals(SeatStatus.booked));
        expect(seatBooked.isBooked, isTrue);

        final seatAvail = SeatModel.fromJson({
          'seatId': 12,
          'seatCode': 'A03',
          'floor': 1,
          'status': 'TRONG',
          'price': 290000,
        });
        expect(seatAvail.status, equals(SeatStatus.available));
        expect(seatAvail.isAvailable, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // 4. SeatHoldModel (Giữ ghế & Đếm ngược)
    // -------------------------------------------------------------------------
    group('SeatHoldModel', () {
      test('calculates countdown timer correctly', () {
        final now = DateTime.now();
        final expires = now.add(const Duration(minutes: 9, seconds: 45));

        final hold = SeatHoldModel(
          holdToken: 'uuid-hold-token-123',
          tripId: 101,
          seatIds: const [10, 11],
          seatCodes: const ['A01', 'A02'],
          expiresAt: expires,
        );

        expect(hold.isExpired, isFalse);
        expect(hold.remainingSeconds, inInclusiveRange(580, 586));
        expect(hold.formattedRemainingTime, contains('09:'));

        final json = hold.toJson();
        expect(json['holdToken'], equals('uuid-hold-token-123'));
        expect(json['tripId'], equals(101));
        expect(json['seatIds'], equals([10, 11]));

        final parsed = SeatHoldModel.fromJson(json);
        expect(parsed.holdToken, equals('uuid-hold-token-123'));
        expect(parsed.seatIds, equals([10, 11]));
      });

      test('detects expired hold correctly', () {
        final past = DateTime.now().subtract(const Duration(seconds: 10));
        final expiredHold = SeatHoldModel(
          holdToken: 'expired-token',
          tripId: 101,
          seatIds: const [10],
          expiresAt: past,
        );
        expect(expiredHold.isExpired, isTrue);
        expect(expiredHold.remainingSeconds, equals(0));
        expect(expiredHold.formattedRemainingTime, equals('00:00'));
      });
    });

    // -------------------------------------------------------------------------
    // 5. BookingQuoteModel (Báo giá preview từ Backend)
    // -------------------------------------------------------------------------
    group('BookingQuoteModel', () {
      test('parses quote calculation from backend correctly', () {
        final quoteJson = {
          'unitPrice': 250000,
          'seatCount': 2,
          'originalTotal': 500000,
          'discountAmount': 50000,
          'serviceFee': 0,
          'finalTotal': 450000,
          'currency': 'VND',
          'appliedPromotionCode': 'SUMMER26',
          'promotionDescription': 'Giảm 10% tối đa 50k',
        };

        final quote = BookingQuoteModel.fromJson(quoteJson);
        expect(quote.unitPrice, equals(250000));
        expect(quote.seatCount, equals(2));
        expect(quote.originalTotal, equals(500000));
        expect(quote.discountAmount, equals(50000));
        expect(quote.finalTotal, equals(450000));
        expect(quote.appliedPromotionCode, equals('SUMMER26'));
        expect(quote.promotionDescription, equals('Giảm 10% tối đa 50k'));

        final serialized = quote.toJson();
        expect(serialized['finalTotal'], equals(450000));
        expect(serialized['currency'], equals('VND'));
      });
    });

    // -------------------------------------------------------------------------
    // 6. PromotionValidationModel
    // -------------------------------------------------------------------------
    group('PromotionValidationModel', () {
      test('handles valid and invalid promo codes', () {
        final valid = PromotionValidationModel.fromJson({
          'code': 'VEXGO50',
          'isValid': true,
          'discountAmount': 50000,
          'description': 'Giảm 50.000đ cho đơn từ 200k',
        });
        expect(valid.isValid, isTrue);
        expect(valid.discountAmount, equals(50000));

        final invalid = PromotionValidationModel.fromJson({
          'code': 'EXPIRED_CODE',
          'isValid': false,
          'discountAmount': 0,
          'reason': 'Mã ưu đãi đã hết lượt áp dụng.',
        });
        expect(invalid.isValid, isFalse);
        expect(invalid.discountAmount, equals(0));
        expect(invalid.reason, equals('Mã ưu đãi đã hết lượt áp dụng.'));
      });
    });

    // -------------------------------------------------------------------------
    // 7. BookingModel
    // -------------------------------------------------------------------------
    group('BookingModel', () {
      test('parses backend booking order response', () {
        final bookingJson = {
          'bookingId': 888,
          'bookingCode': 'VXG-2026-888',
          'tripId': 101,
          'status': 'CHO_THANH_TOAN',
          'contact': {
            'fullName': 'Nguyễn Hải Yến',
            'phone': '0912345678',
            'email': 'haiyen@example.com',
          },
          'pickupPoint': 'Bến xe Miền Đông mới',
          'dropoffPoint': 'Bến xe Đà Lạt',
          'seats': ['A01', 'A02'],
          'seatIds': [10, 11],
          'totalAmount': 450000,
          'originalAmount': 500000,
          'discountAmount': 50000,
          'promotionCode': 'SUMMER26',
          'holdToken': 'hold-token-xyz',
          'createdAt': '2026-09-30T10:20:00.000Z',
          'expiresAt': '2026-09-30T10:35:00.000Z',
        };

        final booking = BookingModel.fromJson(bookingJson);
        expect(booking.bookingId, equals(888));
        expect(booking.bookingCode, equals('VXG-2026-888'));
        expect(booking.tripId, equals(101));
        expect(booking.status, equals(BookingStatus.pending));
        expect(booking.isPending, isTrue);
        expect(booking.contact.fullName, equals('Nguyễn Hải Yến'));
        expect(booking.seats, equals(['A01', 'A02']));
        expect(booking.seatIds, equals([10, 11]));
        expect(booking.totalAmount, equals(450000));
        expect(booking.holdToken, equals('hold-token-xyz'));

        final jsonOut = booking.toJson();
        expect(jsonOut['status'], equals('CHO_THANH_TOAN'));
        expect(jsonOut['bookingId'], equals(888));
      });
    });

    // -------------------------------------------------------------------------
    // 8. PaymentTransactionModel
    // -------------------------------------------------------------------------
    group('PaymentTransactionModel', () {
      test('parses payment gateway transaction and url/deeplink', () {
        final paymentJson = {
          'paymentId': 999,
          'bookingId': 888,
          'provider': 'MOMO',
          'amount': 450000,
          'paymentUrl':
              'https://test-payment.momo.vn/v2/gateway/pay?orderId=123',
          'deeplink': 'momo://app?action=pay&orderId=123',
          'qrCodeUrl': 'https://test-payment.momo.vn/qr/123.png',
          'status': 'PENDING',
        };

        final payment = PaymentTransactionModel.fromJson(paymentJson);
        expect(payment.paymentId, equals(999));
        expect(payment.bookingId, equals(888));
        expect(payment.provider, equals(PaymentProvider.momo));
        expect(payment.amount, equals(450000));
        expect(payment.paymentUrl, contains('momo.vn'));
        expect(payment.deeplink, contains('momo://'));
        expect(payment.status, equals(PaymentStatus.pending));
        expect(payment.isPending, isTrue);

        final jsonOut = payment.toJson();
        expect(jsonOut['provider'], equals('MOMO'));
        expect(jsonOut['status'], equals('PENDING'));
      });
    });
  });
}
