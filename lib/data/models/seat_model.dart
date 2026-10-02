import 'package:equatable/equatable.dart';

enum SeatStatus { available, booked, selected, held }

class SeatModel extends Equatable {
  final String id;
  final String name;
  final int floor; // 1: Tầng dưới, 2: Tầng trên
  final SeatStatus status;
  final int price;
  final int row;
  final int col;

  const SeatModel({
    required this.id,
    required this.name,
    required this.floor,
    required this.status,
    required this.price,
    required this.row,
    required this.col,
  });

  SeatModel copyWith({
    String? id,
    String? name,
    int? floor,
    SeatStatus? status,
    int? price,
    int? row,
    int? col,
  }) {
    return SeatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      price: price ?? this.price,
      row: row ?? this.row,
      col: col ?? this.col,
    );
  }

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    SeatStatus parseStatus(String? statusStr) {
      switch (statusStr?.toUpperCase()) {
        case 'BOOKED':
        case 'DA_DAT':
          return SeatStatus.booked;
        case 'HELD':
        case 'HOLD':
        case 'DANG_GIU':
          return SeatStatus.held;
        case 'SELECTED':
          return SeatStatus.selected;
        case 'AVAILABLE':
        case 'TRONG':
        default:
          return SeatStatus.available;
      }
    }

    final id = (json['tripSeatId'] ?? json['seatId'] ?? json['id'] ?? '')
        .toString();
    final name = (json['seatNumber'] ?? json['seatCode'] ?? json['name'] ?? '')
        .toString();
    final status = parseStatus(
      json['status'] as String? ?? json['trangThai'] as String?,
    );

    final positionStr = json['position'] as String? ?? '';
    final hasUpperInPosition =
        positionStr.contains('Tầng trên') ||
        positionStr.contains('tầng trên') ||
        positionStr.toUpperCase().contains('TANG TREN');
    final startsWithB = name.toUpperCase().startsWith('B');

    final floor =
        (json['floor'] as num?)?.toInt() ??
        (json['tang'] as num?)?.toInt() ??
        ((hasUpperInPosition || startsWithB) ? 2 : 1);

    final price =
        (json['price'] as num?)?.toInt() ?? (json['gia'] as num?)?.toInt() ?? 0;

    int row =
        (json['row'] as num?)?.toInt() ?? (json['hang'] as num?)?.toInt() ?? 0;
    int col =
        (json['col'] as num?)?.toInt() ?? (json['cot'] as num?)?.toInt() ?? 0;

    if (row == 0 || col == 0) {
      final seatNum = int.tryParse(name.replaceAll(RegExp(r'[^0-9]'), ''));
      if (seatNum != null && seatNum > 0) {
        if (row == 0) row = ((seatNum - 1) ~/ 3) + 1;
        if (col == 0) col = ((seatNum - 1) % 3) + 1;
      } else {
        if (row == 0) row = 1;
        if (col == 0) col = 1;
      }
    }

    return SeatModel(
      id: id,
      name: name,
      floor: floor,
      status: status,
      price: price,
      row: row,
      col: col,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seatId': numericSeatId,
    'name': name,
    'seatCode': name,
    'floor': floor,
    'status': status.name.toUpperCase(),
    'price': price,
    'row': row,
    'col': col,
  };

  /// Helper getters
  int? get numericSeatId => int.tryParse(id);
  bool get isAvailable => status == SeatStatus.available;
  bool get isBooked => status == SeatStatus.booked;
  bool get isHeld => status == SeatStatus.held;
  bool get isSelected => status == SeatStatus.selected;

  @override
  List<Object?> get props => [id, name, floor, status, price, row, col];
}

class SeatLayoutModel extends Equatable {
  final String vehicleType;
  final bool hasTwoFloors;
  final List<SeatModel> lowerFloor;
  final List<SeatModel> upperFloor;

  const SeatLayoutModel({
    required this.vehicleType,
    required this.hasTwoFloors,
    required this.lowerFloor,
    required this.upperFloor,
  });

  factory SeatLayoutModel.fromJson(Map<String, dynamic> json) {
    return SeatLayoutModel(
      vehicleType: json['vehicleType'] as String? ?? '',
      hasTwoFloors: json['hasTwoFloors'] as bool? ?? false,
      lowerFloor:
          (json['lowerFloor'] as List<dynamic>?)
              ?.map((item) => SeatModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      upperFloor:
          (json['upperFloor'] as List<dynamic>?)
              ?.map((item) => SeatModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
    vehicleType,
    hasTwoFloors,
    lowerFloor,
    upperFloor,
  ];
}
