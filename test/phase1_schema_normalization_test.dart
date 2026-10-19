import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/features/user/search_trips/data/models/trip_filter_model.dart';

void main() {
  group('Phase 1: Schema Normalization & Network Config Tests', () {
    test(
      'ApiConfig contains new endpoints for reviews, notifications, routes',
      () {
        expect(ApiConfig.reviews, equals('/reviews'));
        expect(ApiConfig.notifications, equals('/notifications'));
        expect(
          ApiConfig.notificationRead(12),
          equals('/notifications/12/read'),
        );
        expect(
          ApiConfig.notificationReadAll,
          equals('/notifications/read-all'),
        );
        expect(ApiConfig.ticketsCancel, equals('/tickets/cancel'));
        expect(ApiConfig.routes, equals('/routes'));
        expect(ApiConfig.busCompanies, equals('/bus-companies'));
      },
    );

    test('TripModel.normalizeTime correctly formats ISO and HH:mm strings', () {
      // Vietnam UTC+7 timezone: 01:00 UTC = 08:00 ICT
      final isoUtc = '2026-10-10T01:00:00.000Z';
      expect(TripModel.normalizeTime(isoUtc), equals('08:00'));

      // Direct HH:mm
      expect(TripModel.normalizeTime('09:30'), equals('09:30'));
      expect(TripModel.normalizeTime('9:30'), equals('09:30'));
      expect(TripModel.normalizeTime('23:45:00'), equals('23:45'));
    });

    test('TimeSlotExt.matches matches both formatted time and ISO strings', () {
      // 08:00 is morning (06:00 - 12:00)
      expect(TimeSlot.morning.matches('08:00'), isTrue);
      expect(TimeSlot.earlyMorning.matches('08:00'), isFalse);

      // ISO UTC string (01:00 UTC -> 08:00 ICT)
      final isoUtc = '2026-10-10T01:00:00.000Z';
      expect(TimeSlot.morning.matches(isoUtc), isTrue);
      expect(TimeSlot.earlyMorning.matches(isoUtc), isFalse);
    });

    test(
      'TicketModel.fromJson seamlessly parses flat backend tickets payload',
      () {
        final backendJson = {
          'ticketId': 987,
          'ticketCode': 'VXG-987654',
          'origin': 'TP. Hồ Chí Minh',
          'destination': 'Đà Lạt',
          'busCompanyName': 'Phương Trang FUTA',
          'vehicleType': 'Limousine VIP',
          'departureTime': '2026-10-10T01:00:00.000Z',
          'arrivalTime': '2026-10-10T07:00:00.000Z',
          'seatNumber': 'B02',
          'seatPosition': 'Tầng 1',
          'price': 300000,
          'status': 'DA_BAN',
          'passengerName': 'Nguyễn Văn An',
          'passengerPhone': '0901234567',
          'cancellation': {
            'eligible': true,
            'cancelFeeRate': 0.1,
            'cancelFee': 30000,
            'refundAmount': 270000,
          },
        };

        final ticket = TicketModel.fromJson(backendJson);
        expect(ticket.id, equals('987'));
        expect(ticket.ticketCode, equals('VXG-987654'));
        expect(ticket.status, equals(TicketStatus.upcoming));
        expect(ticket.trip.operatorName, equals('Phương Trang FUTA'));
        expect(ticket.trip.fromCity, equals('TP. Hồ Chí Minh'));
        expect(ticket.trip.toCity, equals('Đà Lạt'));
        expect(ticket.trip.departureTime, equals('08:00'));
        expect(ticket.seats, equals(['B02']));
        expect(ticket.passenger.fullName, equals('Nguyễn Văn An'));
        expect(ticket.passenger.phone, equals('0901234567'));
        expect(ticket.finalAmount, equals(300000));
        expect(ticket.canCancel, isTrue);
        expect(ticket.cancelFeeRate, equals(0.1));
        expect(ticket.calculatedRefundAmount, equals(270000));
      },
    );

    test(
      'NotificationModel.fromJson handles backend integer IDs and Vietnamese fields',
      () {
        final backendNotifJson = {
          'id': 42, // Integer ID from Prisma
          'tieuDe': 'Đặt vé thành công',
          'noiDung': 'Mã vé VXG-123456 đã được xác nhận.',
          'trangThai': 'DA_GUI',
          'thoiGian': '2026-10-09T08:00:00.000Z',
          'daDoc': false,
        };

        final notif = NotificationModel.fromJson(backendNotifJson);
        expect(notif.id, equals('42'));
        expect(notif.title, equals('Đặt vé thành công'));
        expect(notif.message, equals('Mã vé VXG-123456 đã được xác nhận.'));
        expect(notif.category, equals(NotificationCategory.unknown));
        expect(notif.isRead, isFalse);
      },
    );
  });
}
