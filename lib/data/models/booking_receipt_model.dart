/// Read-only booking/payment evidence, not a tax invoice or boarding QR.
class ReceiptUnavailable implements Exception {
  final String message;
  const ReceiptUnavailable(this.message);
}

/// Transient navigation data; never serialize phone/capability codes into URLs.
class ReceiptLookupRequest {
  final String code;
  final String phone;
  final int sessionVersion;
  const ReceiptLookupRequest(this.code, this.phone, this.sessionVersion);
}

class ReceiptTicket {
  final String code;
  final String seat;
  final String status;
  final num price;
  const ReceiptTicket(this.code, this.seat, this.status, this.price);
}

class ReceiptCargo {
  final String name;
  final int quantity;
  const ReceiptCargo(this.name, this.quantity);
}

class BookingReceipt {
  final int bookingId;
  final String bookingCode;
  final String orderCode;
  final String company;
  final String route;
  final String vehicle;
  final String pickup;
  final String dropoff;
  final String passengerName;
  final String passengerPhone;
  final String passengerEmail;
  final String paymentMethod;
  final String promotionCode;
  final DateTime createdAt;
  final DateTime? departureAt;
  final num originalSubtotal;
  final num discount;
  final num ticketSubtotal;
  final num cargoFee;
  final num total;
  final List<ReceiptTicket> tickets;
  final List<ReceiptCargo> cargo;

  const BookingReceipt._({
    required this.bookingId,
    required this.bookingCode,
    required this.orderCode,
    required this.company,
    required this.route,
    required this.vehicle,
    required this.pickup,
    required this.dropoff,
    required this.passengerName,
    required this.passengerPhone,
    required this.passengerEmail,
    required this.paymentMethod,
    required this.promotionCode,
    required this.createdAt,
    required this.departureAt,
    required this.originalSubtotal,
    required this.discount,
    required this.ticketSubtotal,
    required this.cargoFee,
    required this.total,
    required this.tickets,
    required this.cargo,
  });

  static String text(dynamic value) => value is String ? value.trim() : '';
  static int positiveId(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) {
      throw const FormatException('Thiếu mã đơn hợp lệ.');
    }
    return parsed;
  }

  static num money(dynamic value) {
    final parsed = value is num ? value : num.tryParse(value.toString());
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      throw const FormatException('Số tiền từ máy chủ không hợp lệ.');
    }
    return parsed;
  }

  static Map<String, dynamic> object(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu không đầy đủ.');
    }
    return value;
  }

  factory BookingReceipt.fromJson(Map<String, dynamic> json) {
    final status = text(json['status']);
    final payment = text(json['paymentStatus']);
    if (['DA_HUY', 'HUY', 'HET_HAN', 'EXPIRED'].contains(status) ||
        ['DA_HUY', 'HUY', 'HET_HAN', 'EXPIRED'].contains(payment)) {
      throw const ReceiptUnavailable(
        'Đơn đã hủy hoặc hết hạn, không thể hiển thị chứng từ thanh toán.',
      );
    }
    if (!['DA_THANH_TOAN', 'HOAN_TAT'].contains(status) ||
        payment != 'DA_THANH_TOAN') {
      throw const ReceiptUnavailable(
        'Chưa xác minh đơn đã thanh toán. Vui lòng kiểm tra trạng thái và thử lại.',
      );
    }
    final bookingCode = text(json['bookingCode']);
    final orderCode = text(json['orderCode']);
    final createdAt = DateTime.tryParse(text(json['createdAt']));
    if (bookingCode.isEmpty ||
        orderCode.isEmpty ||
        createdAt == null ||
        json['tickets'] is! List ||
        (json['tickets'] as List).isEmpty ||
        json['cargoItems'] is! List) {
      throw const FormatException('Thông tin chứng từ từ máy chủ chưa đầy đủ.');
    }
    final passenger = object(json['passenger']);
    final tickets = (json['tickets'] as List).map((item) {
      final ticket = object(item);
      final code = text(ticket['ticketCode']);
      if (code.isEmpty) throw const FormatException('Vé thiếu mã.');
      return ReceiptTicket(
        code,
        text(ticket['seatNumber']),
        text(ticket['status']),
        money(ticket['price']),
      );
    }).toList();
    if (tickets.map((ticket) => ticket.code).toSet().length != tickets.length) {
      throw const FormatException('Danh sách vé bị trùng.');
    }
    final cargo = (json['cargoItems'] as List).map((item) {
      final parcel = object(item);
      return ReceiptCargo(text(parcel['name']), positiveId(parcel['quantity']));
    }).toList();
    return BookingReceipt._(
      bookingId: positiveId(json['bookingId']),
      bookingCode: bookingCode,
      orderCode: orderCode,
      company: text(json['busCompanyName']),
      route: text(json['route']),
      vehicle: text(json['vehicleType']),
      pickup: text(json['pickup']),
      dropoff: text(json['dropoff']),
      passengerName: text(passenger['fullName']),
      passengerPhone: text(passenger['phoneNumber']),
      passengerEmail: text(passenger['email']),
      paymentMethod: text(json['paymentMethod']),
      promotionCode: text(json['promotionCode']),
      createdAt: createdAt,
      departureAt: DateTime.tryParse(text(json['departureTime'])),
      originalSubtotal: money(json['originalTicketSubtotal']),
      discount: money(json['discountAmount']),
      ticketSubtotal: money(json['ticketSubtotal']),
      cargoFee: money(json['cargoFee']),
      total: money(json['totalAmount']),
      tickets: List.unmodifiable(tickets),
      cargo: List.unmodifiable(cargo),
    );
  }
}
