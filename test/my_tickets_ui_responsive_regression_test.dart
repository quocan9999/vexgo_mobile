import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/screens/my_tickets_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/ticket_summary_card.dart';
import 'qa/qa_fixtures.dart';

class _Repo implements BookingRepository {
  @override
  Future<List<TicketModel>> getMyTickets() async => [qaTicket()];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedRepo extends _Repo {
  final first = Completer<List<TicketModel>>();
  int calls = 0;
  @override
  Future<List<TicketModel>> getMyTickets() {
    calls++;
    return calls == 1 ? first.future : Future.value([]);
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
  });

  testWidgets('Landscape keyboard leaves a usable list without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = MyTicketsBloc(bookingRepository: _Repo());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(640, 360),
              textScaler: TextScaler.linear(2),
              viewInsets: EdgeInsets.only(bottom: 180),
            ),
            child: const MyTicketsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    final listRect = tester.getRect(find.byType(ListView));
    final tabRect = tester.getRect(find.byKey(const Key('tab-upcoming')));
    expect(listRect.height, greaterThan(0));
    expect(listRect.top, greaterThanOrEqualTo(tabRect.bottom - 1));
  });
  testWidgets('Price remains completely visible on 320dp 2x', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ticket = qaTicket();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TicketSummaryCard(ticket: ticket, onTap: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final price = find.descendant(
      of: find.text(CurrencyFormatter.format(ticket.finalAmount)),
      matching: find.byType(RichText),
    );
    final paragraph = tester.renderObject<RenderParagraph>(price);
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'Money must not be ellipsized',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Status tabs provide Android 48dp tap targets', (tester) async {
    final bloc = MyTicketsBloc(bookingRepository: _Repo());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: MyTicketsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final tab = find.byKey(const Key('tab-upcoming'));
    expect(tester.getSize(tab).height, greaterThanOrEqualTo(48));
  });

  testWidgets('Old account response cannot populate replacement account', (
    tester,
  ) async {
    final repo = _DelayedRepo();
    final bloc = MyTicketsBloc(bookingRepository: repo)..setSession('a');
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: MyTicketsScreen()),
      ),
    );
    await tester.pump();
    expect(repo.calls, 1);
    bloc.setSession('b');
    await tester.pumpAndSettle();
    repo.first.complete([qaTicket()]);
    await tester.pumpAndSettle();
    expect(find.byType(TicketSummaryCard), findsNothing);
    expect(bloc.state.tickets, isEmpty);
    expect(repo.calls, 2);
  });

  testWidgets(
    'Search controller focus and selection survive landscape keyboard resize',
    (tester) async {
      final bloc = MyTicketsBloc(bookingRepository: _Repo());
      addTearDown(bloc.close);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      Future<void> pump(Size size, double inset) async {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          BlocProvider.value(
            value: bloc,
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(2),
                  viewInsets: EdgeInsets.only(bottom: inset),
                ),
                child: const MyTicketsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pump(const Size(320, 740), 0);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'QA');
      await tester.pumpAndSettle();
      final original = tester.widget<EditableText>(find.byType(EditableText));
      original.controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 2,
      );

      await pump(const Size(640, 360), 180);
      final resized = tester.widget<EditableText>(find.byType(EditableText));
      expect(identical(original.controller, resized.controller), isTrue);
      expect(resized.focusNode.hasFocus, isTrue);
      expect(resized.controller.text, 'QA');
      expect(
        resized.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 2),
      );
      expect(bloc.state.searchQuery, 'QA');
      expect(tester.takeException(), isNull);
      await pump(const Size(320, 740), 0);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
