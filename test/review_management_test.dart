import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/my_bookings/presentation/widgets/review_bottom_sheet.dart';
import 'review_contract_regression_test.dart' show ReviewHarness;

// HTTP fixtures for develop@0159558; these are not bank/device E2E results.
class ManagementHarness extends ReviewHarness {
  bool editable = true, wrongAck = false, staleReadback = false;
  bool deletedButStillVisible = false, failMutation = false;
  int patches = 0, deletes = 0, reads = 0;
  Completer<void>? mutationGate;
  final started = Completer<void>();
  ManagementHarness() {
    savedReview = {
      'reviewId': 71,
      'tripId': 902,
      'rating': 4,
      'comment': 'Nội dung cũ',
      'createdAt': '2026-11-06T01:00:00.000Z',
    };
  }
  @override
  Future<http.Response> handle(http.Request request) async {
    http.Response response(Object data, [int code = 200]) => http.Response(
      jsonEncode({'data': data}),
      code,
      headers: ReviewHarness.jsonHeaders,
    );
    if (request.url.path.endsWith('/reviews/my')) {
      reads++;
      return response({
        'reviews': [
          if (savedReview != null)
            {
              ...savedReview!,
              'id': 71,
              'isEditable': editable,
              'isEdited': patches > 0,
              'reply': {
                'content': 'Nhà xe cảm ơn bạn.',
                'responderName': 'Hoa Mai',
                'createdAt': '2026-11-06T02:00:00.000Z',
              },
            },
        ],
      });
    }
    if (request.url.path.endsWith('/reviews/71')) {
      if (request.method == 'PATCH') {
        patches++;
      } else {
        deletes++;
      }
      if (!started.isCompleted) started.complete();
      if (mutationGate != null) await mutationGate!.future;
      if (failMutation) throw TimeoutException('Fixture timeout');
      if (request.method == 'PATCH') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (!staleReadback) savedReview = {...savedReview!, ...body};
        return response({
          'success': true,
          'review': {
            'id': wrongAck ? 99 : 71,
            'tripId': 902,
            ...body,
            'updatedAt': '2026-11-06T03:00:00.000Z',
          },
        });
      }
      if (!deletedButStillVisible) savedReview = null;
      return response({'success': true});
    }
    return super.handle(request);
  }

  Future<MyTicketsState> act(MyTicketsEvent event) async {
    final done = bloc.stream.firstWhere(
      (s) =>
          s.reviewTicketId == '501' &&
          s.reviewStatus != TicketReviewStatus.loading &&
          s.reviewStatus != TicketReviewStatus.submitting,
    );
    bloc.add(event);
    return done.timeout(const Duration(seconds: 3));
  }
}

const edited = ReviewModel(
  rating: 5,
  comment: 'Nội dung mới',
  createdAt: 'unused',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUp(() async {
    ApiConfig.isDemoMode = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(
      accessToken: 'fixture-access',
      refreshToken: 'fixture-refresh',
    );
  });
  tearDown(TokenStorage.resetStorageAdapter);
  ManagementHarness harness() {
    final h = ManagementHarness();
    addTearDown(h.bloc.close);
    return h;
  }

  test(
    'own endpoint preserves ID, edit permission, and carrier reply',
    () async {
      final h = harness();
      await h.load();
      final state = await h.act(const RefreshTicketReviewEvent('501'));
      final review = state.tickets.single.review!;
      expect(review.reviewId, 71);
      expect(review.isEditable, isTrue);
      expect(review.replyContent, 'Nhà xe cảm ơn bạn.');
      expect(review.responderName, 'Hoa Mai');
    },
  );
  test(
    'edit reads back authoritative content across seats on same trip',
    () async {
      final h = harness()..secondSeat = true;
      await h.load();
      final state = await h.act(
        const UpdateTicketReviewEvent(ticketId: '501', review: edited),
      );
      expect(state.reviewStatus, TicketReviewStatus.succeeded);
      expect(
        state.tickets.every((t) => t.review?.comment == edited.comment),
        isTrue,
      );
      expect(
        state.tickets.every((t) => t.review?.replyContent != null),
        isTrue,
      );
      expect(h.patches, 1);
      expect(h.reads, 2);
    },
  );
  test(
    'expired edit is blocked by server flag, delete still allowed',
    () async {
      final h = harness()..editable = false;
      await h.load();
      final rejected = await h.act(
        const UpdateTicketReviewEvent(ticketId: '501', review: edited),
      );
      expect(rejected.reviewStatus, TicketReviewStatus.failed);
      expect(h.patches, 0);
      final deleted = await h.act(const DeleteTicketReviewEvent('501'));
      expect(deleted.reviewStatus, TicketReviewStatus.succeeded);
      expect(deleted.tickets.single.review, isNull);
      expect(h.deletes, 1);
    },
  );
  for (final ack in [true, false]) {
    test(
      'rejects ${ack ? 'wrong ACK identity' : 'stale readback'} after edit',
      () async {
        final h = harness()
          ..wrongAck = ack
          ..staleReadback = !ack;
        await h.load();
        final state = await h.act(
          const UpdateTicketReviewEvent(ticketId: '501', review: edited),
        );
        expect(state.reviewStatus, TicketReviewStatus.uncertain);
        expect(state.tickets.single.review?.comment, 'Nội dung cũ');
      },
    );
  }
  test(
    'delete requires absence on readback and blocks repeat until refresh',
    () async {
      final h = harness()..deletedButStillVisible = true;
      await h.load();
      final state = await h.act(const DeleteTicketReviewEvent('501'));
      expect(state.reviewStatus, TicketReviewStatus.uncertain);
      expect(state.tickets.single.review, isNotNull);
      h.bloc.add(const DeleteTicketReviewEvent('501'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.deletes, 1);
      await h.act(const RefreshTicketReviewEvent('501'));
      expect(h.bloc.reviewUncertain('501'), isFalse);
    },
  );
  test('double edit is single flight', () async {
    final h = harness()..mutationGate = Completer<void>();
    await h.load();
    final done = h.act(
      const UpdateTicketReviewEvent(ticketId: '501', review: edited),
    );
    await h.started.future;
    h.bloc.add(const UpdateTicketReviewEvent(ticketId: '501', review: edited));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    h.mutationGate!.complete();
    await done;
    expect(h.patches, 1);
  });
  test(
    'uncertain edit blocks retry through a second seat of the same trip',
    () async {
      final h = harness()
        ..secondSeat = true
        ..failMutation = true;
      await h.load();
      await h.act(
        const UpdateTicketReviewEvent(ticketId: '501', review: edited),
      );
      h.bloc.add(
        const UpdateTicketReviewEvent(ticketId: '502', review: edited),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.patches, 1);
      expect(h.bloc.reviewUncertain('502'), isTrue);
    },
  );
  test(
    'late list/detail snapshots cannot restore a confirmed deleted review',
    () async {
      final h = harness()..secondSeat = true;
      await h.load();
      final oldTicket = h.bloc.state.tickets.first;
      final oldReview = h.savedReview;
      final deleted = await h.act(const DeleteTicketReviewEvent('501'));
      expect(deleted.tickets.every((t) => t.review == null), isTrue);
      h.savedReview =
          oldReview; // Delayed ticket endpoint/cache still has old payload.
      await h.load();
      h.bloc.add(SyncTicketDetailsEvent(oldTicket, h.bloc.sessionGeneration));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.bloc.state.tickets.every((t) => t.review == null), isTrue);
      await h.act(const RefreshTicketReviewEvent('501'));
      expect(h.bloc.state.tickets.every((t) => t.review != null), isTrue);
    },
  );
  test(
    'account change during mutation causes no next-account follow-up read',
    () async {
      final h = harness()..mutationGate = Completer<void>();
      await h.load();
      h.bloc.add(
        const UpdateTicketReviewEvent(ticketId: '501', review: edited),
      );
      await h.started.future;
      h.bloc.setSession(null);
      await TokenStorage.clearTokens();
      h.mutationGate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(h.reads, 1);
      expect(h.bloc.state.tickets, isEmpty);
      expect(h.bloc.state.successMessage, isNull);
    },
  );
  test(
    'timeout preserves old review and refresh reconciles committed change',
    () async {
      final h = harness()..failMutation = true;
      await h.load();
      final state = await h.act(
        const UpdateTicketReviewEvent(ticketId: '501', review: edited),
      );
      expect(state.reviewStatus, TicketReviewStatus.uncertain);
      expect(state.tickets.single.review?.comment, 'Nội dung cũ');
      h.savedReview = {
        ...h.savedReview!,
        'comment': edited.comment,
        'rating': edited.rating,
      };
      final refreshed = await h.act(const RefreshTicketReviewEvent('501'));
      expect(refreshed.tickets.single.review?.comment, edited.comment);
    },
  );
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('sheet reply/edit fit $size at 2x text with keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = harness();
      h.bloc.add(const LoadMyTicketsEvent());
      for (
        var frame = 0;
        frame < 20 && h.bloc.state.status != MyTicketsStatus.loaded;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(h.bloc.state.status, MyTicketsStatus.loaded);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 100),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: ReviewBottomSheet(
              ticket: h.bloc.state.tickets.single,
              bloc: h.bloc,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Nhà xe cảm ơn bạn.'), findsOneWidget);
      final edit = find.text('Sửa đánh giá');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(TokenStorage.clearTokens);
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Nội dung cũ'), findsNothing);
    });
  }
  testWidgets('failed edit retains the draft for explicit refresh', (
    tester,
  ) async {
    final h = harness()..failMutation = true;
    h.bloc.add(const LoadMyTicketsEvent());
    for (
      var frame = 0;
      frame < 20 && h.bloc.state.status != MyTicketsStatus.loaded;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(h.bloc.state.status, MyTicketsStatus.loaded);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReviewBottomSheet(
            ticket: TicketModel.fromJson(h.ticket),
            bloc: h.bloc,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Sửa đánh giá'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'Bản nháp được giữ lại');
    final save = find.text('Lưu thay đổi');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Bản nháp được giữ lại'), findsOneWidget);
    expect(h.bloc.state.reviewStatus, TicketReviewStatus.uncertain);
    expect(h.patches, 1);
  });
}
