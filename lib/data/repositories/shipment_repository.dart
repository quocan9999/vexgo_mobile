import 'dart:convert';
import 'dart:math';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/token_storage.dart';
import '../models/booking_cargo_model.dart';
import '../models/shipment_model.dart';

abstract class ShipmentRepository {
  Future<List<ShipmentRoute>> searchRoutes({
    required String from,
    required String to,
    required String date,
    int page = 1,
  });
  Future<ShipmentOptions> loadOptions(int routeId);
  Future<ShipmentQuote> quote(ShipmentDraft draft);
  Future<ShipmentRecord> create(
    ShipmentDraft draft, {
    bool retryUncertain = false,
  });
  Future<ShipmentLookup> lookup({
    required String waybillCode,
    required String phone,
  });
  Future<ShipmentPage> listMine({
    int page = 1,
    int pageSize = 10,
    String search = '',
    ShipmentStatus? status,
  });
  Future<ShipmentRecord> detail(int id);
  Future<ShipmentCancellation> cancel({
    required String waybillCode,
    required String phone,
    String? reason,
  });
}

/// Standalone shipments only. Never POST /bookings or call an Admin endpoint.
class RealShipmentRepository implements ShipmentRepository {
  final ApiClient client;
  bool _creating = false;
  int? _uncertainSession;
  ShipmentDraft? _uncertainDraft;
  ShipmentIdentity? _uncertainIdentity;
  RealShipmentRepository({ApiClient? client}) : client = client ?? ApiClient();
  Map<String, dynamic> _data(Object? response) =>
      shipmentMap(shipmentMap(response)['data']);
  final Map<int, ShipmentRoute> _routes = {};
  final Map<int, String> _categoryNames = {};
  String? _requestKey, _requestPayload;
  int? _requestSession;
  String _key() => List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  @override
  Future<List<ShipmentRoute>> searchRoutes({
    required String from,
    required String to,
    required String date,
    int page = 1,
  }) async {
    if (from.trim().isEmpty ||
        to.trim().isEmpty ||
        from.trim() == to.trim() ||
        page < 1 ||
        !validShipmentSendDate(date)) {
      throw ArgumentError('Điểm gửi, điểm nhận hoặc ngày gửi chưa hợp lệ.');
    }
    final routes = <int, ShipmentRoute>{};
    var next = page;
    while (true) {
      final response = shipmentMap(
        await client.get(
          '/shipments/options',
          queryParams: {
            'from': from.trim(),
            'to': to.trim(),
            'sendDate': date,
            'page': next,
            'pageSize': 20,
          },
        ),
      );
      final rows = shipmentList(response['data'], ShipmentRoute.fromJson);
      for (final route in rows) {
        routes[route.id] = route;
      }
      final totalPages = cargoInteger(
        shipmentMap(response['meta'])['totalPages'],
      );
      if (next >= totalPages) break;
      if (rows.isEmpty) {
        throw const FormatException('Missing shipment option page');
      }
      next++;
    }
    _routes.addAll(routes);
    return List.unmodifiable(routes.values);
  }

  @override
  Future<ShipmentOptions> loadOptions(int routeId) async {
    if (routeId <= 0) throw ArgumentError('Invalid route');
    final values = await Future.wait([
      client.get('/shipments/categories'),
      client.get('/shipments/routes/$routeId/route-points'),
    ]);
    // Categories use a data array, route-points use a data object.
    final parsedCategories = shipmentList(
      shipmentMap(values[0])['data'],
      CargoCategory.fromJson,
    );
    _categoryNames.addEntries(
      parsedCategories.map((c) => MapEntry(c.id, c.name)),
    );
    final points = _data(values[1]);
    final senders = shipmentList(points['senderPoints'], CargoPoint.fromJson);
    final receivers = shipmentList(
      points['receiverPoints'],
      CargoPoint.fromJson,
    );
    if (parsedCategories.map((v) => v.id).toSet().length !=
            parsedCategories.length ||
        senders.map((v) => v.id).toSet().length != senders.length ||
        receivers.map((v) => v.id).toSet().length != receivers.length) {
      throw const FormatException('Duplicate shipment options');
    }
    return ShipmentOptions(
      routeId: routeId,
      categories: parsedCategories,
      senders: senders,
      receivers: receivers,
    );
  }

  @override
  Future<ShipmentQuote> quote(ShipmentDraft draft) async {
    final payload = draft.toJson();
    final data = _data(
      await client.post(
        '/shipments/quotes',
        optionalAuth: true,
        expectedSessionVersion: TokenStorage.sessionVersion,
        body: {
          for (final key in [
            'routeId',
            'sendDate',
            'senderPointId',
            'receiverPointId',
            'items',
          ])
            if (payload.containsKey(key)) key: payload[key],
        },
      ),
    );
    final result = ShipmentQuote.fromJson(data);
    final categories = draft.items.map((i) => i.categoryId).toSet();
    if (result.rates.any((r) => !categories.contains(r.categoryId)) ||
        !categories.every(
          (id) => result.rates.any((r) => r.categoryId == id),
        )) {
      throw const FormatException('Quote categories differ from draft');
    }
    return result;
  }

  bool _sameItems(ShipmentRecord record, ShipmentDraft draft) {
    String dimensions(double? l, double? w, double? h) =>
        l == null ? '' : '${l.toString()}x${w.toString()}x${h.toString()}';
    String normalizeDimensions(String? text) => text == null
        ? ''
        : text
              .replaceAll('cm', '')
              .split('x')
              .map((n) => double.parse(n).toString())
              .join('x');
    final sent = <String, int>{}, received = <String, int>{};
    for (final i in draft.items) {
      final key = jsonEncode([
        i.name.trim(),
        i.quantity,
        i.weight,
        _categoryNames[i.categoryId],
        dimensions(i.length, i.width, i.height),
      ]);
      sent[key] = (sent[key] ?? 0) + 1;
    }
    for (final i in record.items) {
      final key = jsonEncode([
        i.name,
        i.quantity,
        i.weight,
        i.category,
        normalizeDimensions(i.dimensions),
      ]);
      received[key] = (received[key] ?? 0) + 1;
    }
    return sent.length == received.length &&
        sent.entries.every((e) => received[e.key] == e.value);
  }

  bool _matches(ShipmentRecord record, ShipmentDraft draft) =>
      _sameItems(record, draft) &&
      _routes[draft.routeId] != null &&
      record.trip.origin == _routes[draft.routeId]!.origin &&
      record.trip.destination == _routes[draft.routeId]!.destination &&
      record.trip.carrier == _routes[draft.routeId]!.carrier &&
      record.expectedSendDate == draft.sendDate &&
      record.senderPointId == draft.senderPointId &&
      record.receiverPointId == draft.receiverPointId &&
      normalizeShipmentPhone(record.senderPhone) ==
          normalizeShipmentPhone(draft.senderPhone) &&
      normalizeShipmentPhone(record.receiverPhone) ==
          normalizeShipmentPhone(draft.receiverPhone) &&
      record.senderName == draft.senderName.trim() &&
      record.receiverName == draft.receiverName.trim() &&
      record.payer == draft.payer &&
      record.paymentMethod == draft.paymentMethod;
  @override
  Future<ShipmentRecord> create(
    ShipmentDraft draft, {
    bool retryUncertain = false,
  }) async {
    final payload = draft.toJson();
    final session = TokenStorage.sessionVersion;
    if (_creating) throw StateError('Đang tạo đơn gửi hàng.');
    final encoded = jsonEncode(payload);
    if (!_routes.containsKey(draft.routeId)) {
      throw StateError('Cần tải lại tuyến nhận hàng.');
    }
    if (_uncertainSession == session &&
        (!retryUncertain || _requestPayload != encoded)) {
      throw ShipmentCreationUncertain(identity: _uncertainIdentity);
    }
    if (_uncertainSession != session) {
      _uncertainSession = null;
      _uncertainIdentity = null;
      _uncertainDraft = null;
    }
    if (_requestSession != session || _requestPayload != encoded) {
      _requestSession = session;
      _requestPayload = encoded;
      _requestKey = _key();
    }
    _creating = true;
    try {
      final raw = await client.post(
        '/shipments',
        headers: {'Idempotency-Key': _requestKey!},
        body: payload,
        optionalAuth: true,
        expectedSessionVersion: session,
      );
      if (session != TokenStorage.sessionVersion) throw UnauthorizedException();
      ShipmentIdentity? identity;
      try {
        final data = _data(raw);
        try {
          identity = ShipmentIdentity.fromJson(data);
        } on FormatException {
          /* Keep unresolved. */
        }
        final record = ShipmentRecord.fromJson(data);
        if (!_matches(record, draft)) {
          throw const FormatException(
            'Shipment response does not match submission',
          );
        }
        _uncertainSession = null;
        _uncertainDraft = null;
        _uncertainIdentity = null;
        return record;
      } catch (_) {
        _uncertainSession = session;
        _uncertainDraft = draft;
        _uncertainIdentity = identity;
        throw ShipmentCreationUncertain(identity: identity);
      }
    } catch (e) {
      final rejected =
          e is ApiException &&
          e.statusCode >= 400 &&
          e.statusCode < 500 &&
          e.statusCode != 408 &&
          e.statusCode != 409;
      if (!rejected) {
        _uncertainSession = session;
        _uncertainDraft = draft;
      }
      rethrow;
    } finally {
      _creating = false;
    }
  }

  @override
  Future<ShipmentLookup> lookup({
    required String waybillCode,
    required String phone,
  }) async {
    if (waybillCode.trim().isEmpty || !validShipmentPhone(phone)) {
      throw ArgumentError('Nhập mã vận đơn và số điện thoại hợp lệ.');
    }
    final result = ShipmentLookup.fromJson(
      _data(
        await client.post(
          '/shipments/lookup',
          body: {
            'waybillCode': waybillCode.trim(),
            'phoneNumber': phone.trim(),
          },
        ),
      ),
    );
    if (result.waybillCode.toUpperCase() != waybillCode.trim().toUpperCase()) {
      throw const FormatException('Wrong waybill lookup');
    }
    return result;
  }

  @override
  Future<ShipmentPage> listMine({
    int page = 1,
    int pageSize = 10,
    String search = '',
    ShipmentStatus? status,
  }) async {
    if (page < 1 ||
        pageSize < 1 ||
        pageSize > 50 ||
        search.trim().length > 100 ||
        status == ShipmentStatus.unknown) {
      throw ArgumentError('Invalid shipment query');
    }
    return ShipmentPage.fromJson(
      shipmentMap(
        await client.get(
          '/shipments',
          requiresAuth: true,
          queryParams: {
            'page': page,
            'pageSize': pageSize,
            if (search.trim().isNotEmpty) 'search': search.trim(),
            if (status != null) 'status': status.code,
          },
        ),
      ),
    );
  }

  @override
  Future<ShipmentCancellation> cancel({
    required String waybillCode,
    required String phone,
    String? reason,
  }) async {
    final code = waybillCode.trim().toUpperCase();
    if (code.isEmpty ||
        !validShipmentPhone(phone) ||
        (reason?.trim().length ?? 0) > 255) {
      throw ArgumentError(
        'Mã vận đơn, số điện thoại hoặc lý do hủy không hợp lệ.',
      );
    }
    final result = ShipmentCancellation.fromJson(
      _data(
        await client.post(
          '/shipments/cancel',
          optionalAuth: true,
          body: {
            'waybillCode': code,
            'phoneNumber': phone.trim(),
            if (reason?.trim().isNotEmpty ?? false) 'reason': reason!.trim(),
          },
        ),
      ),
    );
    if (result.waybillCode.toUpperCase() != code) {
      throw const FormatException('Kết quả hủy thuộc vận đơn khác.');
    }
    return result;
  }

  @override
  Future<ShipmentRecord> detail(int id) async {
    if (id <= 0) throw ArgumentError('Invalid shipment ID');
    final session = TokenStorage.sessionVersion;
    final record = ShipmentRecord.fromJson(
      _data(await client.get('/shipments/$id', requiresAuth: true)),
    );
    if (record.identity.shipmentId != id) {
      throw const FormatException('Wrong shipment detail');
    }
    if (_uncertainSession == session &&
        _uncertainDraft != null &&
        _uncertainIdentity?.shipmentId == id) {
      if (!_matches(record, _uncertainDraft!)) {
        throw const FormatException(
          'Recovered shipment differs from submitted cargo',
        );
      }
      _uncertainSession = null;
      _uncertainDraft = null;
      _uncertainIdentity = null;
    }
    return record;
  }
}
