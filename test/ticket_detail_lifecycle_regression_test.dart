import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/ticket_read_cubit.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/boarding_pass_card.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/screens/ticket_detail_screen.dart';
import 'qa/qa_fixtures.dart';

class _Repo implements BookingRepository {
  bool fail = false;
  Completer<TicketModel?>? next;
  final tickets = <String, TicketModel>{};
  @override
  Future<List<TicketModel>> getMyTickets() async => [];
  @override
  Future<TicketModel?> getTicketById(String id) async {
    final pending = next;
    next = null;
    if (pending != null) return pending.future;
    if (fail) throw const SocketException('Connection refused');
    return tickets[id];
  }

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
  setUp(() {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });
  TicketModel ticket(String id) => TicketModel.fromJson({
    ...qaTicketJson(),
    'ticketId': int.parse(id),
    'ticketCode': 'PRIVATE-$id',
  }).copyWith(driverPhone: '0909999999');
  Future<void> mount(
    WidgetTester tester,
    MyTicketsBloc owner,
    TicketModel ticket, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: owner,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: TicketDetailScreen(initialTicket: ticket),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Fast refresh keeps authoritative ticket and QR visible', (
    tester,
  ) async {
    final repo = _Repo();
    final t = ticket('91');
    repo.tickets[t.id] = t;
    expect(t.hasFullDetails, isTrue);
    final owner = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    addTearDown(owner.close);
    await mount(tester, owner, t);
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.tap(find.byTooltip('Cập nhật trạng thái vé'));
    await tester.pumpAndSettle();
    final reader = tester
        .element(find.byType(BoardingPassCard))
        .read<TicketReadCubit>();
    expect(reader.state.status, TicketReadStatus.loaded);
    expect(reader.state.ticket!.canShowQr, isTrue);
    expect(owner.sessionGeneration, 1);
    debugPrint(
      'REVIEW refresh reader=loaded canShowQr=true unchanged session; invalidated banners=${find.text('Phiên đã thay đổi. Vui lòng mở lại thông tin vé.').evaluate().length}',
    );
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.text('Phiên đã thay đổi. Vui lòng mở lại thông tin vé.'),
      findsNothing,
    );
  });
  testWidgets('Mounted route can replace seed with another ticket', (
    tester,
  ) async {
    final repo = _Repo();
    final a = ticket('91');
    final b = ticket('92');
    repo.tickets.addAll({a.id: a, b.id: b});
    final owner = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    addTearDown(owner.close);
    await mount(tester, owner, a);
    await mount(tester, owner, b);
    final reader = tester
        .element(find.byType(BoardingPassCard))
        .read<TicketReadCubit>();
    expect(reader.state.status, TicketReadStatus.loaded);
    expect(reader.state.ticket!.id, b.id);
    expect(find.textContaining('PRIVATE-92'), findsWidgets);
    expect(find.textContaining('PRIVATE-91'), findsNothing);
    expect(find.byType(QrImageView), findsOneWidget);
  });
  testWidgets('Offline error landscape 2x can display retry without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo()..fail = true;
    final owner = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    addTearDown(owner.close);
    await mount(tester, owner, ticket('91'), scale: 2);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Clipboard feedback does not cross account replacement', (
    tester,
  ) async {
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
    final repo = _Repo();
    final t = ticket('91');
    repo.tickets[t.id] = t;
    final owner = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    addTearDown(owner.close);
    await mount(tester, owner, t);
    final copy = find.text('Sao chép số');
    await tester.ensureVisible(copy);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pump();
    owner.setSession('b');
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Đã sao chép số liên hệ.'), findsNothing);
  });

  for (final replaceSession in [false, true]) {
    testWidgets(
      'Delayed refresh hides old QR; account replacement=$replaceSession',
      (tester) async {
        final repo = _Repo();
        final t = ticket('91');
        repo.tickets[t.id] = t;
        final owner = MyTicketsBloc(bookingRepository: repo)..setSession('a');
        addTearDown(owner.close);
        await mount(tester, owner, t);
        final gate = Completer<TicketModel?>();
        repo.next = gate;
        await tester.tap(find.byTooltip('Cập nhật trạng thái vé'));
        await tester.pump();
        expect(find.byType(QrImageView), findsNothing);
        expect(find.textContaining(t.ticketCode), findsNothing);
        if (replaceSession) owner.setSession('b');
        gate.complete(t.copyWith());
        await tester.pumpAndSettle();
        expect(
          find.byType(QrImageView),
          replaceSession ? findsNothing : findsOneWidget,
        );
        if (replaceSession) {
          expect(find.textContaining(t.ticketCode), findsNothing);
        } else {
          expect(
            find.text('Phiên đã thay đổi. Vui lòng mở lại thông tin vé.'),
            findsNothing,
          );
        }
      },
    );
  }

  testWidgets(
    'Clipboard completion after route disposal has no feedback or exception',
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
      final repo = _Repo();
      final t = ticket('91');
      repo.tickets[t.id] = t;
      final owner = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      addTearDown(owner.close);
      await mount(tester, owner, t);
      final copy = find.text('Sao chép số');
      await tester.ensureVisible(copy);
      await tester.pumpAndSettle();
      await tester.tap(copy);
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Other route'))),
      );
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đã sao chép số liên hệ.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Previously rendered copy callback cannot copy after session replacement',
    (tester) async {
      var copies = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copies++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final repo = _Repo();
      final t = ticket('91');
      repo.tickets[t.id] = t;
      final owner = MyTicketsBloc(bookingRepository: repo)..setSession('a');
      addTearDown(owner.close);
      await mount(tester, owner, t);
      final button = find.ancestor(
        of: find.text('Sao chép số'),
        matching: find.byType(OutlinedButton),
      );
      final action = tester.widget<OutlinedButton>(button).onPressed!;
      owner.setSession('b');
      action();
      await tester.pumpAndSettle();
      expect(copies, 0);
      expect(find.text('Đã sao chép số liên hệ.'), findsNothing);
    },
  );
}
