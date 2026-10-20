import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/ticket_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/ticket_read_cubit.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/screens/ticket_detail_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/screens/my_tickets_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/guest_ticket_lookup_panel.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/ticket_qr_modal.dart';
import 'package:vexgo_app/features/user/search_trips/bloc/trip_detail_cubit.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_detail_sheet.dart';
import 'qa/qa_fixtures.dart';

// Contract-shaped HTTP fixtures and isolated repository/UI components. No live
// account, seat hold, booking, cancellation, or payment is created by these tests.
http.Response jsonResponse(Object json, [int status = 200]) => http.Response(
  jsonEncode(json),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Future<void> tick() => Future<void>.delayed(Duration.zero);
TripModel trip({
  int id = 101,
  String operator = 'Fresh operator',
  int price = 320000,
}) => TripModel.fromJson({
  ...qaTrip.toJson(),
  'id': id.toString(),
  'tripId': id,
  'busCompanyName': operator,
  'operatorName': operator,
  'discountPrice': price,
});
TicketModel ticket({String status = 'DA_THANH_TOAN', bool paid = true}) =>
    TicketModel.fromJson({
      ...qaTicketJson(),
      'status': status,
      'bookingStatus': paid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
      'paymentStatus': paid ? 'DA_THANH_TOAN' : 'CHO_THANH_TOAN',
    });

class ReadBookingRepository extends MockBookingRepository {
  final details = <Completer<TicketModel?>>[];
  final lookups = <Completer<TicketModel?>>[];
  final lookupArguments = <Map<String, String>>[];
  @override
  Future<List<TicketModel>> getMyTickets() async => [];
  @override
  Future<TicketModel?> getTicketById(String id) {
    final request = Completer<TicketModel?>();
    details.add(request);
    return request.future;
  }

  @override
  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) {
    lookupArguments.add({'ticketCode': ticketCode, 'phoneNumber': phoneNumber});
    final request = Completer<TicketModel?>();
    lookups.add(request);
    return request.future;
  }
}

class ReadTripRepository extends MockTripRepository {
  final reads = <Completer<TripModel?>>[];
  @override
  Future<TripModel?> getTripById(String id) {
    final request = Completer<TripModel?>();
    reads.add(request);
    return request.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.isDemoMode = false;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(TokenStorage.resetStorageAdapter);
  group('HTTP trip search pagination contracts', () {
    test(
      'follows meta, preserves search query and deduplicates IDs across pages',
      () async {
        final pages = <String>[];
        final ds = TripRemoteDataSourceImpl(
          client: ApiClient(
            httpClient: MockClient((request) async {
              final page = request.url.queryParameters['page']!;
              pages.add(page);
              expect(request.url.queryParameters['from'], 'Ho Chi Minh');
              expect(request.url.queryParameters['to'], 'Da Lat');
              expect(
                request.url.queryParameters['departureDate'],
                '2030-10-20',
              );
              return jsonResponse({
                'data': [
                  trip(id: 101).toJson(),
                  if (page == '2') trip(id: 102).toJson(),
                ],
                'meta': {'page': int.parse(page), 'totalPages': 2},
              });
            }),
          ),
        );
        final result = await ds.searchTrips(
          from: 'Ho Chi Minh',
          to: 'Da Lat',
          departureDate: '2030-10-20',
        );
        expect(pages, ['1', '2']);
        expect(result.map((t) => t.id), ['101', '102']);
      },
    );
    test(
      'later page error does not report partial search as complete; retry restarts query',
      () async {
        bool fail = true;
        final pages = <String>[];
        final ds = TripRemoteDataSourceImpl(
          client: ApiClient(
            httpClient: MockClient((request) async {
              final page = request.url.queryParameters['page']!;
              pages.add(page);
              if (page == '2' && fail) {
                return jsonResponse({'message': 'offline'}, 503);
              }
              return jsonResponse({
                'data': [trip(id: int.parse(page)).toJson()],
                'meta': {'totalPages': 2},
              });
            }),
          ),
        );
        await expectLater(ds.searchTrips(), throwsException);
        fail = false;
        expect((await ds.searchTrips()).length, 2);
        expect(pages, ['1', '2', '1', '2']);
      },
    );
    test(
      'malformed payload and inconsistent empty intermediate page are errors',
      () async {
        for (final body in [
          {'data': 'wrong'},
          {
            'data': [],
            'meta': {'totalPages': 2},
          },
        ]) {
          final ds = TripRemoteDataSourceImpl(
            client: ApiClient(
              httpClient: MockClient((r) async => jsonResponse(body)),
            ),
          );
          await expectLater(ds.searchTrips(), throwsFormatException);
        }
      },
    );
    test('empty legitimate search is an empty result', () async {
      final ds = TripRemoteDataSourceImpl(
        client: ApiClient(
          httpClient: MockClient(
            (r) async => jsonResponse({
              'data': [],
              'meta': {'totalPages': 0},
            }),
          ),
        ),
      );
      expect(await ds.searchTrips(), isEmpty);
    });
  });
  test(
    'HTTP public ticket lookup sends credentials in body without auth header',
    () async {
      final ds = TicketRemoteDataSourceImpl(
        client: ApiClient(
          httpClient: MockClient((r) async {
            expect(r.method, 'POST');
            expect(r.url.path, endsWith('/tickets/lookup'));
            expect(r.headers.containsKey('Authorization'), false);
            expect(jsonDecode(r.body), {
              'ticketCode': 'TICKET-AUTH-91',
              'phoneNumber': '0901234567',
            });
            return jsonResponse(qaTicketJson());
          }),
        ),
      );
      final result = await ds.lookupTicket(
        ticketCode: 'TICKET-AUTH-91',
        phoneNumber: '0901234567',
      );
      expect(result.hasFullDetails, true);
      expect(result.canShowQr, true);
    },
  );
  group('Trip detail component lifecycle', () {
    test(
      'latest request wins and close safely discards pending response',
      () async {
        final repo = ReadTripRepository();
        final cubit = TripDetailCubit(repository: repo, tripId: '101');
        final first = cubit.load();
        final latest = cubit.load();
        repo.reads[1].complete(trip(operator: 'New'));
        await latest;
        repo.reads[0].complete(trip(operator: 'Old'));
        await first;
        expect(cubit.state.trip!.operatorName, 'New');
        final pending = cubit.load();
        await cubit.close();
        repo.reads[2].complete(trip());
        await pending;
      },
    );
    test(
      'missing or mismatched detail is retryable and never uses search snapshot',
      () async {
        final repo = ReadTripRepository();
        final cubit = TripDetailCubit(repository: repo, tripId: '101');
        addTearDown(cubit.close);
        final first = cubit.load();
        repo.reads.single.complete(null);
        await first;
        expect(cubit.state.status, TripDetailStatus.failure);
        final retry = cubit.load();
        repo.reads[1].complete(trip());
        await retry;
        expect(cubit.state.status, TripDetailStatus.loaded);
      },
    );
  });
  group('Ticket read/session component lifecycle', () {
    test(
      'fresh unpaid detail overrides stale paid list and caches full server fields',
      () async {
        final repo = ReadBookingRepository();
        final owner = MyTicketsBloc(bookingRepository: repo);
        addTearDown(owner.close);
        owner.add(AddNewTicketEvent(ticket()));
        await tick();
        final reader = TicketReadCubit(owner: owner);
        addTearDown(reader.close);
        final read = reader.loadTicket(ticket());
        expect(reader.state.ticket, isNull);
        repo.details.single.complete(ticket(paid: false));
        await read;
        await tick();
        expect(reader.state.ticket!.canShowQr, false);
        expect(owner.state.tickets.single.canShowQr, false);
      },
    );
    test(
      'failed read/retry hides previous boarding credential; newer response wins',
      () async {
        final repo = ReadBookingRepository();
        final owner = MyTicketsBloc(bookingRepository: repo);
        final reader = TicketReadCubit(owner: owner);
        addTearDown(reader.close);
        addTearDown(owner.close);
        var read = reader.loadTicket(ticket());
        repo.details[0].complete(ticket());
        await read;
        expect(reader.state.ticket!.canShowQr, true);
        read = reader.refresh();
        expect(reader.state.ticket, isNull);
        repo.details[1].completeError(Exception('offline'));
        await read;
        expect(reader.state.status, TicketReadStatus.failure);
        expect(reader.state.ticket, isNull);
        final old = reader.refresh();
        final newer = reader.refresh();
        repo.details[3].complete(ticket(status: 'HUY'));
        await newer;
        repo.details[2].complete(ticket());
        await old;
        expect(reader.state.ticket!.status, TicketStatus.cancelled);
        expect(reader.state.ticket!.canShowQr, false);
      },
    );
    test(
      'unknown status, incomplete and mismatched tickets never authorize detail/QR',
      () async {
        for (final result in [
          ticket(status: 'FUTURE_UNKNOWN'),
          TicketModel.fromJson({
            'ticketId': 91,
            'ticketCode': 'TICKET-AUTH-91',
            'status': 'DA_DAT',
          }),
          ticket().copyWith(id: '999'),
        ]) {
          final repo = ReadBookingRepository();
          final owner = MyTicketsBloc(bookingRepository: repo);
          final reader = TicketReadCubit(owner: owner);
          final read = reader.loadTicket(ticket());
          repo.details.single.complete(result);
          await read;
          expect(reader.state.status, TicketReadStatus.failure);
          expect(reader.state.ticket, isNull);
          await reader.close();
          await owner.close();
        }
      },
    );
    for (final invalidation in ['logout', 'account switch', 'token clear']) {
      test('public lookup response discarded after $invalidation', () async {
        final repo = ReadBookingRepository();
        final owner = MyTicketsBloc(
          bookingRepository: repo,
          authenticated: false,
        );
        owner.setSession(null);
        final reader = TicketReadCubit(owner: owner);
        addTearDown(reader.close);
        addTearDown(owner.close);
        final read = reader.lookup(
          ticketCode: 'TICKET-AUTH-91',
          phoneNumber: '0901234567',
        );
        if (invalidation == 'token clear') {
          await TokenStorage.clearTokens();
        } else {
          owner.setSession('account');
          if (invalidation == 'logout') owner.setSession(null);
        }
        repo.lookups.single.complete(ticket());
        await read;
        expect(reader.state.status, TicketReadStatus.invalidated);
        expect(reader.state.ticket, isNull);
      });
    }
    test('disposed ticket reader discards pending response', () async {
      final repository = ReadBookingRepository();
      final owner = MyTicketsBloc(bookingRepository: repository);
      final reader = TicketReadCubit(owner: owner);
      final read = reader.loadTicket(ticket());
      await reader.close();
      repository.details.single.complete(ticket());
      await read;
      expect(reader.isClosed, true);
      await owner.close();
    });
    test(
      'guest ticket-detail reload uses public lookup rather than protected GET',
      () async {
        final repo = ReadBookingRepository();
        final owner = MyTicketsBloc(
          bookingRepository: repo,
          authenticated: false,
        );
        owner.setSession(null);
        final reader = TicketReadCubit(owner: owner);
        addTearDown(reader.close);
        addTearDown(owner.close);
        final read = reader.loadTicket(ticket());
        expect(repo.details, isEmpty);
        expect(repo.lookupArguments.single['phoneNumber'], '0901234567');
        repo.lookups.single.complete(ticket());
        await read;
        expect(reader.state.status, TicketReadStatus.loaded);
        expect(owner.state.tickets, isEmpty);
      },
    );
  });
  testWidgets(
    'guest My Tickets opens public lookup without account-list filters',
    (tester) async {
      final repository = ReadBookingRepository();
      final owner = MyTicketsBloc(
        bookingRepository: repository,
        authenticated: false,
      )..setSession(null);
      addTearDown(owner.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: owner,
          child: const MaterialApp(home: MyTicketsScreen()),
        ),
      );
      expect(find.byKey(const Key('lookup-ticket-code')), findsOneWidget);
      expect(find.byKey(const Key('lookup-phone')), findsOneWidget);
      expect(find.text('Sắp đi'), findsNothing);
      expect(repository.details, isEmpty);
      expect(repository.lookups, isEmpty);
    },
  );

  testWidgets(
    'trip detail sheet fetches, retries, and booking callback receives fresh model',
    (tester) async {
      final repo = ReadTripRepository();
      TripModel? selected;
      await tester.pumpWidget(
        RepositoryProvider<TripRepository>.value(
          value: repo,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => TripDetailSheet.show(
                    context,
                    trip: trip(operator: 'Stale snapshot'),
                    onSelectTrip: (value) => selected = value,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      expect(repo.reads.length, 1);
      expect(find.text('Stale snapshot'), findsNothing);
      repo.reads[0].completeError(Exception('offline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      repo.reads[1].complete(trip(operator: 'Fresh server'));
      await tester.pumpAndSettle();
      expect(find.text('Fresh server'), findsOneWidget);
      await tester.tap(find.text('CHỌN CHUYẾN NÀY'));
      await tester.pumpAndSettle();
      expect(selected!.operatorName, 'Fresh server');
    },
  );
  testWidgets(
    'ticket detail renders only fresh state and removes QR on refresh/error',
    (tester) async {
      final repo = ReadBookingRepository();
      final owner = MyTicketsBloc(bookingRepository: repo);
      addTearDown(owner.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: owner,
          child: MaterialApp(home: TicketDetailScreen(initialTicket: ticket())),
        ),
      );
      expect(find.byType(BoardingPassCard), findsNothing);
      repo.details[0].complete(ticket(paid: false));
      await tester.pumpAndSettle();
      expect(find.byType(BoardingPassCard), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      await tester.tap(find.byTooltip('Cập nhật trạng thái vé'));
      await tester.pump();
      expect(find.byType(BoardingPassCard), findsNothing);
      repo.details[1].completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      repo.details[2].complete(ticket());
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
    },
  );
  testWidgets('ticket contact copies only server-provided phone', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final repository = ReadBookingRepository();
    final owner = MyTicketsBloc(bookingRepository: repository);
    addTearDown(owner.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: owner,
        child: MaterialApp(home: TicketDetailScreen(initialTicket: ticket())),
      ),
    );
    repository.details.single.complete(
      ticket().copyWith(driverPhone: '0901234567'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sao chép số'));
    await tester.tap(find.text('Sao chép số'));
    await tester.pumpAndSettle();
    expect(copied, '0901234567');
    expect(find.text('Đã sao chép số liên hệ.'), findsOneWidget);
    expect(find.text('Gọi ngay'), findsNothing);
  });

  testWidgets(
    'guest lookup validates, retries, displays authoritative ticket and clears on account switch',
    (tester) async {
      final repo = ReadBookingRepository();
      final owner = MyTicketsBloc(
        bookingRepository: repo,
        authenticated: false,
      );
      owner.setSession(null);
      addTearDown(owner.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: owner,
          child: const MaterialApp(
            home: Scaffold(body: GuestTicketLookupPanel()),
          ),
        ),
      );
      await tester.tap(find.text('Tra cứu vé'));
      await tester.pump();
      expect(repo.lookups, isEmpty);
      expect(find.text('Vui lòng nhập mã vé.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('lookup-ticket-code')),
        'TICKET-AUTH-91',
      );
      await tester.enterText(
        find.byKey(const Key('lookup-phone')),
        '0901234567',
      );
      await tester.tap(find.text('Tra cứu vé'));
      await tester.pump();
      repo.lookups[0].completeError(Exception('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      repo.lookups[1].complete(ticket());
      await tester.pumpAndSettle();
      expect(find.byType(BoardingPassCard), findsOneWidget);
      expect(owner.state.tickets, isEmpty);
      owner.setSession('B');
      await tester.pumpAndSettle();
      expect(find.byType(BoardingPassCard), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('lookup-phone')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  for (final invalidation in ['account switch', 'token clear']) {
    testWidgets('open guest QR is removed after $invalidation', (tester) async {
      final repository = ReadBookingRepository();
      final owner = MyTicketsBloc(
        bookingRepository: repository,
        authenticated: false,
      )..setSession(null);
      addTearDown(owner.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: owner,
          child: const MaterialApp(
            home: Scaffold(body: GuestTicketLookupPanel()),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('lookup-ticket-code')),
        'TICKET-AUTH-91',
      );
      await tester.enterText(
        find.byKey(const Key('lookup-phone')),
        '0901234567',
      );
      await tester.tap(find.text('Tra cứu vé'));
      await tester.pump();
      repository.lookups.single.complete(ticket());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(QrImageView));
      await tester.tap(find.byType(QrImageView));
      await tester.pumpAndSettle();
      expect(find.byType(TicketQrModal), findsOneWidget);
      if (invalidation == 'account switch') {
        owner.setSession('B');
      } else {
        await tester.runAsync(TokenStorage.clearTokens);
      }
      await tester.pumpAndSettle();
      expect(find.byType(TicketQrModal), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('TICKET-AUTH-91'), findsNothing);
    });
  }

  testWidgets(
    'readerless QR entrypoint binds root account owner and cannot reopen after switch',
    (tester) async {
      final repository = ReadBookingRepository();
      final owner = MyTicketsBloc(
        bookingRepository: repository,
        authenticated: false,
      )..setSession(null);
      addTearDown(owner.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: owner,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BoardingPassCard(ticket: ticket()),
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byType(QrImageView));
      await tester.tap(find.byType(QrImageView));
      await tester.pumpAndSettle();
      expect(find.byType(TicketQrModal), findsOneWidget);
      owner.setSession('B');
      await tester.pumpAndSettle();
      expect(find.byType(TicketQrModal), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('TICKET-AUTH-91'), findsNothing);
    },
  );

  testWidgets('open QR cannot outlive refresh of its authoritative reader', (
    tester,
  ) async {
    final repository = ReadBookingRepository();
    final owner = MyTicketsBloc(bookingRepository: repository);
    final reader = TicketReadCubit(owner: owner);
    addTearDown(owner.close);
    addTearDown(reader.close);
    final read = reader.loadTicket(ticket());
    repository.details.single.complete(ticket());
    await read;
    final authoritativeTicket = reader.state.ticket!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BoardingPassCard(
              ticket: authoritativeTicket,
              ticketReader: reader,
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.byType(QrImageView));
    await tester.tap(find.byType(QrImageView));
    await tester.pumpAndSettle();
    expect(find.byType(TicketQrModal), findsOneWidget);
    final refresh = reader.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(TicketQrModal), findsNothing);
    expect(find.byType(QrImageView), findsNothing);
    repository.details[1].complete(ticket(status: 'HUY'));
    await refresh;
  });

  testWidgets(
    'cancelled ticket and quoted refund amount do not imply settlement',
    (tester) async {
      final repository = ReadBookingRepository();
      final owner = MyTicketsBloc(bookingRepository: repository);
      addTearDown(owner.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: owner,
          child: MaterialApp(home: TicketDetailScreen(initialTicket: ticket())),
        ),
      );
      repository.details.single.complete(
        ticket(status: 'HUY').copyWith(refundAmount: 225000),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Tiền hoàn đã được gửi'), findsNothing);
      expect(
        find.textContaining('Trạng thái hoàn tiền chưa được xác nhận'),
        findsOneWidget,
      );
      expect(find.text('Số tiền hoàn (chưa xác nhận):'), findsOneWidget);
    },
  );
}
