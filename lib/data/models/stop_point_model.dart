import 'package:equatable/equatable.dart';

class StopPointModel extends Equatable {
  final String id;
  final int? tripPointId;
  final num surcharge;
  final String name;
  final String time;
  final String address;
  final String type; // 'station', 'office', 'transfer', 'point'
  final bool isDefault;

  const StopPointModel({
    required this.id,
    this.tripPointId,
    this.surcharge = 0,
    required this.name,
    required this.time,
    required this.address,
    this.type = 'point',
    this.isDefault = false,
  });

  factory StopPointModel.fromJson(Map<String, dynamic> json) {
    return StopPointModel(
      id: json['id']?.toString() ?? '',
      tripPointId: (json['diemDonTraChuyenXeId'] as num?)?.toInt(),
      surcharge: json['phuPhi'] as num? ?? 0,
      name: json['name'] as String? ?? '',
      time: json['time'] as String? ?? '',
      address: json['address'] as String? ?? '',
      type: json['type'] as String? ?? 'point',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (tripPointId != null) 'diemDonTraChuyenXeId': tripPointId,
    'phuPhi': surcharge,
    'name': name,
    'time': time,
    'address': address,
    'type': type,
    'isDefault': isDefault,
  };

  String get typeLabel {
    switch (type) {
      case 'station':
        return 'Bến xe';
      case 'office':
        return 'Văn phòng';
      case 'transfer':
        return 'Trung chuyển';
      default:
        return 'Điểm đón/trả';
    }
  }

  @override
  List<Object?> get props => [
    id,
    tripPointId,
    surcharge,
    name,
    time,
    address,
    type,
    isDefault,
  ];
}
