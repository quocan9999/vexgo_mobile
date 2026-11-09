import 'package:equatable/equatable.dart';

String evidenceText(dynamic value) {
  if (value == null) return '';
  if (value is! String) {
    throw const FormatException('Thông tin mô tả không hợp lệ.');
  }
  return value.trim();
}

int? evidenceMoney(dynamic value) {
  if (value == null) return null;
  final number = value is num ? value : num.tryParse(value.toString());
  if (number == null ||
      !number.isFinite ||
      number < 0 ||
      number > 9007199254740991 ||
      number != number.roundToDouble()) {
    throw const FormatException('Số tiền không hợp lệ.');
  }
  return number.toInt();
}

/// Vietnam business clock, independent of the phone's selected time zone.
DateTime? evidenceInstant(dynamic value) {
  if (value == null || value == '') return null;
  if (value is! String || !value.contains('T')) return null;
  final zoned = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value);
  return DateTime.tryParse(zoned ? value : '$value+07:00')?.toUtc();
}

String evidenceClock(DateTime instant, {bool withDate = true}) {
  final vn = instant.toUtc().add(const Duration(hours: 7));
  String two(int n) => n.toString().padLeft(2, '0');
  final clock = '${two(vn.hour)}:${two(vn.minute)}';
  return withDate ? '$clock ${two(vn.day)}/${two(vn.month)}/${vn.year}' : clock;
}

class StopSnapshot extends Equatable {
  final String name, address, phone, code, type;
  final int? offsetMinutes, arrivalLeadMinutes, tripStopId;
  final int? surcharge;
  final String transferName, transferAddress;
  final int? transferId;
  const StopSnapshot({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.code = '',
    this.type = '',
    this.offsetMinutes,
    this.arrivalLeadMinutes,
    this.tripStopId,
    this.surcharge,
    this.transferName = '',
    this.transferAddress = '',
    this.transferId,
  });

  static StopSnapshot? parse(dynamic value) {
    if (value == null) return null;
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Điểm đón/trả không hợp lệ.');
    }
    int? integer(dynamic v, {bool signed = false}) {
      if (v == null) return null;
      if (v is! int || v > 2147483647 || v < (signed ? -2147483648 : 0)) {
        throw const FormatException(
          'Thời gian/định danh điểm đón trả không hợp lệ.',
        );
      }
      return v;
    }

    final transfer = value['benTrungChuyen'];
    if (transfer != null && transfer is! Map<String, dynamic>) {
      throw const FormatException('Điểm trung chuyển không hợp lệ.');
    }
    return StopSnapshot(
      name: evidenceText(value['tenDiem']),
      address: evidenceText(value['diaChi']),
      phone: evidenceText(value['soDienThoai']),
      code: evidenceText(value['maDiem']),
      type: evidenceText(value['loaiDiem']),
      offsetMinutes: integer(value['phutLech'], signed: true),
      arrivalLeadMinutes: integer(value['phutCoMatTruoc']),
      tripStopId: integer(value['diemDonTraChuyenXeId']),
      surcharge: evidenceMoney(value['phuPhi']),
      transferName: evidenceText(transfer?['tenDiem']),
      transferAddress: evidenceText(transfer?['diaChi']),
      transferId: integer(transfer?['id']),
    );
  }

  DateTime? at(DateTime? departure) =>
      departure == null || offsetMinutes == null
      ? null
      : departure.toUtc().add(Duration(minutes: offsetMinutes!));
  DateTime? arriveBy(DateTime? departure) {
    final time = at(departure);
    return time == null || arrivalLeadMinutes == null
        ? null
        : time.subtract(Duration(minutes: arrivalLeadMinutes!));
  }

  Map<String, dynamic> toJson() => {
    'tenDiem': name,
    'diaChi': address,
    'soDienThoai': phone,
    'maDiem': code,
    'loaiDiem': type,
    if (offsetMinutes != null) 'phutLech': offsetMinutes,
    if (arrivalLeadMinutes != null) 'phutCoMatTruoc': arrivalLeadMinutes,
    if (tripStopId != null) 'diemDonTraChuyenXeId': tripStopId,
    if (surcharge != null) 'phuPhi': surcharge,
    if (transferName.isNotEmpty ||
        transferAddress.isNotEmpty ||
        transferId != null)
      'benTrungChuyen': {
        'tenDiem': transferName,
        'diaChi': transferAddress,
        if (transferId != null) 'id': transferId,
      },
  };
  @override
  List<Object?> get props => [
    name,
    address,
    phone,
    code,
    type,
    offsetMinutes,
    arrivalLeadMinutes,
    tripStopId,
    surcharge,
    transferName,
    transferAddress,
    transferId,
  ];
}

/// Read-only cargo metadata. Fee is stored at order level, never per ticket.
class EvidenceCargo extends Equatable {
  final String name, category, categoryName, note;
  final int quantity;
  final double? weight;
  const EvidenceCargo(
    this.name,
    this.quantity, {
    this.weight,
    this.category = '',
    this.categoryName = '',
    this.note = '',
  });
  factory EvidenceCargo.fromJson(Map<String, dynamic> json) {
    final quantity = evidenceMoney(json['quantity']);
    final rawWeight = json['weight'];
    final weight = rawWeight == null
        ? null
        : (rawWeight is num
              ? rawWeight.toDouble()
              : double.tryParse(rawWeight.toString()));
    if (quantity == null ||
        quantity < 1 ||
        (rawWeight != null &&
            (weight == null || !weight.isFinite || weight < 0))) {
      throw const FormatException('Số lượng/khối lượng vật phẩm không hợp lệ.');
    }
    return EvidenceCargo(
      evidenceText(json['name']),
      quantity,
      weight: weight,
      category: evidenceText(json['category']),
      categoryName: evidenceText(json['categoryName']),
      note: evidenceText(json['note']),
    );
  }
  static List<EvidenceCargo> parseList(dynamic json) {
    if (json == null) return const [];
    if (json is! List) {
      throw const FormatException('Danh sách vật phẩm không hợp lệ.');
    }
    return List.unmodifiable(
      json.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Vật phẩm không hợp lệ.');
        }
        return EvidenceCargo.fromJson(item);
      }),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    if (weight != null) 'weight': weight,
    'category': category,
    'categoryName': categoryName,
    'note': note,
  };
  @override
  List<Object?> get props => [
    name,
    quantity,
    weight,
    category,
    categoryName,
    note,
  ];
}
