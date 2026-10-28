import 'package:equatable/equatable.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/adapters/city_search_adapter.dart';

enum TripLeg { outbound, inbound }

/// Typed navigation payload. No passenger details or hold/payment capabilities
/// belong in route query parameters.
class RoundTripSelection {
  final RoundTripRequest request;
  final TripModel outbound;
  final TripModel inbound;
  RoundTripSelection({
    required this.request,
    required this.outbound,
    required this.inbound,
  }) {
    if (!request.acceptsPair(outbound, inbound)) {
      throw ArgumentError('Cặp chuyến khứ hồi không hợp lệ.');
    }
  }
}

/// Calendar dates are Vietnam business dates, not UTC instants.
class RoundTripRequest extends Equatable {
  final CityModel origin;
  final CityModel destination;
  final DateTime departureDate;
  final DateTime returnDate;
  final int ticketCount;

  RoundTripRequest({
    required this.origin,
    required this.destination,
    required DateTime departureDate,
    required DateTime returnDate,
    this.ticketCount = 1,
  }) : departureDate = _day(departureDate),
       returnDate = _day(returnDate) {
    if (origin.id.trim().isEmpty ||
        destination.id.trim().isEmpty ||
        origin.id == destination.id ||
        (_identity(origin.name).isNotEmpty &&
            _identity(origin.name) == _identity(destination.name)) ||
        _identity(origin.id) == _identity(destination.id) ||
        this.returnDate.isBefore(this.departureDate) ||
        ticketCount < 1 ||
        ticketCount > 5) {
      throw ArgumentError('Tuyến, ngày đi/về hoặc số vé không hợp lệ.');
    }
  }

  /// Accepts the existing Home query/extra without discarding the return date.
  factory RoundTripRequest.fromRoute({
    required Map<String, String> query,
    Map<String, dynamic> extra = const {},
  }) {
    CityModel city(String key) {
      final value = extra[key];
      if (value is CityModel) return value;
      final id = query['${key}Id'];
      if (id == null || id.trim().isEmpty) throw ArgumentError('Thiếu $key.');
      return CityModel(
        id: id,
        name: query['${key}Name'] ?? id,
        region: '',
        isPopular: false,
      );
    }

    DateTime date(String key) {
      if (extra[key] is DateTime) return extra[key] as DateTime;
      final value = query[key] ?? '';
      final parsed = DateTime.tryParse(value);
      if (parsed == null || formatDate(parsed) != value) {
        throw ArgumentError('Ngày $key không hợp lệ.');
      }
      return parsed;
    }

    return RoundTripRequest(
      origin: city('fromCity'),
      destination: city('toCity'),
      departureDate: date('date'),
      returnDate: date('returnDate'),
      ticketCount:
          extra['ticketCount'] as int? ??
          int.tryParse(query['ticketCount'] ?? '') ??
          1,
    );
  }

  DateTime dateFor(TripLeg leg) =>
      leg == TripLeg.outbound ? departureDate : returnDate;
  CityModel originFor(TripLeg leg) =>
      leg == TripLeg.outbound ? origin : destination;
  CityModel destinationFor(TripLeg leg) =>
      leg == TripLeg.outbound ? destination : origin;

  bool accepts(TripLeg leg, TripModel trip) {
    final id = trip.numericTripId;
    if (id == null || id <= 0 || trip.availableSeats < ticketCount) {
      return false;
    }
    bool matches(CityModel city, String id, String name) {
      final expected = [
        city.id,
        city.name,
      ].map(_identity).where((s) => s.isNotEmpty).toSet();
      return [id, name].map(_identity).any(expected.contains);
    }

    if (!matches(originFor(leg), trip.fromCityId, trip.fromCityName) ||
        !matches(destinationFor(leg), trip.toCityId, trip.toCityName)) {
      return false;
    }
    final raw = trip.rawDepartureTime;
    if (raw != null && raw.contains('T')) {
      final instant = DateTime.tryParse(raw);
      if (instant == null) return false;
      final business = instant.isUtc
          ? instant.add(const Duration(hours: 7))
          : instant;
      if (formatDate(business) != formatDate(dateFor(leg))) return false;
    }
    return true;
  }

  bool acceptsPair(TripModel outbound, TripModel inbound) {
    if (!accepts(TripLeg.outbound, outbound) ||
        !accepts(TripLeg.inbound, inbound) ||
        outbound.numericTripId == inbound.numericTripId) {
      return false;
    }
    final outDeparture = _clock(departureDate, outbound.departureTime);
    final inDeparture = _clock(returnDate, inbound.departureTime);
    if (outDeparture == null || inDeparture == null) return false;
    final rawArrival = outbound.rawArrivalTime;
    DateTime? arrival;
    if (rawArrival != null && rawArrival.contains('T')) {
      final parsed = DateTime.tryParse(rawArrival);
      if (parsed != null) {
        final business = parsed.isUtc
            ? parsed.add(const Duration(hours: 7))
            : parsed;
        arrival = DateTime(
          business.year,
          business.month,
          business.day,
          business.hour,
          business.minute,
        );
      }
    } else if (outbound.durationMinutes != null &&
        outbound.durationMinutes! > 0) {
      arrival = outDeparture.add(Duration(minutes: outbound.durationMinutes!));
    } else {
      arrival = _clock(departureDate, outbound.arrivalTime);
      if (arrival != null && !arrival.isAfter(outDeparture)) {
        arrival = arrival.add(const Duration(days: 1));
      }
    }
    // Without a verified schedule, do not permit overlapping legs.
    return arrival != null &&
        arrival.isAfter(outDeparture) &&
        inDeparture.isAfter(arrival);
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static String _identity(String value) =>
      CitySearchAdapter.resolveBackendSearchCity(value).toLowerCase();
  static String formatDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  static DateTime? _clock(DateTime day, String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  @override
  List<Object?> get props => [
    origin,
    destination,
    departureDate,
    returnDate,
    ticketCount,
  ];
}
