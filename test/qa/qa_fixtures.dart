// Independent QA fixtures. No real account or payment provider is contacted.
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';

const qaPassenger = PassengerInfo(
  fullName: 'QA Sandbox',
  phone: '0901234567',
  email: 'qa@example.invalid',
);

const qaSummary = TicketTripSummary(
  id: '101',
  operatorName: 'QA Operator',
  vehicleType: 'Sleeper',
  departureTime: '23:00',
  departureDate: '20/10/2030',
  arrivalTime: '06:00',
  arrivalDate: '21/10/2030',
  fromCity: 'TP.HCM',
  toCity: 'Đà Lạt',
  pickupPoint: 'QA Pickup',
  pickupAddress: 'QA address',
  dropoffPoint: 'QA Dropoff',
  dropoffAddress: 'QA address',
);

final qaTrip = TripModel(
  id: '101',
  operatorId: '1',
  operatorName: 'QA Operator',
  vehicleType: 'Sleeper',
  fromCityId: 'HCM',
  fromCityName: 'TP.HCM',
  toCityId: 'DL',
  toCityName: 'Đà Lạt',
  departureTime: '23:00',
  arrivalTime: '06:00',
  duration: '7h',
  pickupPoint: 'QA Pickup',
  pickupAddress: 'QA address',
  dropoffPoint: 'QA Dropoff',
  dropoffAddress: 'QA address',
  originalPrice: 300000,
  discountPrice: 250000,
  availableSeats: 1,
  totalSeats: 1,
  seatLayoutType: 'SLEEPER',
  rating: 4,
  reviewCount: 0,
);

TicketModel qaTicket({String id = '91', String code = 'TICKET-AUTH-91'}) =>
    TicketModel(
      id: id,
      ticketCode: code,
      bookingId: 888,
      bookingCode: 'BOOKING-888',
      status: TicketStatus.upcoming,
      bookingDate: '18/10/2026 14:00',
      trip: qaSummary,
      seats: const ['A01'],
      totalAmount: 250000,
      discountAmount: 0,
      finalAmount: 250000,
      paymentMethod: 'MOMO',
      passenger: qaPassenger,
    );

// Shapes derived from bookings.service.ts mapBooking and tickets.service.ts
// mapTicket in the local backend. These remain fixtures, not live evidence.
Map<String, dynamic> qaBookingJson({String status = 'DA_THANH_TOAN'}) => {
  'bookingId': 888,
  'bookingCode': 'BOOKING-888',
  'tripId': 101,
  'status': status,
  'paymentStatus': status,
  'totalAmount': 250000,
  'seatNumbers': ['A01'],
  'tickets': [
    {
      'ticketId': 91,
      'ticketCode': 'TICKET-AUTH-91',
      'seatNumber': 'A01',
      'price': 250000,
      'status': 'DA_THANH_TOAN',
      'pickup': 'QA Pickup',
    },
  ],
};

Map<String, dynamic> qaTicketJson() => {
  'ticketId': 91,
  'ticketCode': 'TICKET-AUTH-91',
  'bookingId': 888,
  'bookingCode': 'BOOKING-888',
  'origin': 'TP.HCM',
  'destination': 'Đà Lạt',
  'busCompanyName': 'QA Operator',
  'vehicleType': 'Sleeper',
  'departureTime': '2030-10-20T16:00:00Z',
  'arrivalTime': '2030-10-20T23:00:00Z',
  'seatNumber': 'A01',
  'price': 250000,
  'status': 'DA_THANH_TOAN',
  'bookingStatus': 'DA_THANH_TOAN',
  'paymentStatus': 'DA_THANH_TOAN',
  'paymentMethod': 'MOMO',
  'pickup': 'QA Pickup',
  'dropoff': 'Đà Lạt',
  'passengerName': 'QA Sandbox',
  'passengerPhone': '0901234567',
  'createdAt': '2026-10-18T07:00:00Z',
  'cancellation': {
    'eligible': true,
    'cancelFeeRate': 0.1,
    'cancelFee': 25000,
    'refundAmount': 225000,
  },
};
