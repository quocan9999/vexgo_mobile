import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/datasources/remote/notification_remote_data_source.dart';
import 'package:vexgo_app/data/datasources/remote/review_remote_data_source.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import 'package:vexgo_app/data/models/review_model.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_event.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_state.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_bloc.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_event.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_state.dart';

class FakeReviewRemoteDataSource implements ReviewRemoteDataSource {
  bool called = false;
  Map<String, dynamic>? lastBody;
  bool shouldThrow = false;

  @override
  Future<ReviewModel> createReview({
    required int tripId,
    required int rating,
    String? comment,
  }) async {
    called = true;
    lastBody = {'tripId': tripId, 'rating': rating, 'comment': comment};
    if (shouldThrow) throw Exception('Review submit failed');
    return ReviewModel(
      rating: rating,
      comment: comment ?? '',
      createdAt: '2026-10-09T00:00:00.000Z',
    );
  }
}

class FakeNotificationRemoteDataSource implements NotificationRemoteDataSource {
  bool shouldThrow = false;
  List<NotificationModel> mockList = [];
  dynamic lastReadId;
  bool markAllCalled = false;

  @override
  Future<List<NotificationModel>> getNotifications() => getMyNotifications();

  @override
  Future<List<NotificationModel>> getMyNotifications({
    bool unreadOnly = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (shouldThrow) throw Exception('Notification fetch failed');
    return mockList;
  }

  @override
  Future<bool> markAsRead(dynamic id) async {
    lastReadId = id;
    if (shouldThrow) throw Exception('Mark read failed');
    return true;
  }

  @override
  Future<bool> markAllAsRead() async {
    markAllCalled = true;
    if (shouldThrow) throw Exception('Mark all read failed');
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3: Reviews & Notifications Integration Tests', () {
    late FakeReviewRemoteDataSource fakeReviewDataSource;
    late FakeNotificationRemoteDataSource fakeNotifDataSource;
    late HybridNotificationRepository hybridNotifRepo;

    // Flat TicketsService response after Backend PR #39; no hand-built trip model.
    final completedTicket = TicketModel.fromJson({
      'ticketId': 501,
      'ticketCode': 'VXG-999888',
      'bookingId': 101,
      'tripId': 25,
      'status': 'HOAN_TAT',
      'busCompanyName': 'Phương Trang',
      'origin': 'TP. Hồ Chí Minh',
      'destination': 'Đà Lạt',
      'departureTime': '2026-10-01T01:00:00.000Z',
      'arrivalTime': '2026-10-01T07:00:00.000Z',
      'seatNumber': 'A05',
      'price': 300000,
      'createdAt': '2026-09-29T01:00:00.000Z',
    });

    setUp(() {
      fakeReviewDataSource = FakeReviewRemoteDataSource();
      fakeNotifDataSource = FakeNotificationRemoteDataSource();
      hybridNotifRepo = HybridNotificationRepository(
        remoteDataSource: fakeNotifDataSource,
      );
    });

    test(
      'SubmitTicketReviewEvent calls ReviewRemoteDataSource with correct tripId and rating',
      () async {
        final bloc = MyTicketsBloc(
          reviewRemoteDataSource: fakeReviewDataSource,
        );

        bloc.add(AddNewTicketEvent(completedTicket));

        const review = ReviewModel(
          rating: 5,
          comment: 'Tài xế lái rất êm và cẩn thận',
          createdAt: '2026-10-09T00:00:00.000Z',
        );

        bloc.add(
          const SubmitTicketReviewEvent(ticketId: '501', review: review),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              final t = state.tickets.firstWhere((t) => t.id == '501');
              return t.review != null &&
                  t.review!.rating == 5 &&
                  state.successMessage != null;
            }),
          ),
        );

        expect(fakeReviewDataSource.called, isTrue);
        expect(fakeReviewDataSource.lastBody?['tripId'], equals(25));
        expect(fakeReviewDataSource.lastBody?['rating'], equals(5));
        expect(
          fakeReviewDataSource.lastBody?['comment'],
          equals('Tài xế lái rất êm và cẩn thận'),
        );

        await bloc.close();
      },
    );

    test(
      'Finding K: SubmitTicketReviewEvent in Real Mode emits error and never fakes success when backend review fails',
      () async {
        ApiConfig.isDemoMode = false;
        fakeReviewDataSource.shouldThrow = true;
        final bloc = MyTicketsBloc(
          reviewRemoteDataSource: fakeReviewDataSource,
        );

        bloc.add(AddNewTicketEvent(completedTicket));

        const review = ReviewModel(
          rating: 5,
          comment: 'Tài xế lái rất êm và cẩn thận',
          createdAt: '2026-10-09T00:00:00.000Z',
        );

        bloc.add(
          const SubmitTicketReviewEvent(ticketId: '501', review: review),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<MyTicketsState>((state) {
              final t = state.tickets.firstWhere((t) => t.id == '501');
              return t.review == null &&
                  state.errorMessage != null &&
                  state.errorMessage!.contains('chưa khả dụng');
            }),
          ),
        );

        await bloc.close();
      },
    );

    test(
      'Finding J: HybridNotificationRepository & RealNotificationRepository in Real Mode call remote data source',
      () async {
        ApiConfig.isDemoMode = false;
        final realRepo = RealNotificationRepository(
          remoteDataSource: fakeNotifDataSource,
        );
        final realList = await realRepo.getNotifications();
        expect(realList, isEmpty);

        final hybridList = await hybridNotifRepo.getNotifications();
        expect(hybridList, isEmpty);
      },
    );

    test(
      'Finding J: HybridNotificationRepository in Demo Mode returns mock data',
      () async {
        ApiConfig.isDemoMode = true;
        try {
          final list = await hybridNotifRepo.getNotifications();
          expect(list, isA<List<NotificationModel>>());
        } finally {
          ApiConfig.isDemoMode = false;
        }
      },
    );

    test(
      'NotificationBloc in Demo Mode interacts with HybridNotificationRepository',
      () async {
        ApiConfig.isDemoMode = true;
        try {
          final bloc = NotificationBloc(
            notificationRepository: hybridNotifRepo,
          );
          bloc.add(const LoadNotificationsEvent());

          await expectLater(
            bloc.stream,
            emitsThrough(
              predicate<NotificationState>((state) {
                return state.status == NotificationStatus.loaded;
              }),
            ),
          );

          await bloc.close();
        } finally {
          ApiConfig.isDemoMode = false;
        }
      },
    );
  });
}
