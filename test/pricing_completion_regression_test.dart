import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/booking_quote_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/voucher_model.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_5_trip_summary.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_6_payment.dart';

import 'booking_integrity_regression_test.dart'
    show CheckoutServer, ready, dispatch;

/// Current develop contract: quote money uses decimal strings and eligibility
/// depends on optional principal + contactPhone. A 0 VND create auto-settles.
class PricingServer extends CheckoutServer {
  int quotePosts = 0;
  int quoteUnit = 240000;
  bool quoteNetworkError = false;
  bool quoteMissingTotal = false;
  bool zeroUnsettled = false;
  bool eligibilityUnchecked = false;
  String? deniedPhone;
  final List<Map<String, dynamic>> quoteBodies = [];
  final List<String?> quoteAuthorization = [];
  final List<Completer<void>> quoteGates = [];
  String? committedCode;
  int committedTotal = 240000;

  int discountFor(String? code, int original) => code == 'FREE'
      ? original
      : code == 'SAVE25'
      ? 25000
      : 0;

  @override
  Map<String, dynamic> ticket(int id) => {
    ...super.ticket(id),
    'ticketCode': 'VXG-PDV-42-VE-01',
    'price': committedTotal,
    'status': committedTotal == 0 ? 'DA_THANH_TOAN' : 'DA_DAT',
    'bookingStatus': zeroUnsettled ? 'CHO_THANH_TOAN' : 'DA_THANH_TOAN',
    'paymentStatus': zeroUnsettled ? 'CHO_THANH_TOAN' : 'DA_THANH_TOAN',
  };

  @override
  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path.replaceFirst('/api/v1', '');
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(request.body) as Map<String, dynamic>;
    if (path == '/bookings/quote') {
      final index = quotePosts++;
      quoteBodies.add(Map.of(body));
      quoteAuthorization.add(request.headers['Authorization']);
      final code = body['promotionCode'] as String?;
      final phone = body['contactPhone'] as String?;
      final original = quoteUnit * (body['seatIds'] as List).length;
      final discount = discountFor(code, original);
      final failNetwork = quoteNetworkError;
      final missing = quoteMissingTotal;
      if (quoteGates.length > index) await quoteGates[index].future;
      if (failNetwork) throw const SocketException('quote offline');
      if (code == 'INVALID' || phone == deniedPhone) {
        return http.Response(
          jsonEncode({
            'error': 'PROMOTION_QUOTA_EXCEEDED',
            'message': 'Mã không hợp lệ hoặc số điện thoại đã sử dụng ưu đãi.',
          }),
          422,
        );
      }
      return http.Response(
        jsonEncode({
          'data': {
            'unitPrice': '$quoteUnit.00',
            'seatCount': (body['seatIds'] as List).length,
            'originalTotal': '$original.00',
            'discountAmount': '$discount.00',
            if (!missing) 'finalTotal': '${original - discount}.00',
            'currency': 'VND',
            'appliedPromotionCode': code,
            'identityChecked': !eligibilityUnchecked,
            'phoneEligibilityChecked': !eligibilityUnchecked,
            'requiresPhoneBeforeBooking': eligibilityUnchecked,
          },
        }),
        200,
      );
    }
    if (path == '/bookings/42/detail') {
      expect(request.headers['x-booking-code'], 'VXG-PDV-42');
      expect(request.headers['x-booking-phone'], isNotEmpty);
      return http.Response(jsonEncode({'data': bookingDetails()}), 200);
    }
    if (path == '/tickets/lookup') {
      expect(body['ticketCode'], 'VXG-PDV-42-VE-01');
      expect(body['phoneNumber'], isNotEmpty);
      ticketGets++;
      return http.Response(jsonEncode({'data': ticket(101)}), 200);
    }
    final response = await super.handle(request);
    if (response.statusCode != 200) return response;
    if (path == '/bookings' && request.method == 'POST') {
      committedCode = body['promotionCode'] as String?;
      committedTotal = quoteUnit - discountFor(committedCode, quoteUnit);
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>;
      data.addAll({
        'orderId': 72,
        'orderCode': 'VXG-DGD-72',
        'totalAmount': committedTotal,
        'status': committedTotal == 0 ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
        'paymentExpiresAt': now
            .add(const Duration(minutes: 15))
            .toIso8601String(),
        'tickets': [
          {
            'veId': 101,
            'maVe': 'VXG-PDV-42-VE-01',
            'price': committedTotal,
            'status': 'DA_DAT',
          },
        ],
      });
      return http.Response(jsonEncode(payload), 200);
    }
    if (path == '/payments' || path == '/payments/9/status') {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      (payload['data'] as Map<String, dynamic>)['amount'] = committedTotal;
      return http.Response(jsonEncode(payload), 200);
    }
    if (path == '/bookings/42') {
      return http.Response(jsonEncode({'data': bookingDetails()}), 200);
    }
    return response;
  }

  Map<String, dynamic> bookingDetails() => {
    'bookingId': 42,
    'bookingCode': 'VXG-PDV-42',
    'orderId': 72,
    'orderCode': 'VXG-DGD-72',
    'totalAmount': committedTotal,
    'contact': {
      'fullName': 'Nguyen Van An',
      'phone': '0901234567',
      'email': '',
    },
    'ticketCount': 1,
    'status': zeroUnsettled ? 'CHO_THANH_TOAN' : 'DA_THANH_TOAN',
    'paymentStatus': zeroUnsettled ? 'CHO_THANH_TOAN' : 'DA_THANH_TOAN',
    'expiresAt': now.add(const Duration(minutes: 15)).toIso8601String(),
    'tickets': [
      {
        'ticketId': 101,
        'ticketCode': 'VXG-PDV-42-VE-01',
        'seatNumber': 'A1',
        'price': committedTotal,
        'status': committedTotal == 0 ? 'DA_THANH_TOAN' : 'DA_DAT',
      },
    ],
  };
}

Future<void> summary(BookingFlowBloc bloc) async {
  await dispatch(
    bloc,
    const NextStepEvent(),
    (s) => s.step == BookingStep.dropoffPoint,
  );
  await dispatch(
    bloc,
    const NextStepEvent(),
    (s) => s.step == BookingStep.passengerInfo,
  );
  await dispatch(
    bloc,
    const NextStepEvent(),
    (s) => s.step == BookingStep.tripSummary && s.quote != null,
  );
}

Future<void> apply(BookingFlowBloc bloc, String code) => dispatch(
  bloc,
  ApplyPromotionCodeEvent(code),
  (s) => !s.quoteLoading && s.quote != null && s.requestedPromotionCode == code,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'fixture-user');
  });
  tearDown(() async {
    await TokenStorage.clearTokens();
    TokenStorage.resetStorageAdapter();
  });

  test('decimal-string quote parses exact VND and identity eligibility', () {
    final quote = BookingQuoteModel.fromJson({
      'unitPrice': '240000.00',
      'seatCount': 1,
      'originalTotal': '240000.00',
      'discountAmount': '240000.00',
      'finalTotal': '0.00',
      'identityChecked': true,
      'phoneEligibilityChecked': true,
      'requiresPhoneBeforeBooking': false,
    });
    expect(quote.finalTotal, 0);
    expect(quote.identityChecked, isTrue);
    for (final invalid in [null, '-1.00', 'NaN', '0.50', '100.00']) {
      expect(
        () => BookingQuoteModel.fromJson({
          'unitPrice': '240000.00',
          'seatCount': 1,
          'originalTotal': '240000.00',
          'discountAmount': '240000.00',
          'finalTotal': invalid,
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'quote sends optional principal and exact contact phone; summary replaces seat estimate',
    () async {
      final server = PricingServer();
      final bloc = await ready(server);
      addTearDown(bloc.close);
      await summary(bloc);
      expect(server.quoteBodies.single['contactPhone'], '0901234567');
      expect(server.quoteAuthorization.single, 'Bearer fixture-user');
      expect(bloc.state.seatsTotalAmount, 200000);
      expect(bloc.state.finalAmount, 240000);
      expect(bloc.state.quotedSubtotal, 240000);
      expect(bloc.state.canProceed, isTrue);
      await TokenStorage.clearTokens();
      await apply(bloc, 'SAVE25');
      expect(server.quoteAuthorization.last, isNull);
      expect(server.quoteBodies.last['contactPhone'], '0901234567');
      expect(bloc.state.discountAmount, 25000);
      expect(bloc.state.finalAmount, 215000);
    },
  );

  test(
    'real ApplyVoucher uses server validation instead of untrusted local discount',
    () async {
      final server = PricingServer();
      final bloc = await ready(server);
      addTearDown(bloc.close);
      const forgedVoucher = VoucherModel(
        code: 'SAVE25',
        title: 'fake',
        description: '',
        discountAmount: 99999999,
        discountPercent: 100,
        minOrderAmount: 0,
        expiryDate: '2099',
        isApplicable: true,
      );
      await dispatch(
        bloc,
        const ApplyVoucherEvent(forgedVoucher),
        (s) => s.quote != null,
      );
      expect(bloc.state.discountAmount, 25000);
      expect(bloc.state.finalAmount, 215000);
      expect(server.quoteBodies.single['promotionCode'], 'SAVE25');
    },
  );

  for (final malformed in [false, true]) {
    test(
      'quote ${malformed ? 'malformed total' : 'timeout'} prevents booking and remains retryable',
      () async {
        final server = PricingServer();
        server.quoteMissingTotal = malformed;
        server.quoteNetworkError = !malformed;
        final bloc = await ready(server);
        addTearDown(bloc.close);
        await dispatch(
          bloc,
          const ConfirmPaymentEvent(),
          (s) => s.quoteError != null,
        );
        expect(server.bookingPosts, 0);
        expect(bloc.state.finalAmount, isNull);
        expect(bloc.state.bookingOutcomeUnknown, isFalse);
        server.quoteMissingTotal = server.quoteNetworkError = false;
        await dispatch(
          bloc,
          const RefreshBookingQuoteEvent(),
          (s) => s.quote != null,
        );
        expect(bloc.state.finalAmount, 240000);
      },
    );
  }

  test(
    'invalid promotion does not leave previous price or allow checkout',
    () async {
      final server = PricingServer();
      final bloc = await ready(server);
      addTearDown(bloc.close);
      await summary(bloc);
      await dispatch(
        bloc,
        const ApplyPromotionCodeEvent('INVALID'),
        (s) => s.quoteError != null,
      );
      expect(bloc.state.quote, isNull);
      expect(bloc.state.appliedVoucher, isNull);
      expect(bloc.state.canProceed, isFalse);
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.quoteError != null && !s.quoteLoading,
      );
      expect(server.bookingPosts, 0);
      await dispatch(bloc, const RemoveVoucherEvent(), (s) => s.quote != null);
      expect(bloc.state.finalAmount, 240000);
    },
  );

  test(
    'contact change revalidates guest eligibility and rejects phone quota',
    () async {
      final server = PricingServer()..deniedPhone = '0909999999';
      final bloc = await ready(server);
      addTearDown(bloc.close);
      await summary(bloc);
      await apply(bloc, 'SAVE25');
      await dispatch(
        bloc,
        const UpdatePassengerInfoEvent(
          name: 'Nguyen Van An',
          phone: '0909999999',
          email: '',
        ),
        (s) => s.quoteError != null,
      );
      expect(server.quoteBodies.last['contactPhone'], '0909999999');
      expect(bloc.state.quote, isNull);
      expect(bloc.state.discountAmount, 0);
      expect(bloc.state.canProceed, isFalse);
      expect(server.bookingPosts, 0);
    },
  );

  test('late quote cannot overwrite a newer contact quote', () async {
    final server = PricingServer();
    final bloc = await ready(server);
    addTearDown(bloc.close);
    await summary(bloc);
    final old = Completer<void>();
    server.quoteGates.addAll([Completer<void>()..complete(), old]);
    bloc.add(const ApplyPromotionCodeEvent('SAVE25'));
    await bloc.stream.firstWhere((s) => s.quoteLoading);
    await dispatch(
      bloc,
      const UpdatePassengerInfoEvent(
        name: 'Another Passenger',
        phone: '0909999999',
        email: '',
      ),
      (s) =>
          s.quote != null &&
          !s.quoteLoading &&
          s.passengerPhone == '0909999999',
    );
    final accepted = bloc.state.quote;
    old.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.quote, same(accepted));
    expect(server.quotePosts, 3);
    expect(server.bookingPosts, 0);
  });

  test(
    'duplicate quote/Confirm clicks during request never submit a transaction',
    () async {
      final server = PricingServer();
      final gate = Completer<void>();
      server.quoteGates.add(gate);
      final bloc = await ready(server);
      addTearDown(bloc.close);
      bloc.add(const ApplyPromotionCodeEvent('FREE'));
      await bloc.stream.firstWhere((s) => s.quoteLoading);
      bloc.add(const ApplyPromotionCodeEvent('FREE'));
      bloc.add(const RefreshBookingQuoteEvent());
      bloc.add(const ConfirmPaymentEvent());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(server.quotePosts, 1);
      expect(server.bookingPosts, 0);
      gate.complete();
      await bloc.stream.firstWhere((s) => s.quote != null);
      expect(bloc.state.finalAmount, 0);
      final done = bloc.stream.firstWhere(
        (s) => s.status == BookingFlowStatus.success,
      );
      bloc.add(const ConfirmPaymentEvent());
      bloc.add(const ConfirmPaymentEvent());
      await done;
      expect(server.bookingPosts, 1);
      expect(server.paymentPosts, 0);
    },
  );

  test(
    'guest 100% promotion settles 0 VND without payment gateway and hydrates a real ticket',
    () async {
      await TokenStorage.clearTokens();
      final server = PricingServer();
      final bloc = await ready(server);
      addTearDown(bloc.close);
      await apply(bloc, 'FREE');
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.success,
      );
      expect(server.bookingPosts, 1);
      expect(server.paymentPosts, 0);
      expect(server.statusGets, 0);
      expect(server.ticketGets, 1);
      expect(bloc.state.createdTicket!.ticketCode, 'VXG-PDV-42-VE-01');
      expect(bloc.state.createdTicket!.finalAmount, 0);
      expect(bloc.state.createdTicket!.canShowQr, isTrue);
    },
  );

  test(
    '0 VND without authoritative settlement cannot produce ticket or payment request',
    () async {
      final server = PricingServer()..zeroUnsettled = true;
      final bloc = await ready(server);
      addTearDown(bloc.close);
      await apply(bloc, 'FREE');
      await dispatch(
        bloc,
        const ConfirmPaymentEvent(),
        (s) => s.status == BookingFlowStatus.failure,
      );
      expect(server.paymentPosts, 0);
      expect(bloc.state.createdTicket, isNull);
      expect(bloc.state.pendingBookingId, 42);
      expect(bloc.state.pendingQrCodeUrl, isNull);
    },
  );

  test(
    'legacy repository 0 VND create also skips unsupported provider payment',
    () async {
      final server = PricingServer();
      final ticket = await server.real.createBooking(
        trip: const TicketTripSummary(
          id: '101',
          operatorName: 'Nha xe',
          vehicleType: 'Limousine',
          departureTime: '08:00',
          departureDate: '01/11/2026',
          arrivalTime: '14:00',
          arrivalDate: '01/11/2026',
          fromCity: 'Ho Chi Minh',
          toCity: 'Da Lat',
          pickupPoint: 'Ben xe',
          pickupAddress: '',
          dropoffPoint: 'Da Lat',
          dropoffAddress: '',
        ),
        seats: ['A1'],
        seatIds: [1],
        holdToken: 'fixture-hold',
        promotionCode: 'FREE',
        totalAmount: 1,
        discountAmount: 0,
        finalAmount: 1,
        paymentMethod: 'momo',
        passenger: const PassengerInfo(
          fullName: 'Nguyen Van An',
          phone: '0901234567',
          email: '',
        ),
      );
      expect(ticket.finalAmount, 0);
      expect(ticket.canShowQr, isTrue);
      expect(server.paymentPosts, 0);
    },
  );

  test('promotion without checked identity fails closed', () async {
    final server = PricingServer()..eligibilityUnchecked = true;
    final bloc = await ready(server);
    addTearDown(bloc.close);
    await dispatch(
      bloc,
      const ApplyPromotionCodeEvent('FREE'),
      (s) => s.quoteError != null,
    );
    expect(bloc.state.finalAmount, isNull);
    expect(server.bookingPosts, 0);
  });

  testWidgets('summary accepts a real code despite empty voucher catalogue', (
    tester,
  ) async {
    final server = PricingServer();
    final bloc = (await tester.runAsync(() => ready(server)))!;
    await tester.runAsync(() => summary(bloc));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step5TripSummary(state: bloc.state, bloc: bloc),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Chọn hoặc nhập mã khuyến mãi'));
    await tester.tap(find.text('Chọn hoặc nhập mã khuyến mãi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'FREE');
    await tester.tap(find.text('Kiểm tra mã'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => bloc.stream
          .firstWhere(
            (s) => s.quote != null && s.requestedPromotionCode == 'FREE',
          )
          .timeout(const Duration(seconds: 3)),
    );
    expect(bloc.state.requestedPromotionCode, 'FREE');
    expect(bloc.state.finalAmount, 0);
    await tester.runAsync(bloc.close);
  });

  testWidgets(
    'pending checkout shows actual booking and ticket codes for guest recovery',
    (tester) async {
      final server = PricingServer();
      final bloc = (await tester.runAsync(() => ready(server)))!;
      await tester.runAsync(
        () => dispatch(
          bloc,
          const ConfirmPaymentEvent(),
          (s) => s.status == BookingFlowStatus.paymentPending,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Step6Payment(state: bloc.state, bloc: bloc),
          ),
        ),
      );
      expect(find.text('Mã đặt vé: VXG-PDV-42'), findsOneWidget);
      expect(find.text('Mã vé: VXG-PDV-42-VE-01'), findsOneWidget);
      expect(find.textContaining('tra cứu bằng số điện thoại'), findsOneWidget);
      expect(bloc.state.createdTicket, isNull);
      await tester.runAsync(bloc.close);
    },
  );
}
