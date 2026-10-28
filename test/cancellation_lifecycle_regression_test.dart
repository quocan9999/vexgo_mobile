import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/api_response.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/ticket_read_cubit.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/cancel_ticket_sheet.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/guest_cancel_ticket_sheet.dart';
import 'qa/qa_fixtures.dart';

class Repo extends MockBookingRepository {
  TicketModel current = TicketModel.fromJson(qaTicketJson());
  final gate = Completer<Map<String, dynamic>>();
  double? sentRate;
  bool fail = false;
  int calls = 0;
  bool autoSuccess = false;
  bool malformed = false;
  bool hideList = false;
  ApiException? rejected;
  Map<String, dynamic>? reply;
  @override
  Future<List<TicketModel>> getMyTickets() async => hideList ? [] : [current];
  @override
  Future<TicketModel?> getTicketById(String id) async => current;
  @override
  Future<TicketModel?> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async => current;
  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) {
    sentRate = expectedCancelFeeRate;
    calls++;
    if (rejected != null) return Future.error(rejected!);
    if (reply != null) return Future.value(reply!);
    if (fail) return Future.error(StateError('offline'));
    if (malformed) return Future.value({'success': true});
    if (autoSuccess) {
      current = current.copyWith(
        status: TicketStatus.cancelled,
        rawStatus: 'HUY',
      );
      return Future.value({
        'ticketId': current.id,
        'ticketCode': current.ticketCode,
        'status': 'HUY',
        'refundAmount': 225000,
      });
    }
    return gate.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'VexGoJakarta',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  setUp(() {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });
  Future<void> open(
    WidgetTester tester,
    Repo repo,
    MyTicketsBloc bloc, {
    TicketReadCubit? reader,
  }) async {
    addTearDown(() async {
      if (repo.sentRate != null &&
          !repo.fail &&
          !repo.autoSuccess &&
          !repo.malformed &&
          repo.rejected == null &&
          repo.reply == null &&
          !repo.gate.isCompleted) {
        repo.gate.completeError(StateError('test cleanup'));
        await tester.pump();
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => reader == null
                  ? CancelTicketSheet.show(context, repo.current, bloc)
                  : GuestCancelTicketSheet.show(context, reader),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Xác nhận hủy vé');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('Authenticated sheet stays visible while mutation is pending', (
    tester,
  ) async {
    final repo = Repo();
    final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    addTearDown(bloc.close);
    await open(tester, repo, bloc);
    await submit(tester);
    expect(find.byType(CancelTicketSheet), findsOneWidget);
  });
  testWidgets('Guest failure keeps sheet for error and retry', (tester) async {
    final repo = Repo()..fail = true;
    final bloc = MyTicketsBloc(bookingRepository: repo, authenticated: false)
      ..setSession(null);
    addTearDown(bloc.close);
    final reader = TicketReadCubit(owner: bloc);
    addTearDown(reader.close);
    await reader.lookup(
      ticketCode: repo.current.ticketCode,
      phoneNumber: repo.current.passenger.phone,
    );
    await open(tester, repo, bloc, reader: reader);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.byType(GuestCancelTicketSheet), findsOneWidget);
  });
  testWidgets(
    'Open authenticated sheet revokes old passenger ticket after account change',
    (tester) async {
      final repo = Repo();
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      addTearDown(bloc.close);
      await open(tester, repo, bloc);
      bloc.setSession('b');
      await tester.pumpAndSettle();
      expect(find.textContaining(repo.current.ticketCode), findsNothing);
    },
  );
  testWidgets('Never sends a new cache fee under consent to an older quote', (
    tester,
  ) async {
    final repo = Repo();
    final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    addTearDown(bloc.close);
    await open(tester, repo, bloc);
    repo.current = repo.current.copyWith(
      cancellation: const CancellationQuote(
        eligible: true,
        cancelFeeRate: 0.2,
        cancelFee: 50000,
        refundAmount: 200000,
      ),
    );
    bloc.add(const LoadMyTicketsEvent());
    await tester.pumpAndSettle();
    await submit(tester);
    expect(
      repo.sentRate,
      isNull,
      reason: 'A changed quote requires new user consent',
    );
  });

  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  CancelTicketEvent event(Repo repo, MyTicketsBloc bloc) => CancelTicketEvent(
    ticketId: repo.current.id,
    reason: 'Changed plans',
    refundAmount: repo.current.cancellation!.refundAmount,
    quotedTicket: repo.current,
    sessionGeneration: bloc.sessionGeneration,
    tokenSessionVersion: TokenStorage.sessionVersion,
  );
  test(
    'Bloc rejects duplicate submissions across callers while first is pending',
    () async {
      final repo = Repo();
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      await flush();
      final request = event(repo, bloc);
      bloc.add(request);
      bloc.add(request);
      await flush();
      expect(repo.calls, 1);
      repo.gate.complete({
        'ticketId': repo.current.id,
        'ticketCode': repo.current.ticketCode,
        'status': 'HUY',
        'refundAmount': 225000,
      });
      await flush();
      expect(bloc.state.cancellationStatus, TicketCancellationStatus.succeeded);
      expect(bloc.state.successMessage, contains('xác nhận riêng'));
      expect(bloc.state.tickets.single.rawStatus, 'HUY');
      await bloc.close();
    },
  );
  test(
    'Malformed success enters uncertainty and only read-only checks may follow',
    () async {
      final repo = Repo()..malformed = true;
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      await flush();
      final request = event(repo, bloc);
      bloc.add(request);
      await flush();
      expect(bloc.state.cancellationStatus, TicketCancellationStatus.uncertain);
      expect(bloc.state.tickets.single.status, TicketStatus.upcoming);
      bloc.add(request);
      await flush();
      expect(repo.calls, 1);
      bloc.add(CheckCancellationEvent(repo.current.id));
      await flush();
      expect(repo.calls, 1);
      expect(bloc.state.cancellationStatus, TicketCancellationStatus.uncertain);
      repo.current = repo.current.copyWith(
        status: TicketStatus.cancelled,
        rawStatus: 'HUY',
      );
      bloc.add(CheckCancellationEvent(repo.current.id));
      await flush();
      expect(bloc.state.cancellationStatus, TicketCancellationStatus.succeeded);
      expect(repo.calls, 1);
      await bloc.close();
    },
  );
  test(
    'Known API rejection does not fake cancellation or lock read-only forever',
    () async {
      final repo = Repo()
        ..rejected = const ApiException(
          ApiError(
            statusCode: 409,
            errorCode: 'CANCELLATION_QUOTE_EXPIRED',
            message: 'Quote expired',
          ),
        );
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      await flush();
      bloc.add(event(repo, bloc));
      await flush();
      expect(bloc.state.cancellationStatus, TicketCancellationStatus.failed);
      expect(bloc.state.successMessage, isNull);
      expect(bloc.state.tickets.single.status, TicketStatus.upcoming);
      expect(bloc.cancellationUncertain(repo.current.id), isFalse);
      await bloc.close();
    },
  );
  test(
    'Pending cancellation response cannot update a replacement account',
    () async {
      final repo = Repo();
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      await flush();
      bloc.add(event(repo, bloc));
      await flush();
      expect(repo.calls, 1);
      repo.hideList = true;
      bloc.setSession('b');
      await flush();
      repo.gate.complete({
        'ticketId': repo.current.id,
        'ticketCode': repo.current.ticketCode,
        'status': 'HUY',
      });
      await flush();
      expect(bloc.state.tickets, isEmpty);
      expect(bloc.state.cancellationStatus, TicketCancellationStatus.idle);
      expect(bloc.state.successMessage, isNull);
      await bloc.close();
    },
  );
  test(
    'Guest uncertain outcome cannot submit again, even after another lookup',
    () async {
      final repo = Repo()..fail = true;
      final bloc = MyTicketsBloc(bookingRepository: repo, authenticated: false)
        ..setSession(null);
      final reader = TicketReadCubit(owner: bloc);
      final original = repo.current;
      await reader.lookup(
        ticketCode: original.ticketCode,
        phoneNumber: original.passenger.phone,
      );
      await reader.cancelTicket(
        quotedTicket: reader.state.ticket!,
        reason: 'Changed plans',
      );
      expect(reader.state.cancellationUncertain, isTrue);
      expect(repo.calls, 1);
      await reader.cancelTicket(
        quotedTicket: reader.state.ticket!,
        reason: 'Changed plans',
      );
      expect(repo.calls, 1);
      repo.current = TicketModel.fromJson({
        ...qaTicketJson(),
        'ticketId': 92,
        'ticketCode': 'OTHER-92',
      });
      await reader.lookup(
        ticketCode: repo.current.ticketCode,
        phoneNumber: repo.current.passenger.phone,
      );
      expect(reader.state.cancellationUncertain, isFalse);
      repo.current = original;
      await reader.lookup(
        ticketCode: original.ticketCode,
        phoneNumber: original.passenger.phone,
      );
      expect(reader.state.cancellationUncertain, isTrue);
      await reader.cancelTicket(
        quotedTicket: reader.state.ticket!,
        reason: 'Changed plans',
      );
      expect(repo.calls, 1);
      await reader.close();
      await bloc.close();
    },
  );
  testWidgets(
    'Uncertain authenticated outcome survives sheet close and reopen',
    (tester) async {
      final repo = Repo()..malformed = true;
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      addTearDown(bloc.close);
      await open(tester, repo, bloc);
      await submit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra trạng thái'), findsOneWidget);
      expect(repo.calls, 1);
      await tester.ensureVisible(find.text('Giữ vé / Đóng'));
      await tester.tap(find.text('Giữ vé / Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra trạng thái'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Xác nhận hủy vé'),
      );
      expect(button.onPressed, isNull);
      expect(repo.calls, 1);
    },
  );

  test('A mismatched refund response cannot confirm cancellation', () async {
    final repo = Repo();
    repo.reply = {
      'ticketId': repo.current.id,
      'ticketCode': repo.current.ticketCode,
      'status': 'HUY',
      'refundAmount': 999999,
    };
    final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    await flush();
    bloc.add(event(repo, bloc));
    await flush();
    expect(bloc.state.cancellationStatus, TicketCancellationStatus.uncertain);
    expect(bloc.state.tickets.single.status, TicketStatus.upcoming);
    expect(bloc.state.successMessage, isNull);
    await bloc.close();
  });
  testWidgets(
    'Missing quote has retry but no inferred cancellation fee or submit',
    (tester) async {
      final repo = Repo()
        ..current = TicketModel.fromJson({
          ...qaTicketJson(),
          'cancellation': null,
        });
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CancelTicketSheet(ticket: repo.current, bloc: bloc),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Xác nhận hủy vé'),
        findsNothing,
      );
      expect(repo.calls, 0);
    },
  );

  test(
    'Authoritative cancellation in owner cache immediately revokes reader payload',
    () async {
      final repo = Repo();
      final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      await flush();
      final reader = TicketReadCubit(owner: bloc);
      await reader.loadTicket(repo.current);
      expect(reader.state.ticket!.canShowQr, isTrue);
      final cancelled = repo.current.copyWith(
        status: TicketStatus.cancelled,
        rawStatus: 'HUY',
      );
      bloc.add(SyncTicketDetailsEvent(cancelled, bloc.sessionGeneration));
      await flush();
      expect(reader.state.ticket, isNull);
      await reader.refresh();
      expect(
        reader.state.ticket,
        isNull,
        reason:
            'A stale paid read must not restore QR after confirmed cancellation',
      );
      repo.current = cancelled;
      await reader.refresh();
      expect(reader.state.ticket!.status, TicketStatus.cancelled);
      expect(reader.state.ticket!.canShowQr, isFalse);
      await reader.close();
      await bloc.close();
    },
  );
}
