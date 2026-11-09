import 'booking_cargo_model.dart';

double _positive(Object? value, {bool zero = false}) {
  if (value is! num || !value.isFinite || (zero ? value < 0 : value <= 0)) {
    throw const FormatException('Thông số hành lý không hợp lệ.');
  }
  return value.toDouble();
}

class LuggagePackage {
  final String code;
  final String name;
  final double maxWeightKg;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final int referenceFee;
  const LuggagePackage({
    required this.code,
    required this.name,
    required this.maxWeightKg,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.referenceFee,
  });

  factory LuggagePackage.fromJson(Map<String, dynamic> json) {
    final code = cargoText(json['code']);
    if (!['S', 'M', 'L', 'XL'].contains(code)) {
      throw const FormatException('Mã gói hành lý chưa được hỗ trợ.');
    }
    return LuggagePackage(
      code: code,
      name: cargoText(json['name']),
      maxWeightKg: _positive(json['weight']),
      lengthCm: _positive(json['length']),
      widthCm: _positive(json['width']),
      heightCm: _positive(json['height']),
      referenceFee: cargoInteger(json['baseFee']),
    );
  }
}

/// All numbers come from the trip-specific public policy endpoint, never defaults.
class LuggagePolicy {
  final int tripId;
  final int routeId;
  final int busCompanyId;
  final String busCompanyName;
  final double freeWeightPerPassengerKg;
  final List<LuggagePackage> packages;
  final Map<String, int> vehicleFees;
  final Map<String, int> serviceFees;
  LuggagePolicy({
    required this.tripId,
    required this.routeId,
    required this.busCompanyId,
    required this.busCompanyName,
    required this.freeWeightPerPassengerKg,
    required List<LuggagePackage> packages,
    required Map<String, int> vehicleFees,
    required Map<String, int> serviceFees,
  }) : packages = List.unmodifiable(packages),
       vehicleFees = Map.unmodifiable(vehicleFees),
       serviceFees = Map.unmodifiable(serviceFees);

  factory LuggagePolicy.fromJson(Map<String, dynamic> json) {
    final raw = json['packages'];
    if (raw is! List ||
        raw.length != 4 ||
        json['vehicles'] is! Map ||
        json['surcharges'] is! Map) {
      throw const FormatException('Bảng gói hành lý không đầy đủ.');
    }
    final packages = raw.map((p) {
      if (p is! Map<String, dynamic>) {
        throw const FormatException('Gói hành lý không hợp lệ.');
      }
      return LuggagePackage.fromJson(p);
    }).toList();
    const codes = ['S', 'M', 'L', 'XL'];
    if (packages.map((p) => p.code).toSet().length != 4) {
      throw const FormatException('Gói hành lý bị trùng.');
    }
    packages.sort(
      (a, b) => codes.indexOf(a.code).compareTo(codes.indexOf(b.code)),
    );
    for (var i = 1; i < packages.length; i++) {
      if (packages[i].maxWeightKg <= packages[i - 1].maxWeightKg) {
        throw const FormatException('Hạn mức các gói hành lý không nhất quán.');
      }
    }
    Map<String, int> fees(Object? value, List<String> keys) {
      final map = value as Map;
      return {for (final key in keys) key: cargoInteger(map[key])};
    }

    return LuggagePolicy(
      tripId: cargoInteger(json['tripId'], minimum: 1),
      routeId: cargoInteger(json['routeId'], minimum: 1),
      busCompanyId: cargoInteger(json['busCompanyId'], minimum: 1),
      busCompanyName: cargoText(json['busCompanyName']),
      freeWeightPerPassengerKg: _positive(json['maxFreeWeightKg'], zero: true),
      packages: packages,
      vehicleFees: fees(json['vehicles'], [
        'motorcycleWave',
        'motorcycleScooter',
        'motorcycleBig',
        'bicycle',
      ]),
      serviceFees: fees(json['surcharges'], ['fragile', 'valuable']),
    );
  }

  LuggagePackage? package(String? code) =>
      packages.where((p) => p.code == code).firstOrNull;
}

/// One small carry-on per passenger, per the current Web flow. Not checked cargo.
/// The booking DTO has no carry-on field, so these declarations stay on the client.
class CarryOnBag {
  final double weightKg;
  final int quantity;
  const CarryOnBag({required this.weightKg, this.quantity = 1});
}

enum LuggageMotorcycleTariff { wave, scooter, big }

class CheckedLuggageItem {
  final CargoItemDraft cargo;
  final String? packageCode;
  final LuggageMotorcycleTariff motorcycleTariff;
  const CheckedLuggageItem({
    required this.cargo,
    this.packageCode,
    this.motorcycleTariff = LuggageMotorcycleTariff.wave,
  });

  String? validate(LuggagePolicy policy) {
    if (cargo.validationError != null) return cargo.validationError;
    if (cargo.isVehicle) {
      if (packageCode != null) {
        return 'Phương tiện không áp dụng gói kiện S/M/L/XL.';
      }
      return null;
    }
    final pack = policy.package(packageCode);
    if (pack == null) return 'Chọn gói hành lý hợp lệ.';
    if (cargo.effectiveWeight > pack.maxWeightKg) {
      return 'Khối lượng hiệu dụng vượt hạn mức gói đã chọn.';
    }
    if ((cargo.length ?? 0) > pack.lengthCm ||
        (cargo.width ?? 0) > pack.widthCm ||
        (cargo.height ?? 0) > pack.heightCm) {
      return 'Kích thước kiện vượt hạn mức gói đã chọn.';
    }
    return null;
  }

  /// UI reference only. Backend currently prices cargo against BangCuocGuiHang.
  int referenceFee(LuggagePolicy policy) {
    final error = validate(policy);
    if (error != null) throw StateError(error);
    final base = switch (cargo.kind) {
      CargoKind.bicycle => policy.vehicleFees['bicycle']!,
      CargoKind.motorcycle =>
        policy.vehicleFees[switch (motorcycleTariff) {
          LuggageMotorcycleTariff.wave => 'motorcycleWave',
          LuggageMotorcycleTariff.scooter => 'motorcycleScooter',
          LuggageMotorcycleTariff.big => 'motorcycleBig',
        }]!,
      _ => policy.package(packageCode)!.referenceFee,
    };
    final surcharge = cargo.service == CargoService.normal
        ? 0
        : policy.serviceFees[cargo.service.name]!;
    final total =
        (BigInt.from(base) + BigInt.from(surcharge)) *
        BigInt.from(cargo.quantity);
    if (total > BigInt.from(9007199254740991)) {
      throw const FormatException('Phí tham khảo vượt giới hạn.');
    }
    return total.toInt();
  }
}

class LuggageSelection {
  final List<CarryOnBag> carryOn;
  final List<CheckedLuggageItem> checked;
  final int? senderPointId;
  final int? receiverPointId;
  LuggageSelection({
    List<CarryOnBag> carryOn = const [],
    List<CheckedLuggageItem> checked = const [],
    this.senderPointId,
    this.receiverPointId,
  }) : carryOn = List.unmodifiable(carryOn),
       checked = List.unmodifiable(checked);

  String? validate(
    LuggagePolicy policy,
    CargoOptions options,
    int passengerCount,
  ) {
    if (passengerCount < 1 ||
        passengerCount > 5 ||
        policy.tripId != options.tripId) {
      return 'Thông tin chuyến hoặc số hành khách chưa hợp lệ.';
    }
    var bagCount = 0;
    for (final bag in carryOn) {
      if (!bag.weightKg.isFinite ||
          bag.weightKg <= 0 ||
          bag.quantity < 1 ||
          bag.quantity > passengerCount) {
        return 'Khai báo hành lý xách tay chưa hợp lệ.';
      }
      if (bag.weightKg > policy.freeWeightPerPassengerKg) {
        return 'Hành lý xách tay vượt hạn mức miễn phí; hãy chuyển sang hành lý ký gửi.';
      }
      bagCount += bag.quantity;
    }
    if (bagCount > passengerCount) {
      return 'Mỗi hành khách được khai báo tối đa một kiện xách tay miễn phí.';
    }
    if (checked.isEmpty) {
      return null; // Free carry-on is not blocked by hold cargo capacity.
    }
    for (final item in checked) {
      final error = item.validate(policy);
      if (error != null) return error;
    }
    try {
      referenceFee(policy);
    } on FormatException catch (error) {
      return error.message;
    }
    return options.validate(toBookingCargo()!);
  }

  BookingCargoDraft? toBookingCargo() => checked.isEmpty
      ? null
      : BookingCargoDraft(
          items: checked.map((item) => item.cargo).toList(),
          senderPointId: senderPointId,
          receiverPointId: receiverPointId,
        );

  int referenceFee(LuggagePolicy policy) {
    final total = checked.fold<BigInt>(
      BigInt.zero,
      (sum, item) => sum + BigInt.from(item.referenceFee(policy)),
    );
    if (total > BigInt.from(9007199254740991)) {
      throw const FormatException('Tổng phí tham khảo vượt giới hạn.');
    }
    return total.toInt();
  }
}
