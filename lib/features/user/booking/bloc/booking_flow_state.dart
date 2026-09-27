import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:vexgo_app/data/models/seat_model.dart';
import 'package:vexgo_app/data/models/stop_point_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';

enum BookingFlowStatus { initial, loading, loaded, submitting, success, failure }

enum BookingStep {
  seatSelection,   // 0: Chọn chỗ ngồi
  pickupPoint,     // 1: Chọn điểm đón
  dropoffPoint,    // 2: Chọn điểm trả
  passengerInfo,   // 3: Nhập thông tin hành khách
  tripSummary,     // 4: Thông tin chuyến đi & Voucher
  payment,         // 5: Thanh toán
}

extension BookingStepExtension on BookingStep {
  int get stepNumber => index + 1;

  String get title {
    switch (this) {
      case BookingStep.seatSelection:
        return 'Chọn chỗ ngồi';
      case BookingStep.pickupPoint:
        return 'Chọn điểm đón';
      case BookingStep.dropoffPoint:
        return 'Chọn điểm trả';
      case BookingStep.passengerInfo:
        return 'Thông tin hành khách';
      case BookingStep.tripSummary:
        return 'Thông tin chuyến đi';
      case BookingStep.payment:
        return 'Thanh toán vé';
    }
  }

  String get shortTitle {
    switch (this) {
      case BookingStep.seatSelection:
        return 'Chỗ ngồi';
      case BookingStep.pickupPoint:
        return 'Điểm đón';
      case BookingStep.dropoffPoint:
        return 'Điểm trả';
      case BookingStep.passengerInfo:
        return 'Thông tin';
      case BookingStep.tripSummary:
        return 'Chi tiết';
      case BookingStep.payment:
        return 'Thanh toán';
    }
  }
}

class BookingFlowState extends Equatable {
  final BookingFlowStatus status;
  final BookingStep step;
  final TripModel? trip;
  final DateTime? date;
  final int targetTicketCount;
  final SeatLayoutModel? seatLayout;
  final int selectedFloor; // 1 hoặc 2
  final List<SeatModel> selectedSeats;
  final List<StopPointModel> availablePickupPoints;
  final StopPointModel? selectedPickupPoint;
  final List<StopPointModel> availableDropoffPoints;
  final StopPointModel? selectedDropoffPoint;
  final String passengerName;
  final String passengerPhone;
  final String passengerEmail;
  final String passengerNote;
  final bool savePassengerInfo;
  final VoucherModel? appliedVoucher;
  final List<VoucherModel> availableVouchers;
  final String selectedPaymentMethod;
  final int countdownSeconds;
  final TicketModel? createdTicket;
  final String? errorMessage;

  const BookingFlowState({
    this.status = BookingFlowStatus.initial,
    this.step = BookingStep.seatSelection,
    this.trip,
    this.date,
    this.targetTicketCount = 1,
    this.seatLayout,
    this.selectedFloor = 1,
    this.selectedSeats = const [],
    this.availablePickupPoints = const [],
    this.selectedPickupPoint,
    this.availableDropoffPoints = const [],
    this.selectedDropoffPoint,
    this.passengerName = 'Nguyễn Văn An',
    this.passengerPhone = '0987654321',
    this.passengerEmail = 'nguyenvanan@gmail.com',
    this.passengerNote = '',
    this.savePassengerInfo = true,
    this.appliedVoucher,
    this.availableVouchers = const [],
    this.selectedPaymentMethod = 'momo',
    this.countdownSeconds = 600,
    this.createdTicket,
    this.errorMessage,
  });

  int get seatsTotalAmount =>
      selectedSeats.fold(0, (sum, seat) => sum + seat.price);

  int get discountAmount {
    if (appliedVoucher == null) return 0;
    final total = seatsTotalAmount;
    if (total < appliedVoucher!.minOrderAmount) return 0;

    if (appliedVoucher!.discountPercent > 0) {
      final calc = (total * appliedVoucher!.discountPercent / 100).round();
      if (appliedVoucher!.maxDiscount != null && appliedVoucher!.maxDiscount! > 0) {
        return min(calc, appliedVoucher!.maxDiscount!);
      }
      return calc;
    }
    return appliedVoucher!.discountAmount;
  }

  int get finalAmount => max(0, seatsTotalAmount - discountAmount);

  bool get isSeatsValid => selectedSeats.isNotEmpty;
  bool get isPickupValid => selectedPickupPoint != null;
  bool get isDropoffValid => selectedDropoffPoint != null;
  bool get isPassengerValid =>
      passengerName.trim().length >= 2 &&
      RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$').hasMatch(passengerPhone.trim()) &&
      passengerEmail.trim().contains('@');

  bool get canProceed {
    switch (step) {
      case BookingStep.seatSelection:
        return isSeatsValid;
      case BookingStep.pickupPoint:
        return isPickupValid;
      case BookingStep.dropoffPoint:
        return isDropoffValid;
      case BookingStep.passengerInfo:
        return isPassengerValid;
      case BookingStep.tripSummary:
        return true;
      case BookingStep.payment:
        return selectedPaymentMethod.isNotEmpty;
    }
  }

  String get countdownFormatted {
    final minutes = (countdownSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (countdownSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  BookingFlowState copyWith({
    BookingFlowStatus? status,
    BookingStep? step,
    TripModel? trip,
    DateTime? date,
    int? targetTicketCount,
    SeatLayoutModel? seatLayout,
    int? selectedFloor,
    List<SeatModel>? selectedSeats,
    List<StopPointModel>? availablePickupPoints,
    StopPointModel? selectedPickupPoint,
    List<StopPointModel>? availableDropoffPoints,
    StopPointModel? selectedDropoffPoint,
    String? passengerName,
    String? passengerPhone,
    String? passengerEmail,
    String? passengerNote,
    bool? savePassengerInfo,
    VoucherModel? appliedVoucher,
    bool clearVoucher = false,
    List<VoucherModel>? availableVouchers,
    String? selectedPaymentMethod,
    int? countdownSeconds,
    TicketModel? createdTicket,
    String? errorMessage,
  }) {
    return BookingFlowState(
      status: status ?? this.status,
      step: step ?? this.step,
      trip: trip ?? this.trip,
      date: date ?? this.date,
      targetTicketCount: targetTicketCount ?? this.targetTicketCount,
      seatLayout: seatLayout ?? this.seatLayout,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      availablePickupPoints: availablePickupPoints ?? this.availablePickupPoints,
      selectedPickupPoint: selectedPickupPoint ?? this.selectedPickupPoint,
      availableDropoffPoints: availableDropoffPoints ?? this.availableDropoffPoints,
      selectedDropoffPoint: selectedDropoffPoint ?? this.selectedDropoffPoint,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      passengerNote: passengerNote ?? this.passengerNote,
      savePassengerInfo: savePassengerInfo ?? this.savePassengerInfo,
      appliedVoucher: clearVoucher ? null : (appliedVoucher ?? this.appliedVoucher),
      availableVouchers: availableVouchers ?? this.availableVouchers,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      createdTicket: createdTicket ?? this.createdTicket,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        step,
        trip,
        date,
        seatLayout,
        selectedFloor,
        selectedSeats,
        selectedPickupPoint,
        selectedDropoffPoint,
        passengerName,
        passengerPhone,
        passengerEmail,
        passengerNote,
        savePassengerInfo,
        appliedVoucher,
        selectedPaymentMethod,
        countdownSeconds,
        createdTicket,
        errorMessage,
      ];
}
