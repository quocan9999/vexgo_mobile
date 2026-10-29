import 'dart:math' as math;
import 'package:equatable/equatable.dart';

int cargoInteger(Object? value, {int minimum = 0}) {
  if (value is! num ||
      !value.isFinite ||
      value != value.round() ||
      value < minimum ||
      value > 9007199254740991) {
    throw const FormatException('Invalid cargo integer');
  }
  return value.toInt();
}

String cargoText(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Invalid cargo text');
  }
  return value.trim();
}

// Match Prisma.Decimal ROUND_HALF_UP at one decimal place. Double products can
// round 40.05 down to 40.0 and accidentally admit an overweight package.
double _volumetricWeight(double length, double width, double height) {
  var numerator = BigInt.one;
  var denominator = BigInt.one;
  for (final value in [length, width, height]) {
    if (!value.isFinite || value <= 0) return double.infinity;
    final parts = value.toString().toLowerCase().split('e');
    final mantissa = parts.first;
    final exponent = parts.length == 2 ? int.parse(parts.last) : 0;
    final decimal = mantissa.indexOf('.');
    final scale = (decimal < 0 ? 0 : mantissa.length - decimal - 1) - exponent;
    numerator *= BigInt.parse(mantissa.replaceAll('.', ''));
    if (scale >= 0) {
      denominator *= BigInt.from(10).pow(scale);
    } else {
      numerator *= BigInt.from(10).pow(-scale);
    }
  }
  numerator *= BigInt.from(10);
  denominator *= BigInt.from(5000);
  final rounded =
      (numerator * BigInt.two + denominator) ~/ (denominator * BigInt.two);
  return rounded.toDouble() / 10;
}

enum CargoGroup {
  motorcycle('XE_MAY', 'motorcycles'),
  bulky('HANG_CONG_KENH', 'bulkyGoods'),
  parcel('HANG_NHE', 'parcels');

  final String code;
  final String jsonKey;
  const CargoGroup(this.code, this.jsonKey);
  static CargoGroup parse(Object? value) => CargoGroup.values.firstWhere(
    (g) => g.code == value,
    orElse: () => throw const FormatException('Unknown cargo group'),
  );
}

class CargoCategory extends Equatable {
  final int id;
  final String name;
  final CargoGroup group;
  const CargoCategory({
    required this.id,
    required this.name,
    required this.group,
  });
  factory CargoCategory.fromJson(Map<String, dynamic> json) => CargoCategory(
    id: cargoInteger(json['categoryId'], minimum: 1),
    name: cargoText(json['name']),
    group: CargoGroup.parse(json['capacityGroup']),
  );
  @override
  List<Object?> get props => [id, name, group];
}

class CargoSlots extends Equatable {
  final int total;
  final int used;
  final int remaining;
  const CargoSlots({
    required this.total,
    required this.used,
    required this.remaining,
  });
  factory CargoSlots.fromJson(Map<String, dynamic> json) {
    final total = cargoInteger(json['total']);
    final used = cargoInteger(json['used']);
    final remaining = cargoInteger(json['remaining']);
    // Capacity can be lowered below existing usage; Backend clamps at zero.
    if (remaining != math.max(0, total - used)) {
      throw const FormatException('Inconsistent cargo capacity');
    }
    return CargoSlots(total: total, used: used, remaining: remaining);
  }
  @override
  List<Object?> get props => [total, used, remaining];
}

class CargoCapacity extends Equatable {
  final bool acceptsShipments;
  final Map<CargoGroup, CargoSlots> slots;
  CargoCapacity({
    required this.acceptsShipments,
    required Map<CargoGroup, CargoSlots> slots,
  }) : slots = Map.unmodifiable(slots);
  factory CargoCapacity.fromJson(Map<String, dynamic> json) {
    if (json['acceptsShipments'] is! bool || json['capacities'] is! Map) {
      throw const FormatException('Invalid cargo capability');
    }
    final capacities = json['capacities'] as Map;
    return CargoCapacity(
      acceptsShipments: json['acceptsShipments'] as bool,
      slots: {
        for (final g in CargoGroup.values)
          g: CargoSlots.fromJson(
            Map<String, dynamic>.from(capacities[g.jsonKey] as Map),
          ),
      },
    );
  }
  @override
  List<Object?> get props => [acceptsShipments, slots];
}

class CargoPoint extends Equatable {
  final int id;
  final String name;
  final String address;
  const CargoPoint({
    required this.id,
    required this.name,
    required this.address,
  });
  factory CargoPoint.fromJson(Map<String, dynamic> json) => CargoPoint(
    id: cargoInteger(json['id'], minimum: 1),
    name: cargoText(json['name']),
    address: json['address'] is String
        ? json['address'] as String
        : throw const FormatException('Invalid cargo address'),
  );
  @override
  List<Object?> get props => [id, name, address];
}

class CargoRoutePoints extends Equatable {
  final int tripId;
  final List<CargoPoint> senders;
  final List<CargoPoint> receivers;
  CargoRoutePoints({
    required this.tripId,
    required List<CargoPoint> senders,
    required List<CargoPoint> receivers,
  }) : senders = List.unmodifiable(senders),
       receivers = List.unmodifiable(receivers);
  factory CargoRoutePoints.fromJson(Map<String, dynamic> json) {
    List<CargoPoint> points(String key) {
      if (json[key] is! List) {
        throw const FormatException('Missing cargo route points');
      }
      final result = (json[key] as List)
          .map((v) => CargoPoint.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
      if (result.map((v) => v.id).toSet().length != result.length) {
        throw const FormatException('Duplicate cargo points');
      }
      return result;
    }

    return CargoRoutePoints(
      tripId: cargoInteger(json['tripId'], minimum: 1),
      senders: points('senderPoints'),
      receivers: points('receiverPoints'),
    );
  }
  @override
  List<Object?> get props => [tripId, senders, receivers];
}

enum CargoKind { parcel, bulky, motorcycle, bicycle }

enum CargoService { normal, fragile, valuable }

class CargoItemDraft extends Equatable {
  final String name;
  final CargoKind kind;
  final int categoryId;
  final int quantity;
  final double weight;
  final double? length;
  final double? width;
  final double? height;
  final CargoService service;
  final String note;
  final String vehicleModel;
  final String licensePlate;
  const CargoItemDraft({
    required this.name,
    required this.kind,
    required this.categoryId,
    this.quantity = 1,
    this.weight = 0,
    this.length,
    this.width,
    this.height,
    this.service = CargoService.normal,
    this.note = '',
    this.vehicleModel = '',
    this.licensePlate = '',
  });
  bool get isVehicle =>
      kind == CargoKind.motorcycle || kind == CargoKind.bicycle;
  double get payloadWeight => kind == CargoKind.motorcycle
      ? 100
      : kind == CargoKind.bicycle
      ? 15
      : weight;
  double get effectiveWeight {
    if (isVehicle || length == null || width == null || height == null) {
      return payloadWeight;
    }
    return math.max(weight, _volumetricWeight(length!, width!, height!));
  }

  CargoGroup get group => kind == CargoKind.motorcycle
      ? CargoGroup.motorcycle
      : kind == CargoKind.bicycle ||
            kind == CargoKind.bulky ||
            effectiveWeight >= 20
      ? CargoGroup.bulky
      : CargoGroup.parcel;
  String? get validationError {
    if (name.trim().isEmpty ||
        categoryId <= 0 ||
        quantity < 1 ||
        quantity > 9007199254740991) {
      return 'Nhập tên, loại hàng và số lượng hợp lệ.';
    }
    final dimensions = [length, width, height];
    if (dimensions.any((v) => v != null) &&
        !dimensions.every((v) => v != null && v.isFinite && v > 0)) {
      return 'Nhập đủ dài, rộng, cao; mỗi chiều phải lớn hơn 0.';
    }
    if (!payloadWeight.isFinite ||
        payloadWeight < 0 ||
        !effectiveWeight.isFinite ||
        effectiveWeight <= 0) {
      return 'Khối lượng hàng phải là số hợp lệ lớn hơn 0.';
    }
    if (!isVehicle &&
        (effectiveWeight > 40 ||
            (length ?? 0) > 150 ||
            (width ?? 0) > 80 ||
            (height ?? 0) > 80)) {
      return 'Mỗi kiện tối đa 40kg hiệu dụng, kích thước tối đa 150 × 80 × 80cm.';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    if (validationError != null) throw ArgumentError(validationError);
    return {
      'name': name.trim(),
      'type': switch (kind) {
        CargoKind.parcel => 'Hàng hóa',
        CargoKind.bulky => 'Hàng cồng kềnh',
        CargoKind.motorcycle => 'Xe máy',
        CargoKind.bicycle => 'Xe đạp',
      },
      'loaiHangHoaId': categoryId,
      'quantity': quantity,
      'weight': payloadWeight,
      if (length != null) 'length': length,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'category': service.name,
      if (note.trim().isNotEmpty) 'note': note.trim(),
      if (kind == CargoKind.motorcycle && vehicleModel.trim().isNotEmpty)
        'motorbikeModel': vehicleModel.trim(),
      if (kind == CargoKind.bicycle && vehicleModel.trim().isNotEmpty)
        'bicycleType': vehicleModel.trim(),
      if (licensePlate.trim().isNotEmpty) 'licensePlate': licensePlate.trim(),
    };
  }

  @override
  List<Object?> get props => [
    name,
    kind,
    categoryId,
    quantity,
    weight,
    length,
    width,
    height,
    service,
    note,
    vehicleModel,
    licensePlate,
  ];
}

class BookingCargoDraft extends Equatable {
  final List<CargoItemDraft> items;
  final int? senderPointId;
  final int? receiverPointId;
  BookingCargoDraft({
    required List<CargoItemDraft> items,
    this.senderPointId,
    this.receiverPointId,
  }) : items = List.unmodifiable(items);
  Map<String, dynamic> toJson() {
    if (items.isEmpty ||
        (senderPointId ?? 0) <= 0 ||
        (receiverPointId ?? 0) <= 0 ||
        senderPointId == receiverPointId) {
      throw ArgumentError(
        'Cargo items and distinct route point IDs are required.',
      );
    }
    return {
      'cargoItems': items.map((v) => v.toJson()).toList(),
      'senderPointId': senderPointId,
      'receiverPointId': receiverPointId,
    };
  }

  @override
  List<Object?> get props => [items, senderPointId, receiverPointId];
}

class CargoOptions extends Equatable {
  final int tripId;
  final List<CargoCategory> categories;
  final CargoCapacity capacity;
  final CargoRoutePoints? points;
  CargoOptions({
    required this.tripId,
    required List<CargoCategory> categories,
    required this.capacity,
    this.points,
  }) : categories = List.unmodifiable(categories);
  String? validate(BookingCargoDraft draft) {
    if (!capacity.acceptsShipments) return 'Chuyến xe không nhận gửi hàng.';
    if (points == null || points!.tripId != tripId) {
      return 'Chưa xác minh điểm gửi/nhận hàng của chuyến.';
    }
    if (draft.items.isEmpty) {
      return 'Thêm ít nhất một món hàng hoặc tắt gửi hàng kèm vé.';
    }
    if (!points!.senders.any((v) => v.id == draft.senderPointId) ||
        !points!.receivers.any((v) => v.id == draft.receiverPointId) ||
        draft.senderPointId == draft.receiverPointId) {
      return 'Chọn điểm gửi và điểm nhận khác nhau, thuộc đúng tuyến.';
    }
    final counts = <CargoGroup, int>{};
    for (final item in draft.items) {
      if (item.validationError != null) return item.validationError;
      final category = categories
          .where((v) => v.id == item.categoryId)
          .firstOrNull;
      if (category == null || category.group != item.group) {
        return 'Loại hàng không hợp lệ hoặc không đúng nhóm sức chứa.';
      }
      counts[item.group] = (counts[item.group] ?? 0) + item.quantity;
    }
    for (final entry in counts.entries) {
      if (entry.value > (capacity.slots[entry.key]?.remaining ?? 0)) {
        return 'Sức chứa hàng còn lại không đủ cho số lượng đã chọn.';
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [tripId, categories, capacity, points];
}

class BookingCargoState extends Equatable {
  final bool enabled;
  final bool loading;
  final CargoOptions? options;
  final BookingCargoDraft? draft;
  final String? error;
  const BookingCargoState({
    this.enabled = false,
    this.loading = false,
    this.options,
    this.draft,
    this.error,
  });
  String? get validationError => !enabled
      ? null
      : loading
      ? 'Đang kiểm tra dịch vụ gửi hàng.'
      : error ??
            (options == null
                ? 'Chưa tải được thông tin gửi hàng.'
                : draft == null
                ? 'Thêm hàng và chọn điểm gửi/nhận.'
                : options!.validate(draft!));
  bool get isValid => validationError == null;
  // No public authoritative cargo quote exists. Never report an unquoted fee as 0.
  bool get needsServerPricing => enabled;
  @override
  List<Object?> get props => [enabled, loading, options, draft, error];
}

class BookingShipmentSummary extends Equatable {
  final int id;
  final String code;
  final int shippingFee;
  final int itemCount;
  const BookingShipmentSummary({
    required this.id,
    required this.code,
    required this.shippingFee,
    required this.itemCount,
  });
  factory BookingShipmentSummary.fromJson(Map<String, dynamic> json) =>
      BookingShipmentSummary(
        id: cargoInteger(json['shipmentId'], minimum: 1),
        code: cargoText(json['shipmentCode']),
        shippingFee: cargoInteger(json['shippingFee']),
        itemCount: cargoInteger(json['itemCount'], minimum: 1),
      );
  Map<String, dynamic> toJson() => {
    'shipmentId': id,
    'shipmentCode': code,
    'shippingFee': shippingFee,
    'itemCount': itemCount,
  };
  @override
  List<Object?> get props => [id, code, shippingFee, itemCount];
}

class BookingCargoLine extends Equatable {
  final String name;
  final int quantity;
  const BookingCargoLine({required this.name, required this.quantity});
  factory BookingCargoLine.fromJson(Map<String, dynamic> json) =>
      BookingCargoLine(
        name: cargoText(json['name']),
        quantity: cargoInteger(json['quantity'], minimum: 1),
      );
  Map<String, dynamic> toJson() => {'name': name, 'quantity': quantity};
  @override
  List<Object?> get props => [name, quantity];
}
