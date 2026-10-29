import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/booking/presentation/screens/booking_success_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';

import 'booking_success_ui_comprehensive_test.dart' as fixtures;

class _Repository implements BookingRepository {
  @override
  Future<List<TicketModel>> getMyTickets() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'VexGoJakarta',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(accessToken: 'account-a');
  });

  final first = fixtures.createTicket(
    id: '101',
    code: 'PRIVATE-A',
    seat: 'A01',
  );
  final second = fixtures.createTicket(
    id: '102',
    code: 'SECOND-CODE',
    seat: 'A02',
  );

  MyTicketsBloc owner() {
    final bloc = MyTicketsBloc(bookingRepository: _Repository())
      ..setSession('a');
    addTearDown(bloc.close);
    return bloc;
  }

  Future<void> mount(WidgetTester tester, MyTicketsBloc bloc) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          home: BookingSuccessScreen(ticket: first, tickets: [first, second]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('account replacement removes mounted QR and passenger data', (
    tester,
  ) async {
    final bloc = owner();
    await mount(tester, bloc);
    expect(find.byType(QrImageView), findsNWidgets(2));
    await tester.runAsync(
      () => TokenStorage.saveTokens(accessToken: 'account-b'),
    );
    bloc.setSession('b');
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('PRIVATE-A'), findsNothing);
    expect(find.text(first.passenger.phone), findsNothing);
    expect(find.byKey(const ValueKey('copy-ticket-102')), findsNothing);
    expect(bloc.state.tickets, isEmpty);
  });

  testWidgets('logout clears mounted ticket; token refresh preserves it', (
    tester,
  ) async {
    final bloc = owner();
    await mount(tester, bloc);
    expect(
      await tester.runAsync(
        () => TokenStorage.rotateTokensIfCurrent(
          expectedVersion: TokenStorage.sessionVersion,
          accessToken: 'rotated-a',
          refreshToken: 'refresh-a',
        ),
      ),
      isTrue,
    );
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNWidgets(2));
    await tester.runAsync(TokenStorage.clearTokens);
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('PRIVATE-A'), findsNothing);
  });

  testWidgets('second ticket copies its own complete code with a 48dp target', (
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
    await mount(tester, owner());
    final button = find.byKey(const ValueKey('copy-ticket-102'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(copied, second.ticketCode);
    expect(find.text('Đã sao chép mã vé vào bộ nhớ tạm!'), findsOneWidget);
  });

  testWidgets(
    'clipboard completion after session change shows no stale feedback',
    (tester) async {
      final gate = Completer<void>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') await gate.future;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await mount(tester, owner());
      await tester.tap(find.byTooltip('Sao chép mã vé'));
      await tester.pump();
      await tester.runAsync(TokenStorage.clearTokens);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đã sao chép mã vé vào bộ nhớ tạm!'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
    },
  );

  testWidgets('cache session replacement also invalidates the route', (
    tester,
  ) async {
    final bloc = owner();
    await mount(tester, bloc);
    bloc.setSession('b');
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text(first.passenger.phone), findsNothing);
  });

  test(
    'queued add from old token session is discarded before processing',
    () async {
      final bloc = owner();
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        AddNewTicketEvent(
          first,
          sessionGeneration: bloc.sessionGeneration,
          tokenSessionVersion: TokenStorage.sessionVersion,
        ),
      );
      final saving = TokenStorage.saveTokens(accessToken: 'b');
      await saving;
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.tickets, isEmpty);
    },
  );

  test(
    'queued add from old cache session is discarded before processing',
    () async {
      final bloc = owner();
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        AddNewTicketEvent(
          first,
          sessionGeneration: bloc.sessionGeneration,
          tokenSessionVersion: TokenStorage.sessionVersion,
        ),
      );
      bloc.setSession('b');
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.tickets, isEmpty);
    },
  );
}
