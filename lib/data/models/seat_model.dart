import 'package:equatable/equatable.dart';

enum SeatStatus { available, booked, selected, held, unavailable }

class SeatModel extends Equatable {
  final String id;
  final String name;
  final int floor; // 1: Tầng dưới, 2: Tầng trên
  final SeatStatus status;
  final int? price;
  final int row;
  final int col;
  final String position;
  final bool hasExplicitCoordinates;

  const SeatModel({
    required this.id,
    required this.name,
    required this.floor,
    required this.status,
    this.price,
    required this.row,
    required this.col,
    this.position = '',
    this.hasExplicitCoordinates = true,
  });

  SeatModel copyWith({
    String? id,
    String? name,
    int? floor,
    SeatStatus? status,
    int? price,
    int? row,
    int? col,
    String? position,
    bool? hasExplicitCoordinates,
  }) {
    return SeatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      price: price ?? this.price,
      row: row ?? this.row,
      col: col ?? this.col,
      position: position ?? this.position,
      hasExplicitCoordinates:
          hasExplicitCoordinates ?? this.hasExplicitCoordinates,
    );
  }

  factory SeatModel.fromJson(Map<String, dynamic> json, {int? tripPrice}) {
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
          return SeatStatus.available;
        default:
          return SeatStatus.unavailable;
      }
    }

    final seatMap = json['seat'] is Map<String, dynamic>
        ? json['seat'] as Map<String, dynamic>
        : null;

    final id =
        (json['tripSeatId'] ??
                json['seatId'] ??
                seatMap?['seatId'] ??
                json['id'] ??
                '')
            .toString();
    final name =
        (json['seatNumber'] ??
                seatMap?['code'] ??
                seatMap?['soGhe'] ??
                json['seatCode'] ??
                json['name'] ??
                '')
            .toString();
    final status = parseStatus(
      json['status'] as String? ??
          json['trangThai'] as String? ??
          seatMap?['status'] as String?,
    );

    final positionStr =
        json['position']?.toString() ??
        seatMap?['position']?.toString() ??
        seatMap?['viTri']?.toString() ??
        '';
    final hasUpperInPosition =
        positionStr.contains('Tầng trên') ||
        positionStr.contains('tầng trên') ||
        positionStr.toUpperCase().contains('TANG TREN');
    final startsWithB = name.toUpperCase().startsWith('B');

    final floor =
        (json['floor'] as num?)?.toInt() ??
        (json['tang'] as num?)?.toInt() ??
        ((hasUpperInPosition || startsWithB) ? 2 : 1);

    final rawPrice =
        (json['price'] as num?)?.toInt() ?? (json['gia'] as num?)?.toInt();
    final effectivePrice = (rawPrice != null && rawPrice > 0)
        ? rawPrice
        : (tripPrice != null && tripPrice > 0 ? tripPrice : null);

    int row =
        (json['row'] as num?)?.toInt() ?? (json['hang'] as num?)?.toInt() ?? 0;
    int col =
        (json['col'] as num?)?.toInt() ?? (json['cot'] as num?)?.toInt() ?? 0;
    final explicitCoordinates =
        json['hasExplicitCoordinates'] as bool? ?? (row > 0 && col > 0);

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
      price: effectivePrice,
      row: row,
      col: col,
      position: positionStr,
      hasExplicitCoordinates: explicitCoordinates,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seatId': numericSeatId,
    'tripSeatId': numericSeatId,
    'name': name,
    'seatNumber': name,
    'seatCode': name,
    'floor': floor,
    'status': status.name.toUpperCase(),
    if (price != null) 'price': price,
    'row': row,
    'col': col,
    'position': position,
    'hasExplicitCoordinates': hasExplicitCoordinates,
  };

  /// Helper getters
  int? get numericSeatId => int.tryParse(id);
  bool get isAvailable => status == SeatStatus.available;
  bool get isBooked => status == SeatStatus.booked;
  bool get isHeld => status == SeatStatus.held;
  bool get isSelected => status == SeatStatus.selected;

  @override
  List<Object?> get props => [
    id,
    name,
    floor,
    status,
    price,
    row,
    col,
    position,
    hasExplicitCoordinates,
  ];
}

class SeatLayoutModel extends Equatable {
  final String vehicleType;
  final bool hasTwoFloors;
  final List<SeatModel> lowerFloor;
  final List<SeatModel> upperFloor;
  final int? columnCount;
  final int? aisleAfterColumn;

  const SeatLayoutModel({
    required this.vehicleType,
    required this.hasTwoFloors,
    required this.lowerFloor,
    required this.upperFloor,
    this.columnCount,
    this.aisleAfterColumn,
  });

  factory SeatLayoutModel.fromJson(Map<String, dynamic> json) {
    return SeatLayoutModel(
      vehicleType: json['vehicleType'] as String? ?? '',
      hasTwoFloors: json['hasTwoFloors'] as bool? ?? false,
      columnCount: (json['columnCount'] as num?)?.toInt(),
      aisleAfterColumn: (json['aisleAfterColumn'] as num?)?.toInt(),
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
    columnCount,
    aisleAfterColumn,
  ];
}
