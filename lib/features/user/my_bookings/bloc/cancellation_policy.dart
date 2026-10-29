import 'package:vexgo_app/data/models/ticket_model.dart';

String cancellationReasonText(String? reason) {
  const labels = {
    'ALREADY_CANCELLED': 'Vé đã được hủy trước đó.',
    'DEPARTURE_TIME_UNAVAILABLE':
        'Chưa xác định được giờ khởi hành để xét điều kiện hủy.',
    'ALREADY_DEPARTED': 'Chuyến xe đã khởi hành, không thể hủy trực tuyến.',
    'LESS_THAN_4_HOURS': 'Đã qua thời hạn hủy trực tuyến của chuyến xe.',
    'LESS_THAN_12_HOURS': 'Đã qua thời hạn hủy trực tuyến của chuyến xe.',
    'ACTIVE_SHIPMENT':
        'Đơn có hàng gửi kèm còn hiệu lực. Vui lòng liên hệ nhà xe.',
  };
  final value = reason?.trim() ?? '';
  return labels[value] ??
      (value.isNotEmpty && !RegExp(r'^[A-Z0-9_]+$').hasMatch(value)
          ? value
          : 'Vé hiện không đủ điều kiện hủy trực tuyến. Vui lòng liên hệ nhà xe.');
}

bool hasUsableCancellationQuote(TicketModel ticket) {
  final quote = ticket.cancellation;
  return ticket.canCancel &&
      quote != null &&
      quote.cancelFeeRate.isFinite &&
      quote.cancelFeeRate >= 0 &&
      quote.cancelFeeRate <= 1 &&
      quote.cancelFee >= 0 &&
      quote.refundAmount >= 0 &&
      quote.cancelFee + quote.refundAmount == ticket.finalAmount;
}

bool sameCancellationQuote(TicketModel a, TicketModel b) =>
    a.id == b.id &&
    a.ticketCode == b.ticketCode &&
    a.finalAmount == b.finalAmount &&
    a.passenger.phone == b.passenger.phone &&
    a.cancellation != null &&
    b.cancellation != null &&
    a.cancellation!.eligible == b.cancellation!.eligible &&
    a.cancellation!.cancelFeeRate == b.cancellation!.cancelFeeRate &&
    a.cancellation!.cancelFee == b.cancellation!.cancelFee &&
    a.cancellation!.refundAmount == b.cancellation!.refundAmount;

bool confirmsCancellation(Map<String, dynamic> payload, TicketModel ticket) {
  final quote = ticket.cancellation;
  if (payload['ticketId']?.toString() != ticket.id ||
      payload['ticketCode'] != ticket.ticketCode ||
      payload['status'] != 'HUY' ||
      quote == null) {
    return false;
  }
  for (final pair in [
    ('cancelFee', quote.cancelFee),
    ('refundAmount', quote.refundAmount),
    ('cancelFeeRate', quote.cancelFeeRate),
  ]) {
    final value = payload[pair.$1];
    if (value != null &&
        (value is! num || !value.isFinite || value != pair.$2)) {
      return false;
    }
  }
  final codes = payload['cancelledTicketCodes'];
  return codes == null ||
      (codes is List && codes.length == 1 && codes.single == ticket.ticketCode);
}
