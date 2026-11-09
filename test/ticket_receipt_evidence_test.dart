import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/booking_evidence_model.dart';
import 'package:vexgo_app/data/models/booking_receipt_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_receipt_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart';
import 'package:vexgo_app/features/user/receipts/presentation/booking_receipt_screen.dart';
import 'booking_receipt_test.dart' show paidReceipt, DeferredReceiptRepository;
import 'review_contract_regression_test.dart' show flatTicket;

Map<String, dynamic> stop({int? offset = -35, int? lead = 15}) => {
  'tenDiem': 'Điểm đón đã đặt',
  'diaChi': 'Địa chỉ đã lưu 123',
  'soDienThoai': '0901234567',
  'phutLech': offset,
  'phutCoMatTruoc': lead,
  'phuPhi': 0,
  'maDiem': 'QA',
  'loaiDiem': 'DON',
  'diemDonTraChuyenXeId': 12,
  'benTrungChuyen': {
    'id': 99,
    'tenDiem': 'Bến trung chuyển QA',
    'diaChi': 'Địa chỉ trung chuyển QA',
  },
};
Map<String, dynamic> item() => {
  'name': 'Vali QA',
  'quantity': 2,
  'weight': 5.5,
  'category': 'HANG_NHE',
  'categoryName': 'Hành lý',
  'note': 'Ghi chú kiện hàng QA',
};
Map<String, dynamic> ticketJson() => {
  ...flatTicket(),
  'departureTime': '2026-11-06T17:15:00.000Z',
  'arrivalTime': '2026-11-07T00:15:00.000Z',
  'diemDonSnapshot': stop(),
  'diemTraSnapshot': {
    ...stop(offset: 420, lead: null),
    'tenDiem': 'Điểm trả đã đặt',
  },
  'price': 180000,
  'discountAmount': 20000,
  'originalTicketSubtotal': 380000,
  'ticketSubtotal': 360000,
  'promotionCode': 'QA20',
  'cargoFee': 50000,
  'cargoItems': [item()],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });
  tearDown(TokenStorage.resetStorageAdapter);
  test('negative stop offset and lead time cross date in Vietnam clock', () {
    final t = TicketModel.fromJson(ticketJson());
    expect(t.trip.departureTime, '00:15');
    expect(t.trip.departureDate, '07/11/2026');
    expect(t.pickupTimeLabel, '23:40');
    expect(t.dropoffTimeLabel, '07:15');
    expect(evidenceClock(t.pickupAt!), '23:40 06/11/2026');
    expect(
      evidenceClock(t.pickupSnapshot!.arriveBy(t.departureAt)!),
      '23:25 06/11/2026',
    );
    expect(evidenceClock(t.dropoffAt!), '07:15 07/11/2026');
    expect(t.trip.pickupAddress, 'Địa chỉ đã lưu 123');
    expect(t.pickupSnapshot!.transferName, 'Bến trung chuyển QA');
  });
  test('zero offset and zero lead are valid, not treated as absent', () {
    final t = TicketModel.fromJson({
      ...ticketJson(),
      'diemDonSnapshot': stop(offset: 0, lead: 0),
    });
    expect(t.pickupAt, t.departureAt);
    expect(t.pickupSnapshot!.arriveBy(t.departureAt), t.departureAt);
  });
  test('positive pickup offset rolls to next business date', () {
    final t = TicketModel.fromJson({
      ...ticketJson(),
      'departureTime': '2026-11-06T16:50:00Z',
      'diemDonSnapshot': stop(offset: 30, lead: 5),
    });
    expect(evidenceClock(t.pickupAt!), '00:20 07/11/2026');
    expect(
      evidenceClock(t.pickupSnapshot!.arriveBy(t.departureAt)!),
      '00:15 07/11/2026',
    );
  });
  test(
    'snapshot with unknown offset does not invent pickup time or arrival deadline',
    () {
      final t = TicketModel.fromJson({
        ...ticketJson(),
        'diemDonSnapshot': stop(offset: null),
      });
      expect(t.pickupAt, isNull);
      expect(t.pickupTimeLabel, '—');
      expect(t.pickupSnapshot!.arriveBy(t.departureAt), isNull);
    },
  );
  test('legacy ticket without snapshots retains supplied clock/address', () {
    final t = TicketModel.fromJson({
      ...flatTicket(),
      'pickupAddress': 'Địa chỉ cũ',
    });
    expect(t.pickupTimeLabel, t.trip.departureTime);
    expect(t.trip.pickupAddress, 'Địa chỉ cũ');
    expect(t.cargoFee, isNull);
    expect(t.cargoItems, isEmpty);
  });
  test(
    'serialization and status/review copies preserve snapshot, cargo, and order metadata',
    () {
      final t = TicketModel.fromJson(ticketJson());
      final copied = TicketModel.fromJson(
        t.copyWith(status: TicketStatus.cancelled, clearReview: true).toJson(),
      );
      expect(copied.pickupSnapshot, t.pickupSnapshot);
      expect(copied.dropoffSnapshot, t.dropoffSnapshot);
      expect(copied.departureAt, t.departureAt);
      expect(copied.cargoItems, t.cargoItems);
      expect(copied.cargoItems.single.weight, 5.5);
      expect(copied.cargoItems.single.note, 'Ghi chú kiện hàng QA');
      expect(copied.cargoFee, 50000);
      expect(copied.originalTicketSubtotal, 380000);
      expect(copied.ticketSubtotal, 360000);
      expect(copied.promotionCode, 'QA20');
    },
  );
  test(
    'multi-seat metadata does not add order cargo fee/discount to each ticket price',
    () {
      final first = TicketModel.fromJson(ticketJson());
      final second = TicketModel.fromJson({
        ...ticketJson(),
        'ticketId': 502,
        'seatNumber': 'A06',
      });
      expect(first.finalAmount, 180000);
      expect(second.finalAmount, 180000);
      expect(first.finalAmount + second.finalAmount, 360000);
      expect(first.cargoFee, 50000);
      expect(second.cargoFee, 50000);
      expect(
        first.discountAmount,
        20000,
      ); // Order metadata, not subtracted again.
    },
  );
  test('metadata changes participate in equality to refresh mounted views', () {
    final t = TicketModel.fromJson(ticketJson());
    expect(t, isNot(t.copyWith(cargoFee: 60000)));
    expect(
      t,
      isNot(t.copyWith(pickupSnapshot: StopSnapshot.parse(stop(offset: 5)))),
    );
  });
  for (final bad in [double.nan, double.infinity, -1, 'not-a-number']) {
    test('rejects malformed cargo weight $bad', () {
      expect(
        () => EvidenceCargo.fromJson({...item(), 'weight': bad}),
        throwsFormatException,
      );
    });
  }
  for (final patch in [
    {'phutLech': '35'},
    {'phutLech': 1.5},
    {'phutCoMatTruoc': -1},
    {'benTrungChuyen': 'bad'},
    {'diaChi': 123},
  ]) {
    test('rejects malformed stop metadata $patch', () {
      expect(
        () => StopSnapshot.parse({...stop(), ...patch}),
        throwsFormatException,
      );
    });
  }
  test(
    'receipt shares cargo/snapshot parsing and keeps server amounts unchanged',
    () {
      final r = BookingReceipt.fromJson({
        ...paidReceipt(),
        'diemDonSnapshot': stop(),
        'diemTraSnapshot': stop(offset: 420),
        'cargoItems': [item()],
      });
      expect(r.total, 520000);
      expect(r.cargoFee, 20000);
      expect(r.tickets.length, 2);
      expect(r.cargo.single.weight, 5.5);
      expect(r.cargo.single.categoryName, 'Hành lý');
      expect(r.pickup, 'Điểm đón đã đặt');
      expect(r.pickupSnapshot!.address, 'Địa chỉ đã lưu 123');
    },
  );
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets(
      'boarding pass shows full snapshot/cargo at $size and 2x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final t = TicketModel.fromJson(ticketJson());
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(child: BoardingPassCard(ticket: t)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('23:40 06/11/2026'), findsOneWidget);
        expect(find.textContaining('23:25 06/11/2026'), findsOneWidget);
        expect(find.textContaining('Địa chỉ đã lưu 123'), findsWidgets);
        expect(find.textContaining('Bến trung chuyển QA'), findsNWidgets(2));
        expect(find.text('2 × Vali QA'), findsOneWidget);
        expect(find.text('Khối lượng khai báo: 5,5 kg'), findsOneWidget);
        expect(find.text('Ghi chú: Ghi chú kiện hàng QA'), findsOneWidget);
        expect(
          find.textContaining('Cước vật phẩm (toàn đơn):'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  test('offset-qualified instants and unqualified business clocks agree', () {
    expect(
      evidenceInstant('2026-11-07T00:15:00+07:00'),
      evidenceInstant('2026-11-06T17:15:00Z'),
    );
    expect(
      evidenceInstant('2026-11-07T00:15:00'),
      evidenceInstant('2026-11-06T17:15:00Z'),
    );
    expect(evidenceInstant('not-a-time'), isNull);
  });
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets(
      'receipt renders stop/cargo at $size and 2x text; clears on account change',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = DeferredReceiptRepository();
        await tester.pumpWidget(
          RepositoryProvider<BookingReceiptRepository>.value(
            value: repo,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
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
        repo.calls.single.complete(
          BookingReceipt.fromJson({
            ...paidReceipt(),
            'diemDonSnapshot': stop(),
            'diemTraSnapshot': stop(offset: 420),
            'cargoItems': [item()],
          }),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('2 × Vali QA'),
          300,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 80,
        );
        await tester.pumpAndSettle();
        expect(find.text('2 × Vali QA'), findsOneWidget);
        expect(find.text('Khối lượng khai báo: 5,5 kg'), findsOneWidget);
        expect(find.textContaining('Địa chỉ đã lưu 123'), findsNWidgets(2));
        expect(find.textContaining('Ghi chú kiện hàng QA'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.runAsync(TokenStorage.clearTokens);
        await tester.pump();
        expect(find.textContaining('Ghi chú kiện hàng QA'), findsNothing);
        expect(find.textContaining('Địa chỉ đã lưu 123'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
