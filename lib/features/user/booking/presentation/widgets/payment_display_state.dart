import '../../bloc/booking_flow_state.dart';

/// Presentation gates only; payment verification remains in BookingFlowBloc.
extension PaymentDisplayState on BookingFlowState {
  bool get hasCurrentPaymentOrder =>
      pendingBookingId != null &&
      checkoutBooking?.bookingId == pendingBookingId &&
      !bookingOutcomeUnknown;

  // A single booking/payment status must never override the BLoC's decision.
  // This also supports confirmed gateway payments while tickets are hydrated.
  bool get hasConfirmedPayment => hasCurrentPaymentOrder && paymentConfirmed;

  bool paymentDeadlineExpired(DateTime now) {
    final deadline = checkoutBooking?.expiresAt;
    return hasCurrentPaymentOrder &&
        !hasConfirmedPayment &&
        deadline != null &&
        !deadline.isAfter(now);
  }

  bool canDisplayBankTransfer(DateTime now) {
    final booking = checkoutBooking;
    return hasCurrentPaymentOrder &&
        !hasConfirmedPayment &&
        status == BookingFlowStatus.paymentPending &&
        selectedPaymentMethod == 'vietqr' &&
        booking != null &&
        booking.isPending &&
        booking.paymentStatus == 'CHO_THANH_TOAN' &&
        booking.totalAmount > 0 &&
        pendingPaymentAmount == booking.totalAmount &&
        (booking.orderCode?.trim().isNotEmpty ?? false) &&
        booking.expiresAt != null &&
        booking.expiresAt!.isAfter(now);
  }
}
