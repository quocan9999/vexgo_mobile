import 'package:vexgo_app/features/user/booking/presentation/widgets/payment_display_state.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/booking_model.dart';
import 'package:vexgo_app/data/models/booking_receipt_model.dart';
import 'package:vexgo_app/data/models/booking_cargo_model.dart';
import 'package:vexgo_app/data/models/cargo_settlement.dart';
import 'package:vexgo_app/data/repositories/booking_receipt_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/receipts/presentation/booking_receipt_screen.dart';
import 'booking_cargo_core_test.dart' as cargo;
import 'round_trip_core_test.dart' as core;
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'booking_receipt_test.dart' show paidReceipt, DeferredReceiptRepository;

class FreeTicketServer extends cargo.CargoServer {
  @override
  Future<http.Response> handle(http.Request req) async {
    if (req.url.path.endsWith('/bookings/quote')) {
      return response({
        'unitPrice': '190000',
        'seatCount': 1,
        'originalTotal': '190000',
        'discountAmount': '190000',
        'finalTotal': '0',
        'currency': 'VND',
        'identityChecked': true,
        'phoneEligibilityChecked': true,
        'requiresPhoneBeforeBooking': false,
        'appliedPromotionCode': 'FREE',
      });
    }
    final res = await super.handle(req);
    if (req.method == 'POST' &&
        req.url.path.endsWith('/bookings') &&
        res.statusCode < 400) {
      final data =
          (jsonDecode(res.body) as Map)['data'] as Map<String, dynamic>;
      final id = data['bookingId'] as int;
      data.addAll({
        'totalAmount': 0,
        'ticketSubtotal': 0,
        'discountAmount': 190000,
        'status': 'DA_THANH_TOAN',
        'paymentStatus': 'DA_THANH_TOAN',
      });
      orders[id] = data;
      paid.add(id);
      return response(data);
    }
    if (req.url.path.contains('/tickets/')) {
      final data =
          (jsonDecode(res.body) as Map)['data'] as Map<String, dynamic>;
      data['price'] = 0;
      return response(data);
    }
    return res;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    ApiConfig.isDemoMode = false;
    GoogleFonts.config.allowRuntimeFetching = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'fixture-counter-owner');
  });
  tearDown(TokenStorage.resetStorageAdapter);
  test('new and legacy order totals select the proper collection method', () {
    final base = {
      'bookingId': 1,
      'ticketSubtotal': 190000,
      'shippingFee': 50000,
      'originalTicketSubtotal': 200000,
      'discountAmount': 10000,
    };
    final current = BookingModel.fromJson({...base, 'totalAmount': 190000});
    final legacy = BookingModel.fromJson({...base, 'totalAmount': 240000});
    expect(current.cargoPayment, CargoSettlement.atStation);
    expect(current.totalAmount, 190000);
    expect(legacy.cargoPayment, CargoSettlement.includedOnline);
    expect(legacy.totalAmount, 240000);
    expect(
      BookingModel.fromJson(legacy.toJson()).cargoPayment,
      CargoSettlement.includedOnline,
    );
    expect(
      () => BookingModel.fromJson({...base, 'totalAmount': 210000}),
      throwsFormatException,
    );
  });
  test(
    'missing payment metadata remains unknown and does not assume station collection',
    () {
      final b = BookingModel.fromJson({
        'bookingId': 1,
        'totalAmount': 190000,
        'cargoFee': 50000,
      });
      expect(b.cargoPayment, CargoSettlement.unknown);
    },
  );
  test(
    'positive cargo estimate with zero ticket total never requires online cargo payment',
    () async {
      final s = FreeTicketServer();
      final f = await cargo.oneWay(s);
      addTearDown(f.close);
      await f.applyDraftAction(const SetBookingCargoEnabledEvent(true));
      await f.applyDraftAction(UpdateBookingCargoEvent(cargo.draft(101)));
      await f.applyDraftAction(const ApplyPromotionCodeEvent('FREE'));
      expect(f.state.ticketFinalAmount, 0);
      expect(f.state.finalAmount, 0);
      await f.confirmPayment();
      expect(f.state.checkoutBooking?.totalAmount, 0);
      expect(f.state.checkoutBooking?.shippingFee, 50000);
      expect(f.state.checkoutBooking?.cargoPayment, CargoSettlement.atStation);
      expect(s.calls.where((p) => p == 'POST /payments'), isEmpty);
      expect(f.state.status, BookingFlowStatus.success);
      expect(f.state.canDisplayBankTransfer(s.now), isFalse);
    },
  );
  test(
    'old-server included fee response retains recovery ID but exposes no QR for a new draft',
    () async {
      final s = cargo.CargoServer()..legacyIncluded = true;
      final f = await cargo.oneWay(s);
      addTearDown(f.close);
      await f.applyDraftAction(const SetBookingCargoEnabledEvent(true));
      await f.applyDraftAction(UpdateBookingCargoEvent(cargo.draft(101)));
      await f.confirmPayment();
      expect(f.state.pendingBookingId, 1001);
      expect(f.state.bookingOutcomeUnknown, isFalse);
      expect(f.state.status, BookingFlowStatus.failure);
      expect(f.state.canDisplayBankTransfer(s.now), isFalse);
      await f.confirmPayment();
      expect(s.posts.length, 1);
    },
  );
  test(
    'combo QR combines only online ticket totals while keeping distinct station estimates',
    () async {
      final s = cargo.CargoServer();
      final c = s.checkout();
      addTearDown(c.close);
      await core.ready(c);
      await cargo.enable(c, TripLeg.outbound, 101);
      await cargo.enable(c, TripLeg.inbound, 102);
      expect(c.state.totalAmount, 450000);
      await c.submit();
      expect(c.state.comboAmount, 450000);
      expect(c.state.outbound.checkoutBooking?.shippingFee, 50000);
      expect(c.state.inbound.checkoutBooking?.shippingFee, 80000);
      expect(c.state.canDisplayCombo(s.now), isTrue);
    },
  );
  test(
    'explicit category, not suitcase weight, determines capacity group',
    () async {
      final s = cargo.CargoServer();
      final opts = await s.cargo.loadOptions(101);
      final heavy = cargo.parcel(weight: 25);
      expect(heavy.group, CargoGroup.parcel);
      expect(opts.validate(cargo.draft(101, items: [heavy])), isNull);
      final explicitBulky = CargoItemDraft(
        name: 'Bulky',
        kind: CargoKind.bulky,
        categoryId: 3,
        weight: 25,
      );
      expect(
        opts.validate(cargo.draft(101, items: [explicitBulky])),
        isNotNull,
      );
    },
  );
  for (final legacy in [false, true]) {
    testWidgets(
      '${legacy ? 'legacy' : 'current'} receipt explains cargo collection without changing paid amount',
      (tester) async {
        final repo = DeferredReceiptRepository();
        await tester.pumpWidget(
          RepositoryProvider<BookingReceiptRepository>.value(
            value: repo,
            child: MaterialApp(
              home: BookingReceiptScreen(
                initialRequest: ReceiptLookupRequest(
                  'QA-VE-01',
                  '0901234567',
                  TokenStorage.sessionVersion,
                ),
              ),
            ),
          ),
        );
        final json = paidReceipt();
        if (!legacy) json['totalAmount'] = 500000;
        final receipt = BookingReceipt.fromJson(json);
        repo.calls.single.complete(receipt);
        await tester.pumpAndSettle();
        final label = cargoSettlementLabel(receipt.cargoPayment);
        await tester.scrollUntilVisible(
          find.text(label),
          300,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        expect(find.text(label), findsOneWidget);
        expect(
          receipt.cargoPayment,
          legacy ? CargoSettlement.includedOnline : CargoSettlement.atStation,
        );
        expect(receipt.total, legacy ? 520000 : 500000);
        expect(
          find.text(cargoSettlementDescription(receipt.cargoPayment)),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
