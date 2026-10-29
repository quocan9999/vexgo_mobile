import 'dart:math' as math;
import 'seat_model.dart';

/// Prefer the per-vehicle Customer API layout. The legacy row/column path is
/// retained only for payloads and offline fixtures without the new contract.
SeatLayoutModel resolveSeatLayout({
  required String vehicleType,
  required List<SeatModel> seats,
}) {
  if (seats.any((seat) => seat.usesApiLayout)) {
    return _resolveApiLayout(vehicleType, seats);
  }
  if (seats.isNotEmpty && seats.every((s) => s.hasExplicitCoordinates)) {
    return _layout(vehicleType, seats);
  }

  final type = vehicleType.toUpperCase();
  final sleeper =
      type.contains('GIƯỜNG') ||
      type.contains('GIUONG') ||
      type.contains('SLEEPER') ||
      type.contains('CABIN') ||
      seats.any((s) => s.position.toLowerCase().contains('tầng'));
  final columns = sleeper ? 3 : 4;
  final mapped = <SeatModel>[];
  if (sleeper) {
    for (final floor in [1, 2]) {
      final floorSeats = seats.where((s) => s.floor == floor).toList()
        ..sort(_compareSeats);
      for (var i = 0; i < floorSeats.length; i++) {
        mapped.add(floorSeats[i].copyWith(row: i ~/ 3 + 1, col: i % 3 + 1));
      }
    }
  } else {
    final left = <SeatModel>[];
    final right = <SeatModel>[];
    final unassigned = <SeatModel>[];
    for (final seat in seats) {
      final position = seat.position.toLowerCase();
      if (position.contains('trái') || position.contains('trai')) {
        left.add(seat);
      } else if (position.contains('phải') || position.contains('phai')) {
        right.add(seat);
      } else {
        unassigned.add(seat);
      }
    }
    unassigned.sort(_compareSeats);
    if (left.isEmpty && right.isEmpty) {
      for (var i = 0; i < unassigned.length; i++) {
        (i % 4 < 2 ? left : right).add(unassigned[i]);
      }
    } else {
      for (final seat in unassigned) {
        (left.length <= right.length ? left : right).add(seat);
      }
    }
    for (final group in [left, right]) {
      group.sort(_compareSeats);
      for (var i = 0; i < group.length; i++) {
        mapped.add(
          group[i].copyWith(
            floor: 1,
            row: i ~/ 2 + 1,
            col: i % 2 + (identical(group, left) ? 1 : 3),
          ),
        );
      }
    }
  }

  // Preserve individual server coordinates in a mixed payload. Move inferred
  // cells out of their way so no real trip seat disappears behind another.
  final explicit = seats.where((s) => s.hasExplicitCoordinates).toList();
  final occupied = explicit.map((s) => (s.floor, s.row, s.col)).toSet();
  final result = <SeatModel>[...explicit];
  final width = explicit.fold(columns, (n, s) => math.max(n, s.col));
  for (final seat in mapped.where((s) => !s.hasExplicitCoordinates)) {
    var row = seat.row;
    var col = seat.col;
    while (occupied.contains((seat.floor, row, col))) {
      col++;
      if (col > width) {
        col = 1;
        row++;
      }
    }
    occupied.add((seat.floor, row, col));
    result.add(seat.copyWith(row: row, col: col));
  }
  return _layout(
    vehicleType,
    result,
    columnCount: width,
    aisleAfterColumn: sleeper ? null : 2,
  );
}

SeatLayoutModel _resolveApiLayout(String vehicleType, List<SeatModel> seats) {
  final result = <SeatModel>[];
  for (final floor
      in seats.map((seat) => seat.floor).toSet().toList()..sort()) {
    final floorSeats = seats.where((seat) => seat.floor == floor).toList()
      ..sort(_compareSeats);
    final occupied = <(double, double)>[
      for (final seat in floorSeats)
        if (seat.hasSpatialCoordinates) (seat.x!, seat.y!),
    ];
    for (final seat in floorSeats) {
      if (seat.hasSpatialCoordinates) {
        result.add(seat);
        continue;
      }
      // Same null-coordinate policy as Customer Web. Never change the API's
      // seat ID, floor, status or real coordinates, and never persist fallback.
      var row = 1;
      (double, double)? available;
      while (available == null) {
        final y = row * 1000.0;
        for (final x in [160.0, 360.0, 640.0, 840.0]) {
          if (!occupied.any(
            (point) => (point.$1 - x).abs() < 180 && (point.$2 - y).abs() < 875,
          )) {
            available = (x, y);
            break;
          }
        }
        row++;
      }
      occupied.add(available);
      result.add(seat.copyWith(x: available.$1, y: available.$2));
    }
  }
  return _layout(vehicleType, result);
}

int _compareSeats(SeatModel a, SeatModel b) {
  final pattern = RegExp(r'^(.*?)(\d+)$');
  final first = pattern.firstMatch(a.name);
  final second = pattern.firstMatch(b.name);
  if (first != null &&
      second != null &&
      first.group(1)!.toUpperCase() == second.group(1)!.toUpperCase()) {
    final number = int.parse(
      first.group(2)!,
    ).compareTo(int.parse(second.group(2)!));
    if (number != 0) return number;
  }
  final name = a.name.toUpperCase().compareTo(b.name.toUpperCase());
  return name != 0 ? name : a.id.compareTo(b.id);
}

SeatLayoutModel _layout(
  String vehicleType,
  List<SeatModel> seats, {
  int? columnCount,
  int? aisleAfterColumn,
}) => SeatLayoutModel(
  vehicleType: vehicleType,
  hasTwoFloors: seats.any((s) => s.floor == 2),
  lowerFloor: seats.where((s) => s.floor == 1).toList(),
  upperFloor: seats.where((s) => s.floor == 2).toList(),
  columnCount: columnCount,
  aisleAfterColumn: aisleAfterColumn,
);
