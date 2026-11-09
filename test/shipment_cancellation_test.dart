import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/features/user/shipments/shipment_flow_cubit.dart';
import 'package:vexgo_app/features/user/shipments/presentation/widgets/shipment_cancellation_section.dart';
import 'standalone_shipments_core_test.dart' as fixture;

class CancelServer extends fixture.Server {
  int cancels = 0;
  bool paid = false,
      lose = false,
      wrong = false,
      conflict = false,
      linked = false;
  Completer<void>? gate;
  @override
  Future<http.Response> handle(http.Request r) async {
    final path = r.url.path.replaceFirst('/api/v1', '');
    if (path == '/shipments/cancel') {
      requests.add(r);
      cancels++;
      await gate?.future;
      if (linked) {
        return fixture.response({
          'message': 'Hành lý đi kèm vé cần liên hệ nhà xe',
          'error': 'BOOKING_SHIPMENT_TRIP_FIXED',
        }, 409);
      }
      if (conflict) {
        result['status'] = 'DA_TIEP_NHAN';
        return fixture.response({
          'message': 'Hàng đã được tiếp nhận',
          'error': 'SHIPMENT_CANNOT_BE_CANCELLED_ONLINE',
        }, 409);
      }
      result['status'] = 'DA_HUY';
      if (lose) throw const SocketException('response lost after commit');
      return fixture.response({
        'data': {
          'waybillCode': wrong ? 'OTHER-ORDER' : 'WAY-50',
          'status': 'DA_HUY',
          'updatedAt': fixture.time.toIso8601String(),
          'hasPaidBeforeCancel': paid,
          'message': 'Đã hủy',
        },
      });
    }
    if (path == '/shipments/lookup') {
      requests.add(r);
      return fixture.response({
        'data': {
          ...fixture.lookupJson(method: 'TAI_BEN'),
          'status': result['status'],
          'orderStatus': result['status'] == 'DA_HUY'
              ? 'DA_HUY'
              : 'CHO_THANH_TOAN',
        },
      });
    }
    return super.handle(r);
  }
}

Future<ShipmentFlowCubit> opened(CancelServer s) async {
  final c = ShipmentFlowCubit(
    repository: s.repository,
    now: () => fixture.time,
  );
  await c.openDetail(50);
  return c;
}

Widget host(ShipmentFlowCubit c, {bool fromLookup = false, double scale = 1}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlocBuilder<ShipmentFlowCubit, ShipmentFlowState>(
            bloc: c,
            builder: (_, state) => ShipmentCancellationSection(
              cubit: c,
              state: state,
              fromLookup: fromLookup,
            ),
          ),
        ),
      ),
    );
void main() {
  setUp(() async {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'cancel-fixture-owner');
  });
  tearDown(TokenStorage.resetStorageAdapter);
  test(
    'confirmed cancellation updates detail and sends only public customer endpoint',
    () async {
      final s = CancelServer();
      final c = await opened(s);
      addTearDown(c.close);
      await c.cancelShipment(reason: 'Đặt nhầm');
      expect(c.state.record!.status, ShipmentStatus.cancelled);
      expect(s.cancels, 1);
      expect(c.canCancelShipment(), isFalse);
      final req = s.requests.singleWhere((r) => r.url.path.endsWith('/cancel'));
      expect(jsonDecode(req.body), {
        'waybillCode': 'WAY-50',
        'phoneNumber': '+84901234567',
        'reason': 'Đặt nhầm',
      });
      expect(s.requests.any((r) => r.url.path.contains('/admin')), isFalse);
    },
  );
  test(
    'public receiver lookup cancels using the verified phone even after UI input changes',
    () async {
      final s = CancelServer();
      final c = ShipmentFlowCubit(repository: s.repository);
      addTearDown(c.close);
      await c.lookup(waybillCode: 'WAY-50', phone: '0907654321');
      await c.cancelShipment(fromLookup: true);
      expect(
        jsonDecode(
          s.requests.singleWhere((r) => r.url.path.endsWith('/cancel')).body,
        )['phoneNumber'],
        '0907654321',
      );
      expect(c.state.lookup!.status, ShipmentStatus.cancelled);
    },
  );
  test('accepted and unknown statuses cannot send a cancellation', () async {
    for (final status in [
      'DA_TIEP_NHAN',
      'DANG_VAN_CHUYEN',
      'DA_GIAO',
      'DA_HUY',
      'FUTURE_STATUS',
    ]) {
      final s = CancelServer()..result['status'] = status;
      final c = await opened(s);
      await c.cancelShipment();
      expect(s.cancels, 0);
      await c.close();
    }
  });
  test(
    'booking-linked shipment rejection blocks repeated standalone cancellation',
    () async {
      final s = CancelServer()..linked = true;
      final c = await opened(s);
      addTearDown(c.close);
      await c.cancelShipment();
      expect(c.state.record!.status, ShipmentStatus.created);
      expect(c.canCancelShipment(), isFalse);
      await c.cancelShipment();
      expect(s.cancels, 1);
    },
  );
  test('single flight blocks double tap and detail navigation', () async {
    final s = CancelServer()..gate = Completer<void>();
    final c = await opened(s);
    addTearDown(c.close);
    final task = c.cancelShipment();
    await Future<void>.delayed(Duration.zero);
    await c.cancelShipment();
    await c.openDetail(51);
    expect(s.cancels, 1);
    s.gate!.complete();
    await task;
    expect(c.state.record!.status, ShipmentStatus.cancelled);
  });
  test(
    'lost response locks retry; read-only lookup recovers authoritative cancelled status',
    () async {
      final s = CancelServer()..lose = true;
      final c = await opened(s);
      addTearDown(c.close);
      await c.cancelShipment();
      expect(c.state.cancellationUncertain, isTrue);
      await c.cancelShipment();
      expect(s.cancels, 1);
      await c.refreshCancellationStatus();
      expect(c.state.record!.status, ShipmentStatus.cancelled);
      expect(c.state.cancellationUncertain, isFalse);
      expect(s.cancels, 1);
    },
  );
  test(
    'wrong acknowledgement never claims success and keeps recovery available',
    () async {
      final s = CancelServer()..wrong = true;
      final c = await opened(s);
      addTearDown(c.close);
      await c.cancelShipment();
      expect(c.state.record!.status, ShipmentStatus.created);
      expect(c.state.cancellation, isNull);
      expect(c.state.cancellationUncertain, isTrue);
    },
  );
  test('conflict reloads status and removes stale cancel action', () async {
    final s = CancelServer()..conflict = true;
    final c = await opened(s);
    addTearDown(c.close);
    await c.cancelShipment();
    expect(c.state.record!.status, ShipmentStatus.accepted);
    expect(c.canCancelShipment(), isFalse);
    expect(c.state.cancellation, isNull);
  });
  test(
    'late acknowledgement cannot restore data after account switch',
    () async {
      final s = CancelServer()..gate = Completer<void>();
      final c = await opened(s);
      addTearDown(c.close);
      final task = c.cancelShipment();
      await Future<void>.delayed(Duration.zero);
      await TokenStorage.clearTokens();
      s.gate!.complete();
      await task;
      expect(c.state.phase, ShipmentCreationPhase.invalidated);
      expect(c.state.record, isNull);
      expect(c.state.cancellation, isNull);
    },
  );
  test('reason beyond 255 chars is rejected before POST', () async {
    final s = CancelServer();
    final c = await opened(s);
    addTearDown(c.close);
    await c.cancelShipment(reason: 'x' * 256);
    expect(s.cancels, 0);
    expect(c.state.cancellationError, isNotNull);
  });
  testWidgets(
    'confirmation can keep order; confirmed paid cancellation shows support guidance',
    (t) async {
      final s = CancelServer()..paid = true;
      late ShipmentFlowCubit c;
      await t.runAsync(() async {
        c = await opened(s);
      });
      addTearDown(c.close);
      await t.pumpWidget(host(c));
      await t.tap(find.byKey(const ValueKey('shipment-detail-cancel')));
      await t.pumpAndSettle();
      await t.tap(find.text('Giữ đơn'));
      await t.pumpAndSettle();
      expect(s.cancels, 0);
      await t.tap(find.byKey(const ValueKey('shipment-detail-cancel')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('shipment-cancel-confirm')));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await t.pumpAndSettle();
      expect(c.state.record!.status, ShipmentStatus.cancelled);
      expect(find.textContaining('liên hệ nhà xe'), findsOneWidget);
    },
  );
  testWidgets(
    'open cancellation dialog removes old content after session changes',
    (t) async {
      final s = CancelServer();
      late ShipmentFlowCubit c;
      await t.runAsync(() async {
        c = await opened(s);
      });
      addTearDown(c.close);
      await t.pumpWidget(host(c));
      await t.tap(find.byKey(const ValueKey('shipment-detail-cancel')));
      await t.pumpAndSettle();
      await t.runAsync(TokenStorage.clearTokens);
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('shipment-cancel-confirm')),
        findsNothing,
      );
      expect(find.textContaining('WAY-50'), findsNothing);
      expect(s.cancels, 0);
    },
  );
  testWidgets('confirmation scrolls with large text and landscape keyboard', (
    t,
  ) async {
    t.view.physicalSize = const Size(640, 360);
    t.view.devicePixelRatio = 1;
    t.view.viewInsets = const FakeViewPadding(bottom: 150);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    final s = CancelServer();
    late ShipmentFlowCubit c;
    await t.runAsync(() async {
      c = await opened(s);
    });
    addTearDown(c.close);
    await t.pumpWidget(host(c, scale: 2));
    await t.tap(find.byKey(const ValueKey('shipment-detail-cancel')));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.ensureVisible(
      find.byKey(const ValueKey('shipment-cancel-confirm')),
    );
    expect(t.takeException(), isNull);
  });
}
