import '../../core/utils/json_loader.dart';
import '../models/notification_model.dart';
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
  });
}

class MockBookingRepository implements BookingRepository {
  List<VoucherModel>? _cachedVouchers;
  List<TicketModel>? _cachedTickets;
  List<NotificationModel>? _cachedNotifications;

  @override
  Future<List<VoucherModel>> getVouchers() async {
    if (_cachedVouchers != null) return _cachedVouchers!;
    final List<Map<String, dynamic>> rawList =
        await JsonLoader.loadJsonList('assets/mock_data/vouchers.json');
    _cachedVouchers = rawList.map((item) => VoucherModel.fromJson(item)).toList();
    return _cachedVouchers!;
  }

  @override
  Future<List<TicketModel>> getMyTickets() async {
    if (_cachedTickets != null) return _cachedTickets!;
    final List<Map<String, dynamic>> rawList =
        await JsonLoader.loadJsonList('assets/mock_data/my_tickets.json');
    _cachedTickets = rawList.map((item) => TicketModel.fromJson(item)).toList();
    return _cachedTickets!;
  }

  @override
  Future<TicketModel?> getTicketById(String id) async {
    final tickets = await getMyTickets();
    try {
      return tickets.firstWhere(
        (t) => t.id == id || t.ticketCode == id,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    if (_cachedNotifications != null) return _cachedNotifications!;
    final List<Map<String, dynamic>> rawList =
        await JsonLoader.loadJsonList('assets/mock_data/notifications.json');
    _cachedNotifications = rawList.map((item) => NotificationModel.fromJson(item)).toList();
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
}
