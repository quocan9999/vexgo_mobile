import 'booking_cargo_model.dart';

Map<String, dynamic> shipmentMap(Object? value) {
  if (value is! Map) throw const FormatException('Invalid shipment object');
  return Map<String, dynamic>.from(value);
}

List<T> shipmentList<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) throw const FormatException('Invalid shipment list');
  return List.unmodifiable(value.map((v) => parse(shipmentMap(v))));
}

DateTime shipmentDate(Object? value) {
  final text = cargoText(value);
  if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text)) {
    throw const FormatException('Shipment date needs a timezone');
  }
  final date = DateTime.tryParse(text);
  if (date == null) throw const FormatException('Invalid shipment date');
  return date.toUtc();
}

String normalizeShipmentPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.startsWith('84') ? '0${digits.substring(2)}' : digits;
}

bool validShipmentPhone(String value) => RegExp(
  r'^(?:\+84|0)(?:3[2-9]|5[689]|7[06-9]|8[1-9]|9\d)\d{7}$',
).hasMatch(value.trim());

enum ShipmentStatus {
  created('MOI_TAO'),
  accepted('DA_TIEP_NHAN'),
  inTransit('DANG_VAN_CHUYEN'),
  delivered('DA_GIAO'),
  cancelled('DA_HUY'),
  unknown('UNKNOWN');

  final String code;
  const ShipmentStatus(this.code);
  static ShipmentStatus parse(Object? value) =>
      ShipmentStatus.values.firstWhere(
        (v) => v != unknown && v.code == value,
        orElse: () => unknown,
      );
}

enum ShipmentPaymentMethod {
  counter('TAI_BEN'),
  online('ONLINE'),
  unknown('UNKNOWN');

  final String code;
  const ShipmentPaymentMethod(this.code);
  static ShipmentPaymentMethod parse(Object? value) => switch (value) {
    'TAI_BEN' => counter,
    'ONLINE' || 'SEPAY' => online,
    _ => unknown,
  };
}

enum ShipmentPayer {
  sender('NGUOI_GUI'),
  receiver('NGUOI_NHAN');

  final String code;
  const ShipmentPayer(this.code);
}

enum ShipmentService {
  normal('NORMAL'),
  fragile('FRAGILE'),
  valuable('VALUABLE');

  final String code;
  const ShipmentService(this.code);
}

class ShipmentValidationException implements Exception {
  final Map<String, String> fields;
  ShipmentValidationException(Map<String, String> fields)
    : fields = Map.unmodifiable(fields);
  @override
  String toString() => 'Thông tin gửi hàng chưa hợp lệ.';
}

class ShipmentItem {
  final String name;
  final int categoryId;
  final int quantity;
  final double weight;
  final double? length, width, height;
  final ShipmentService service;
  final String note;
  const ShipmentItem({
    required this.name,
    required this.categoryId,
    required this.weight,
    this.quantity = 1,
    this.length,
    this.width,
    this.height,
    this.service = ShipmentService.normal,
    this.note = '',
  });
  Map<String, String> get errors {
    final errors = <String, String>{};
    if (name.trim().isEmpty) errors['name'] = 'Nhập tên hàng hóa.';
    if (categoryId <= 0) errors['categoryId'] = 'Chọn loại hàng hóa.';
    if (quantity < 1 || quantity > 9007199254740991) {
      errors['quantity'] = 'Số lượng phải là số nguyên dương.';
    }
    if (!weight.isFinite || weight < 0.1) {
      errors['weight'] = 'Khối lượng mỗi kiện phải từ 0,1 kg.';
    }
    final dimensions = [length, width, height];
    if (dimensions.any((v) => v != null) &&
        !dimensions.every((v) => v != null && v.isFinite && v > 0)) {
      errors['dimensions'] = 'Nhập đủ ba kích thước dương hoặc để trống cả ba.';
    }
    return errors;
  }

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'loaiHangHoaId': categoryId,
    'quantity': quantity,
    'weight': weight,
    if (length != null) 'length': length,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    'serviceType': service.code,
    if (note.trim().isNotEmpty) 'note': note.trim(),
  };
}

class ShipmentDraft {
  final int routeId, senderPointId, receiverPointId;
  final String? sendDate;
  final String senderName,
      senderPhone,
      senderEmail,
      receiverName,
      receiverPhone,
      receiverCccd,
      note;
  final List<ShipmentItem> items;
  final ShipmentPayer payer;
  final ShipmentPaymentMethod paymentMethod;
  ShipmentDraft({
    required this.routeId,
    this.sendDate,
    required this.senderPointId,
    required this.receiverPointId,
    required this.senderName,
    required this.senderPhone,
    this.senderEmail = '',
    required this.receiverName,
    required this.receiverPhone,
    this.receiverCccd = '',
    required List<ShipmentItem> items,
    this.payer = ShipmentPayer.sender,
    this.paymentMethod = ShipmentPaymentMethod.counter,
    this.note = '',
  }) : items = List.unmodifiable(items);
  Map<String, String> get errors {
    final result = <String, String>{};
    if (routeId <= 0) result['routeId'] = 'Chọn tuyến và nhà xe.';
    if (sendDate != null && !validShipmentSendDate(sendDate!)) {
      result['sendDate'] = 'Ngày gửi phải theo DD-MM-YYYY.';
    }
    if (senderPointId <= 0) result['senderPointId'] = 'Chọn điểm gửi.';
    if (receiverPointId <= 0) result['receiverPointId'] = 'Chọn điểm nhận.';
    if (senderName.trim().isEmpty || senderName.trim().length > 100) {
      result['sender.fullName'] = 'Nhập họ tên người gửi.';
    }
    if (receiverName.trim().isEmpty || receiverName.trim().length > 100) {
      result['receiver.fullName'] = 'Nhập họ tên người nhận.';
    }
    if (!validShipmentPhone(senderPhone)) {
      result['sender.phoneNumber'] = 'Số điện thoại không hợp lệ.';
    }
    if (!validShipmentPhone(receiverPhone)) {
      result['receiver.phoneNumber'] = 'Số điện thoại không hợp lệ.';
    }
    if (senderEmail.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(senderEmail.trim())) {
      result['sender.email'] = 'Email không hợp lệ.';
    }
    if (receiverCccd.trim().isNotEmpty &&
        !RegExp(r'^(?:\d{9}|\d{12})$').hasMatch(receiverCccd.trim())) {
      result['receiver.cccd'] = 'CCCD/CMND gồm 9 hoặc 12 chữ số.';
    }
    if (items.isEmpty) result['items'] = 'Thêm ít nhất một kiện hàng.';
    for (var i = 0; i < items.length; i++) {
      for (final e in items[i].errors.entries) {
        result['items.$i.${e.key}'] = e.value;
      }
    }
    if (paymentMethod != ShipmentPaymentMethod.counter) {
      result['paymentMethod'] = 'Gửi hàng độc lập chỉ thanh toán tại bến.';
    }
    return result;
  }

  Map<String, dynamic> toJson() {
    if (errors.isNotEmpty) throw ShipmentValidationException(errors);
    return {
      'routeId': routeId,
      if (sendDate != null) 'sendDate': sendDate,
      'senderPointId': senderPointId,
      'receiverPointId': receiverPointId,
      'sender': {
        'fullName': senderName.trim(),
        'phoneNumber': senderPhone.trim(),
        if (senderEmail.trim().isNotEmpty) 'email': senderEmail.trim(),
      },
      'receiver': {
        'fullName': receiverName.trim(),
        'phoneNumber': receiverPhone.trim(),
        if (receiverCccd.trim().isNotEmpty) 'cccd': receiverCccd.trim(),
      },
      'items': items.map((i) => i.toJson()).toList(),
      'freightPayer': payer.code,
      'paymentMethod': paymentMethod.code,
      if (note.trim().isNotEmpty) 'note': note.trim(),
    };
  }
}

bool validShipmentSendDate(String value) {
  final m = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(value);
  if (m == null) return false;
  final d = int.parse(m[1]!), month = int.parse(m[2]!), y = int.parse(m[3]!);
  final date = DateTime.utc(y, month, d);
  return date.year == y && date.month == month && date.day == d;
}

class ShipmentRoute {
  final int id, carrierId;
  final String carrier, origin, destination;
  final int? minimumEstimatedFee;
  const ShipmentRoute({
    required this.id,
    required this.carrierId,
    required this.carrier,
    required this.origin,
    required this.destination,
    this.minimumEstimatedFee,
  });
  factory ShipmentRoute.fromJson(Map<String, dynamic> j) => ShipmentRoute(
    id: cargoInteger(j['routeId'], minimum: 1),
    carrierId: cargoInteger(shipmentMap(j['busCompany'])['id'], minimum: 1),
    carrier: cargoText(shipmentMap(j['busCompany'])['name']),
    origin: cargoText(shipmentMap(j['route'])['origin']),
    destination: cargoText(shipmentMap(j['route'])['destination']),
    minimumEstimatedFee: j['minimumEstimatedFee'] == null
        ? null
        : cargoInteger(j['minimumEstimatedFee']),
  );
}

class ShipmentQuoteRate {
  final int categoryId, rateId, fee;
  final double billableWeight;
  ShipmentQuoteRate.fromJson(Map<String, dynamic> j)
    : categoryId = cargoInteger(j['categoryId'], minimum: 1),
      rateId = cargoInteger(j['rateId'], minimum: 1),
      fee = cargoInteger(j['fee']),
      billableWeight = ShipmentPackage._weight(j['billableWeight']);
}

class ShipmentQuote {
  final int baseFee, serviceFee, totalFee;
  final List<ShipmentQuoteRate> rates;
  ShipmentQuote.fromJson(Map<String, dynamic> j)
    : baseFee = cargoInteger(j['baseFee']),
      serviceFee = cargoInteger(j['serviceFee']),
      totalFee = cargoInteger(j['totalFee']),
      rates = shipmentList(j['rates'], ShipmentQuoteRate.fromJson) {
    if (totalFee != baseFee + serviceFee ||
        rates.isEmpty ||
        rates.fold<int>(0, (sum, r) => sum + r.fee) != baseFee) {
      throw const FormatException('Inconsistent shipment quote');
    }
  }
}

class ShipmentTrip {
  final int? id;
  final String? code;
  final String carrier, origin, destination;
  final DateTime? departure;
  const ShipmentTrip({
    required this.id,
    required this.code,
    required this.carrier,
    required this.origin,
    required this.destination,
    required this.departure,
  });
  factory ShipmentTrip.fromJson(Map<String, dynamic> j) => ShipmentTrip(
    id: j['id'] == null ? null : cargoInteger(j['id'], minimum: 1),
    code: j['code'] == null ? null : cargoText(j['code']),
    carrier: cargoText(shipmentMap(j['busCompany'])['name']),
    origin: cargoText(shipmentMap(j['route'])['origin']),
    destination: cargoText(shipmentMap(j['route'])['destination']),
    departure: j['departureTime'] == null
        ? null
        : shipmentDate(j['departureTime']),
  );
}

class ShipmentRate {
  final int senderPointId, receiverPointId, categoryId, fee;
  final double minWeight;
  final double? maxWeight;
  const ShipmentRate({
    required this.senderPointId,
    required this.receiverPointId,
    required this.categoryId,
    required this.fee,
    required this.minWeight,
    this.maxWeight,
  });
  factory ShipmentRate.fromJson(Map<String, dynamic> j) {
    final min = j['minWeight'], max = j['maxWeight'];
    if (min is! num ||
        !min.isFinite ||
        min < 0 ||
        (max != null && (max is! num || !max.isFinite || max < min))) {
      throw const FormatException('Invalid shipment weight range');
    }
    return ShipmentRate(
      senderPointId: cargoInteger(j['senderPointId'], minimum: 1),
      receiverPointId: cargoInteger(j['receiverPointId'], minimum: 1),
      categoryId: cargoInteger(j['categoryId'], minimum: 1),
      fee: cargoInteger(j['fee']),
      minWeight: min.toDouble(),
      maxWeight: (max as num?)?.toDouble(),
    );
  }
}

class ShipmentOptions {
  final int routeId;
  final List<CargoCategory> categories;
  final List<CargoPoint> senders, receivers;
  ShipmentOptions({
    required this.routeId,
    required List<CargoCategory> categories,
    required List<CargoPoint> senders,
    required List<CargoPoint> receivers,
  }) : categories = List.unmodifiable(categories),
       senders = List.unmodifiable(senders),
       receivers = List.unmodifiable(receivers);
}

class ShipmentIdentity {
  final int shipmentId, orderId;
  final String waybillCode, orderCode;
  const ShipmentIdentity({
    required this.shipmentId,
    required this.orderId,
    required this.waybillCode,
    required this.orderCode,
  });
  factory ShipmentIdentity.fromJson(Map<String, dynamic> j) => ShipmentIdentity(
    shipmentId: cargoInteger(j['shipmentId'], minimum: 1),
    orderId: cargoInteger(j['orderId'], minimum: 1),
    waybillCode: cargoText(j['waybillCode']),
    orderCode: cargoText(j['orderCode']),
  );
}

class ShipmentPackage {
  final int id, quantity;
  final String name, category;
  final double weight;
  final String? dimensions, note;
  ShipmentPackage.fromJson(Map<String, dynamic> j)
    : id = cargoInteger(j['id'], minimum: 1),
      quantity = cargoInteger(j['quantity'], minimum: 1),
      name = cargoText(j['name']),
      category = cargoText(j['category']),
      weight = _weight(j['weight']),
      dimensions = j['dimensions'] as String?,
      note = j['note'] as String?;
  static double _weight(Object? value) {
    if (value is! num || !value.isFinite || value <= 0) {
      throw const FormatException('Invalid shipment package weight');
    }
    return value.toDouble();
  }
}

class ShipmentRecord {
  final ShipmentTrip trip;
  final CargoPoint pickup, dropoff;
  final List<ShipmentPackage> items;
  final List<ShipmentTimelineEntry> timeline;
  final DateTime sentAt;
  final String? senderEmail, receiverCccd, note;
  final ShipmentIdentity identity;
  final int? tripId;
  final DateTime? dropoffDeadline, confirmedAt;
  final String? expectedSendDate;
  final int? estimatedFee, paidAmount, outstandingAmount;
  final int paymentId,
      senderPointId,
      receiverPointId,
      totalFee,
      baseFee,
      serviceFee,
      discount;
  final String senderName,
      senderPhone,
      receiverName,
      receiverPhone,
      rawStatus,
      rawPaymentStatus;
  final ShipmentPaymentMethod paymentMethod;
  final ShipmentPayer payer;
  final DateTime expiresAt;
  ShipmentStatus get status => ShipmentStatus.parse(rawStatus);
  ShipmentRecord({
    required this.trip,
    required this.pickup,
    required this.dropoff,
    required List<ShipmentPackage> items,
    required List<ShipmentTimelineEntry> timeline,
    required this.sentAt,
    this.senderEmail,
    this.receiverCccd,
    this.note,
    required this.identity,
    required this.paymentId,
    required this.tripId,
    required this.senderPointId,
    required this.receiverPointId,
    required this.totalFee,
    required this.baseFee,
    required this.serviceFee,
    required this.discount,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.rawStatus,
    required this.rawPaymentStatus,
    required this.paymentMethod,
    required this.payer,
    required this.expiresAt,
    this.dropoffDeadline,
    this.expectedSendDate,
    this.confirmedAt,
    this.estimatedFee,
    this.paidAmount,
    this.outstandingAmount,
  }) : items = List.unmodifiable(items),
       timeline = List.unmodifiable(timeline);

  ShipmentRecord copyWithTracking({
    required String status,
    String? paymentStatus,
    List<ShipmentTimelineEntry>? history,
  }) => ShipmentRecord(
    trip: trip,
    pickup: pickup,
    dropoff: dropoff,
    sentAt: sentAt,
    senderEmail: senderEmail,
    receiverCccd: receiverCccd,
    note: note,
    identity: identity,
    paymentId: paymentId,
    tripId: tripId,
    senderPointId: senderPointId,
    receiverPointId: receiverPointId,
    totalFee: totalFee,
    baseFee: baseFee,
    serviceFee: serviceFee,
    discount: discount,
    senderName: senderName,
    senderPhone: senderPhone,
    receiverName: receiverName,
    receiverPhone: receiverPhone,
    rawStatus: status,
    rawPaymentStatus: paymentStatus ?? rawPaymentStatus,
    paymentMethod: paymentMethod,
    payer: payer,
    expiresAt: expiresAt,
    dropoffDeadline: dropoffDeadline,
    expectedSendDate: expectedSendDate,
    confirmedAt: confirmedAt,
    estimatedFee: estimatedFee,
    paidAmount: paidAmount,
    outstandingAmount: outstandingAmount,
    items: items,
    timeline: history ?? timeline,
  );
  factory ShipmentRecord.fromJson(Map<String, dynamic> j) {
    final p = shipmentMap(j['pricing']),
        sender = shipmentMap(j['sender']),
        receiver = shipmentMap(j['receiver']);
    final base = cargoInteger(p['baseFee']),
        service = cargoInteger(p['serviceFee']),
        discount = cargoInteger(p['discount']),
        total = cargoInteger(p['totalFee']);
    if (total != base + service - discount) {
      throw const FormatException('Inconsistent shipment total');
    }
    final payer = ShipmentPayer.values.firstWhere(
      (v) => v.code == j['freightPayer'],
      orElse: () => throw const FormatException('Missing shipment payer'),
    );
    final method = ShipmentPaymentMethod.parse(j['paymentMethod']);
    if (method == ShipmentPaymentMethod.unknown ||
        (payer == ShipmentPayer.receiver &&
            method != ShipmentPaymentMethod.counter)) {
      throw const FormatException('Invalid shipment payment method');
    }
    return ShipmentRecord(
      trip: ShipmentTrip.fromJson({
        ...shipmentMap(j['trip']),
        'id': shipmentMap(j['trip'])['tripId'],
      }),
      pickup: CargoPoint.fromJson(shipmentMap(j['pickupPoint'])),
      dropoff: CargoPoint.fromJson(shipmentMap(j['dropoffPoint'])),
      items: shipmentList(j['items'], ShipmentPackage.fromJson),
      timeline: shipmentList(
        j['timeline'] ?? [],
        ShipmentTimelineEntry.fromJson,
      ),
      sentAt: shipmentDate(j['sentAt']),
      senderEmail: sender['email'] as String?,
      receiverCccd: receiver['cccd'] as String?,
      note: j['note'] as String?,
      identity: ShipmentIdentity.fromJson(j),
      paymentId: cargoInteger(j['paymentId'], minimum: 1),
      tripId: shipmentMap(j['trip'])['tripId'] == null
          ? null
          : cargoInteger(shipmentMap(j['trip'])['tripId'], minimum: 1),
      senderPointId: cargoInteger(
        shipmentMap(j['pickupPoint'])['id'],
        minimum: 1,
      ),
      receiverPointId: cargoInteger(
        shipmentMap(j['dropoffPoint'])['id'],
        minimum: 1,
      ),
      totalFee: total,
      baseFee: base,
      serviceFee: service,
      discount: discount,
      senderName: cargoText(sender['fullName']),
      senderPhone: cargoText(sender['phoneNumber']),
      receiverName: cargoText(receiver['fullName']),
      receiverPhone: cargoText(receiver['phoneNumber']),
      rawStatus: cargoText(j['status']),
      rawPaymentStatus: cargoText(j['paymentStatus']),
      paymentMethod: method,
      payer: payer,
      expiresAt: shipmentDate(j['paymentExpiresAt']),
      dropoffDeadline: j['dropoffDeadline'] == null
          ? null
          : shipmentDate(j['dropoffDeadline']),
      expectedSendDate: j['expectedSendDate'] as String?,
      confirmedAt: p['confirmedAt'] == null
          ? null
          : shipmentDate(p['confirmedAt']),
      estimatedFee: p['estimatedFee'] == null
          ? null
          : cargoInteger(p['estimatedFee']),
      paidAmount: p['paidAmount'] == null
          ? null
          : cargoInteger(p['paidAmount']),
      outstandingAmount: p['outstandingAmount'] == null
          ? null
          : cargoInteger(p['outstandingAmount']),
    );
  }
}

class ShipmentCreationUncertain implements Exception {
  final ShipmentIdentity? identity;
  const ShipmentCreationUncertain({this.identity});
  @override
  String toString() => 'Chưa xác minh kết quả tạo đơn; không gửi lại yêu cầu.';
}

class ShipmentTimelineEntry {
  final String rawStatus;
  final DateTime time;
  const ShipmentTimelineEntry(this.rawStatus, this.time);
  factory ShipmentTimelineEntry.fromJson(Map<String, dynamic> j) =>
      ShipmentTimelineEntry(cargoText(j['status']), shipmentDate(j['time']));
}

class ShipmentLookup {
  final String waybillCode, orderCode, rawStatus, rawOrderStatus;
  final String? rawPaymentStatus;
  final int amount, packageCount;
  final ShipmentPaymentMethod paymentMethod;
  final bool requiresReconciliation;
  final DateTime expiresAt, serverTime;
  final DateTime? dropoffDeadline;
  final String pickupName,
      pickupAddress,
      dropoffName,
      dropoffAddress,
      carrier,
      origin,
      destination;
  final List<ShipmentTimelineEntry> timeline;
  ShipmentLookup({
    required this.waybillCode,
    required this.orderCode,
    required this.rawStatus,
    required this.rawOrderStatus,
    required this.rawPaymentStatus,
    required this.amount,
    required this.packageCount,
    required this.paymentMethod,
    required this.requiresReconciliation,
    required this.expiresAt,
    required this.serverTime,
    this.dropoffDeadline,
    required this.pickupName,
    required this.pickupAddress,
    required this.dropoffName,
    required this.dropoffAddress,
    required this.carrier,
    required this.origin,
    required this.destination,
    required List<ShipmentTimelineEntry> timeline,
  }) : timeline = List.unmodifiable(timeline);
  ShipmentStatus get status => ShipmentStatus.parse(rawStatus);
  bool get paid =>
      !requiresReconciliation &&
      status != ShipmentStatus.cancelled &&
      status != ShipmentStatus.unknown &&
      rawOrderStatus == 'DA_THANH_TOAN' &&
      const {'THANH_CONG', 'DA_THANH_TOAN'}.contains(rawPaymentStatus);
  bool get pendingOnline =>
      !requiresReconciliation &&
      status == ShipmentStatus.created &&
      paymentMethod == ShipmentPaymentMethod.online &&
      rawOrderStatus == 'CHO_THANH_TOAN' &&
      const {'DANG_XU_LY', 'CHO_THANH_TOAN'}.contains(rawPaymentStatus) &&
      amount > 0;

  ShipmentLookup copyWithTracking({
    required String status,
    String? paymentStatus,
    List<ShipmentTimelineEntry>? history,
  }) => ShipmentLookup(
    waybillCode: waybillCode,
    orderCode: orderCode,
    rawStatus: status,
    rawOrderStatus: status == 'DA_HUY' ? 'DA_HUY' : rawOrderStatus,
    rawPaymentStatus: paymentStatus ?? rawPaymentStatus,
    amount: amount,
    packageCount: packageCount,
    paymentMethod: paymentMethod,
    requiresReconciliation: requiresReconciliation,
    expiresAt: expiresAt,
    serverTime: serverTime,
    dropoffDeadline: dropoffDeadline,
    pickupName: pickupName,
    pickupAddress: pickupAddress,
    dropoffName: dropoffName,
    dropoffAddress: dropoffAddress,
    carrier: carrier,
    origin: origin,
    destination: destination,
    timeline: history ?? timeline,
  );
  factory ShipmentLookup.fromJson(Map<String, dynamic> j) {
    final pickup = shipmentMap(j['pickupPoint']),
        dropoff = shipmentMap(j['dropoffPoint']),
        route = shipmentMap(j['route']);
    return ShipmentLookup(
      waybillCode: cargoText(j['waybillCode']),
      orderCode: cargoText(j['orderCode']),
      rawStatus: cargoText(j['status']),
      rawOrderStatus: cargoText(j['orderStatus']),
      rawPaymentStatus: j['paymentStatus'] == null
          ? null
          : cargoText(j['paymentStatus']),
      amount: cargoInteger(j['amount']),
      packageCount: cargoInteger(j['packageCount']),
      paymentMethod: ShipmentPaymentMethod.parse(j['paymentMethod']),
      requiresReconciliation: j['requiresReconciliation'] != false,
      expiresAt: shipmentDate(j['paymentExpiresAt']),
      serverTime: shipmentDate(j['serverTime']),
      dropoffDeadline: j['dropoffDeadline'] == null
          ? null
          : shipmentDate(j['dropoffDeadline']),
      pickupName: cargoText(pickup['name']),
      pickupAddress: pickup['address'] as String,
      dropoffName: cargoText(dropoff['name']),
      dropoffAddress: dropoff['address'] as String,
      carrier: cargoText(shipmentMap(j['carrier'])['name']),
      origin: cargoText(route['origin']),
      destination: cargoText(route['destination']),
      timeline: shipmentList(j['timeline'], ShipmentTimelineEntry.fromJson),
    );
  }
}

class ShipmentPage {
  final List<ShipmentListEntry> records;
  final int page, pageSize, totalItems, totalPages;
  ShipmentPage({
    required List<ShipmentListEntry> records,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  }) : records = List.unmodifiable(records);
  factory ShipmentPage.fromJson(Map<String, dynamic> j) {
    final meta = shipmentMap(j['meta']);
    return ShipmentPage(
      records: shipmentList(j['data'], ShipmentListEntry.fromJson),
      page: cargoInteger(meta['page'], minimum: 1),
      pageSize: cargoInteger(meta['pageSize'], minimum: 1),
      totalItems: cargoInteger(meta['totalItems']),
      totalPages: cargoInteger(meta['totalPages']),
    );
  }
}

class ShipmentListEntry {
  final int shipmentId, totalFee, itemsCount;
  final String waybillCode,
      orderCode,
      rawStatus,
      rawPaymentStatus,
      senderName,
      senderPhone,
      receiverName,
      receiverPhone,
      route,
      carrier;
  final DateTime? dropoffDeadline;
  final DateTime sentAt;
  ShipmentListEntry.fromJson(Map<String, dynamic> j)
    : dropoffDeadline = j['dropoffDeadline'] == null
          ? null
          : shipmentDate(j['dropoffDeadline']),
      shipmentId = cargoInteger(j['shipmentId'], minimum: 1),
      totalFee = cargoInteger(j['totalFee']),
      itemsCount = cargoInteger(j['itemsCount']),
      waybillCode = cargoText(j['waybillCode']),
      orderCode = cargoText(j['orderCode']),
      rawStatus = cargoText(j['status']),
      rawPaymentStatus = cargoText(j['paymentStatus']),
      senderName = cargoText(shipmentMap(j['sender'])['fullName']),
      senderPhone = cargoText(shipmentMap(j['sender'])['phoneNumber']),
      receiverName = cargoText(shipmentMap(j['receiver'])['fullName']),
      receiverPhone = cargoText(shipmentMap(j['receiver'])['phoneNumber']),
      route = cargoText(shipmentMap(j['trip'])['route']),
      carrier = cargoText(shipmentMap(j['trip'])['busCompany']),
      sentAt = shipmentDate(j['sentAt']);
  ShipmentStatus get status => ShipmentStatus.parse(rawStatus);
}

class ShipmentCancellation {
  final String waybillCode;
  final DateTime updatedAt;
  final bool hasPaidBeforeCancel;
  final String message;
  const ShipmentCancellation({
    required this.waybillCode,
    required this.updatedAt,
    required this.hasPaidBeforeCancel,
    required this.message,
  });
  factory ShipmentCancellation.fromJson(Map<String, dynamic> json) {
    if (json['status'] != 'DA_HUY' || json['hasPaidBeforeCancel'] is! bool) {
      throw const FormatException('Chưa xác nhận kết quả hủy đơn gửi hàng.');
    }
    return ShipmentCancellation(
      waybillCode: cargoText(json['waybillCode']),
      updatedAt: shipmentDate(json['updatedAt']),
      hasPaidBeforeCancel: json['hasPaidBeforeCancel'] as bool,
      message: cargoText(json['message']),
    );
  }
}
