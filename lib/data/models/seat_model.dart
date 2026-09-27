import 'package:equatable/equatable.dart';

enum SeatStatus { available, booked, selected }

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
          return SeatStatus.booked;
        case 'SELECTED':
          return SeatStatus.selected;
        case 'AVAILABLE':
        default:
          return SeatStatus.available;
      }
    }

    return SeatModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      floor: json['floor'] as int? ?? 1,
      status: parseStatus(json['status'] as String?),
      price: json['price'] as int? ?? 0,
      row: json['row'] as int? ?? 1,
      col: json['col'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'floor': floor,
    'status': status.name.toUpperCase(),
    'price': price,
    'row': row,
    'col': col,
  };

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
      lowerFloor: (json['lowerFloor'] as List<dynamic>?)
              ?.map((item) => SeatModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      upperFloor: (json['upperFloor'] as List<dynamic>?)
              ?.map((item) => SeatModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [vehicleType, hasTwoFloors, lowerFloor, upperFloor];
}
