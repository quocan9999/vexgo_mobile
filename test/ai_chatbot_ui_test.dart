import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/ai_chatbot_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/ai_chatbot/ai_chatbot_cubit.dart';
import 'package:vexgo_app/features/user/ai_chatbot/presentation/screens/ai_chatbot_screen.dart';
import 'package:vexgo_app/features/user/ai_chatbot/presentation/widgets/ai_chatbot_entry_card.dart';

const _sessionToken = 'ab12cd34-1234-4567-8901-123456789012';

http.Response _ok(Object? data, [int status = 200]) => http.Response(
  jsonEncode({'data': data}),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response _fail(int status, {String message = 'sensitive-internal-trace'}) =>
    http.Response(
      jsonEncode({
        'statusCode': status,
        'error': status == 404 ? 'SESSION_NOT_FOUND' : 'SERVER_ERR',
        'message': message,
      }),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, Object?> _replyPayload({
  String session = _sessionToken,
  String reply = 'Hành khách được miễn phí 1 kiện xách tay theo hạn mức chuyến.',
  bool handoff = false,
  List<Object?> citations = const [],
  List<Object?> suggestedTrips = const [],
  List<String> suggestedQuestions = const [],
}) => {
  'sessionToken': session,
  'reply': reply,
  'intent': 'POLICY',
  'citations': citations,
  'suggestedTrips': suggestedTrips,
  'suggestedQuestions': suggestedQuestions,
  'requiresHumanHandoff': handoff,
  'latencyMs': 24,
  if (handoff) 'handoffReason': 'EXPLICIT_HUMAN_REQUEST',
};

Map<String, Object?> _citationPayload({
  String code = 'POL-LUG-01',
  String title = 'Quy định hành lý đi kèm 2026',
  String path = 'Chính sách hành khách > Mục 2.1 Hành lý xách tay',
}) => {
  'documentCode': code,
  'title': title,
  'hierarchyPath': path,
  'relevanceScore': 0.94,
};

Map<String, Object?> _tripPayload({
  int tripId = 833,
  int? price,
  String? arrivalTime = '05:30',
}) => {
  'tripId': tripId,
  'code': 'VG-833',
  'operator': 'Phương Trang',
  'origin': 'TP. Hồ Chí Minh',
  'destination': 'Đà Lạt',
  'departureDate': '2026-11-15',
  'departureTime': '22:00',
  'arrivalTime': arrivalTime,
  'vehicleType': 'Giường nằm Limousine 34 phòng',
  'price': price,
  'availableSeats': 5,
  'bookingUrl': '/trips/833',
};

class _FakeTripRepository implements TripRepository {
  final Map<String, TripModel?> tripsById = {};
  final Map<String, Completer<TripModel?>> pendingById = {};
  bool shouldThrow = false;
  final List<String> requestedIds = [];

  @override
  Future<TripModel?> getTripById(String id) async {
    requestedIds.add(id);
    if (pendingById.containsKey(id)) {
      return pendingById[id]!.future;
    }
    if (shouldThrow) {
      throw Exception('trip-lookup-failed');
    }
    return tripsById[id];
  }

  @override
  Future<List<CityModel>> getCities() async => const [];

  @override
  Future<List<OperatorModel>> getOperators() async => const [];

  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async => const [];

  @override
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  }) async => const [];
}

TripModel _verifiedTripModel(
  int id, {
  String? rawDepartureTime = '2026-11-15T15:00:00.000Z',
}) => TripModel(
  id: id.toString(),
  operatorId: 'op-1',
  operatorName: 'Phương Trang',
  vehicleType: 'Giường nằm Limousine 34 phòng',
  fromCityId: 'HCM',
  fromCityName: 'TP. Hồ Chí Minh',
  toCityId: 'DL',
  toCityName: 'Đà Lạt',
  departureTime: '22:00',
  arrivalTime: '05:30',
  rawDepartureTime: rawDepartureTime,
  duration: '7h30m',
  pickupPoint: 'Bến xe Miền Đông',
  pickupAddress: '292 Đinh Bộ Lĩnh',
  dropoffPoint: 'Bến xe Liên Tỉnh Đà Lạt',
  dropoffAddress: '01 Tô Hiến Thành',
  originalPrice: 320000,
  discountPrice: 320000,
  availableSeats: 5,
  totalSeats: 34,
  seatLayoutType: 'sleeper_34',
  rating: 4.8,
  reviewCount: 120,
);

RealAiChatbotRepository _makeRepo(
  Future<http.Response> Function(http.Request) handler,
) => RealAiChatbotRepository(
  client: ApiClient(httpClient: MockClient(handler)),
);

void main() {
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });

  tearDown(TokenStorage.resetStorageAdapter);

  group('AI Chatbot UI - Suggestions, Exchanges, Pending, Citations, Trips, Handoff', () {
    testWidgets(
      '1. Loads initial suggestions, handles suggestion error + retry without blocking manual send, and tapping suggestion sends question',
      (tester) async {
        var failSuggestions = true;
        final repo = _makeRepo((req) async {
          if (req.url.path.endsWith('/suggestions')) {
            if (failSuggestions) return _fail(500);
            return _ok([
              {
                'id': 'sug-1',
                'category': 'LUGGAGE',
                'question': 'Hành lý xách tay miễn phí bao nhiêu kg?',
                'description': 'Quy định số kiện và cân nặng miễn phí.',
              },
            ]);
          }
          return _ok(_replyPayload());
        });

        await tester.pumpWidget(
          MaterialApp(home: AiChatbotScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        // Suggestion error is shown with Retry button, but composer is still usable
        expect(find.byKey(const Key('ai-chatbot-suggestions-error')), findsOneWidget);
        expect(find.byKey(const Key('ai-chatbot-suggestions-retry-btn')), findsOneWidget);

        // Retry suggestions -> succeeds and renders suggestion card
        failSuggestions = false;
        await tester.tap(find.byKey(const Key('ai-chatbot-suggestions-retry-btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-suggestion-card-0')), findsOneWidget);
        expect(find.text('Hành lý'), findsOneWidget);
        expect(find.text('Hành lý xách tay miễn phí bao nhiêu kg?'), findsOneWidget);

        // Tap suggestion card -> sends and displays user + AI bubbles, never renders sessionToken
        await tester.tap(find.byKey(const Key('ai-chatbot-suggestion-card-0')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-user-bubble-0')), findsOneWidget);
        expect(find.byKey(const Key('ai-chatbot-assistant-bubble-0')), findsOneWidget);
        expect(
          find.text('Hành khách được miễn phí 1 kiện xách tay theo hạn mức chuyến.'),
          findsOneWidget,
        );
        expect(find.textContaining(_sessionToken), findsNothing);
      },
    );

    testWidgets(
      '2. Pending state locks send button, allows editing a new draft during in-flight POST, preserves new draft on ACK, and never leaks raw server errors',
      (tester) async {
        final sendCompleter = Completer<http.Response>();
        var callCount = 0;
        final repo = _makeRepo((req) async {
          if (req.url.path.endsWith('/suggestions')) return _ok(const []);
          if (callCount++ == 0) return sendCompleter.future;
          return _fail(429, message: 'internal-rate-limiter-stack-trace');
        });

        await tester.pumpWidget(
          MaterialApp(home: AiChatbotScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        // Type first question and tap Send
        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Câu hỏi đầu tiên',
        );
        await tester.pump();

        final sendBtn = find.byKey(const ValueKey('ai-chatbot-send-btn'));
        await tester.tap(sendBtn);
        await tester.pump();

        // Pending exchange and typing indicator are visible; send button is disabled
        expect(find.byKey(const Key('ai-chatbot-pending-exchange')), findsOneWidget);
        expect(find.byKey(const Key('ai-chatbot-typing-indicator')), findsOneWidget);
        expect(find.text('Trợ lý AI đang trả lời…'), findsOneWidget);
        expect(tester.widget<IconButton>(sendBtn).onPressed, isNull);

        // User edits composer while first POST is still in-flight
        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Câu hỏi thứ hai đang gõ dở',
        );
        await tester.pump();

        // Pending bubble still displays the sent question ('Câu hỏi đầu tiên')
        expect(find.text('Câu hỏi đầu tiên'), findsOneWidget);

        // Complete first POST -> exchange is added AND new draft ('Câu hỏi thứ hai đang gõ dở') is preserved
        sendCompleter.complete(_ok(_replyPayload(reply: 'Phản hồi cho câu đầu tiên')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-user-bubble-0')), findsOneWidget);
        expect(find.text('Phản hồi cho câu đầu tiên'), findsOneWidget);
        final textField = tester.widget<TextField>(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
        );
        expect(textField.controller?.text, 'Câu hỏi thứ hai đang gõ dở');

        // Send second question -> receives 429; draft is retained and raw server message is NOT rendered
        await tester.tap(sendBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-error-banner')), findsOneWidget);
        expect(find.textContaining('Bạn đang gửi quá nhanh'), findsOneWidget);
        expect(find.textContaining('internal-rate-limiter-stack-trace'), findsNothing);
        expect(textField.controller?.text, 'Câu hỏi thứ hai đang gõ dở');
      },
    );

    testWidgets(
      '3. Expandable citations, suggested trips with null price ("Chưa có giá"), and verified trip navigation via TripRepository.getTripById',
      (tester) async {
        final fakeTrips = _FakeTripRepository()
          ..tripsById['833'] = _verifiedTripModel(833);
        TripModel? navigatedTrip;
        DateTime? navigatedDate;

        final repo = _makeRepo((req) async {
          if (req.url.path.endsWith('/suggestions')) return _ok(const []);
          return _ok(
            _replyPayload(
              citations: [_citationPayload()],
              suggestedTrips: [
                _tripPayload(tripId: 833, price: null, arrivalTime: null),
                _tripPayload(tripId: 834, price: 320000, arrivalTime: '05:30'),
              ],
              suggestedQuestions: const ['Chuyến này có nhận gửi xe máy không?'],
            ),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: AiChatbotScreen(
              repository: repo,
              tripRepository: fakeTrips,
              onOpenVerifiedTrip: (trip, date) {
                navigatedTrip = trip;
                navigatedDate = date;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Tìm chuyến đi Đà Lạt tối nay',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();

        // Citations collapsed initially -> expand to view documentCode, title, hierarchyPath
        final citationToggle = find.byKey(
          const Key('ai-chatbot-citations-toggle-0'),
        );
        expect(citationToggle, findsOneWidget);
        expect(find.text('POL-LUG-01'), findsNothing);

        await Scrollable.ensureVisible(
          tester.element(citationToggle),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(citationToggle);
        await tester.pumpAndSettle();

        expect(find.text('POL-LUG-01'), findsOneWidget);
        expect(find.text('Quy định hành lý đi kèm 2026'), findsOneWidget);
        expect(
          find.text('Chính sách hành khách > Mục 2.1 Hành lý xách tay'),
          findsOneWidget,
        );

        // Collapse citations again
        await Scrollable.ensureVisible(
          tester.element(citationToggle),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(citationToggle);
        await tester.pumpAndSettle();
        expect(find.text('POL-LUG-01'), findsNothing);

        // Suggested Trip 0 has price == null -> renders "Chưa có giá"
        expect(find.byKey(const Key('ai-chatbot-trip-price-0-0')), findsOneWidget);
        expect(find.text('Chưa có giá'), findsOneWidget);
        // Suggested Trip 1 has price == 320000 -> renders formatted currency
        expect(find.textContaining('320.000'), findsOneWidget);

        // Tap "Xem & chọn chuyến" on Trip 0 (id: 833) -> verifies via TripRepository.getTripById('833')
        final selectTrip0 = find.byKey(
          const Key('ai-chatbot-trip-select-btn-0-0'),
        );
        await Scrollable.ensureVisible(
          tester.element(selectTrip0),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(selectTrip0);
        await tester.pumpAndSettle();

        expect(fakeTrips.requestedIds, ['833']);
        expect(navigatedTrip?.id, '833');
        expect(navigatedDate, DateTime.parse('2026-11-15'));

        // Tap Trip 1 (id: 834, which returns null from fakeTrips) -> shows safe error banner without navigating
        final selectTrip1 = find.byKey(
          const Key('ai-chatbot-trip-select-btn-0-1'),
        );
        await Scrollable.ensureVisible(
          tester.element(selectTrip1),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(selectTrip1);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-trip-error-banner')), findsOneWidget);
      },
    );

    testWidgets(
      '4. Human handoff CTA does not auto-navigate; only navigates when user explicitly taps "Chat với nhân viên"',
      (tester) async {
        var supportChatOpened = 0;
        final repo = _makeRepo((req) async {
          if (req.url.path.endsWith('/suggestions')) return _ok(const []);
          return _ok(
            _replyPayload(
              reply: 'Tôi sẽ chuyển bạn sang bộ phận CSKH.',
              handoff: true,
            ),
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: AiChatbotScreen(
              repository: repo,
              onOpenSupportChat: () => supportChatOpened++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Cho tôi gặp nhân viên tổng đài',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();

        // Handoff card is shown, but supportChatOpened is still 0 (no auto-redirect)
        expect(find.byKey(const Key('ai-chatbot-handoff-card-0')), findsOneWidget);
        expect(
          find.textContaining('chưa tự động kết nối hay gửi nội dung'),
          findsOneWidget,
        );
        expect(supportChatOpened, 0);

        // User explicitly taps "Chat với nhân viên"
        final handoffBtn = find.byKey(const Key('ai-chatbot-handoff-btn-0'));
        await Scrollable.ensureVisible(
          tester.element(handoffBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(handoffBtn);
        await tester.pumpAndSettle();

        expect(supportChatOpened, 1);
      },
    );
  });

  group('AI Chatbot UI - Uncertain State, Read-Only History, Session Isolation & Responsive QA', () {
    testWidgets(
      '5. Uncertain state locks send, preserves draft, reads history without unlocking uncertain, and supports starting new conversation with or without draft',
      (tester) async {
        var postCall = 0;
        var historyNotFound = false;
        final repo = _makeRepo((req) async {
          if (req.url.path.endsWith('/suggestions')) return _ok(const []);
          if (req.method == 'POST') {
            postCall++;
            if (postCall == 1) {
              return _ok(_replyPayload(reply: 'Câu trả lời số 1'));
            }
            return _fail(500);
          }
          // GET history
          if (historyNotFound) return _fail(404);
          return _ok({
            'sessionToken': _sessionToken,
            'status': 'ACTIVE',
            'messages': [
              {
                'id': 10,
                'role': 'ASSISTANT',
                'content': 'Câu trả lời số 1 đã lưu trên máy chủ',
                'createdAt': '2026-11-08T10:30:00Z',
                'requiresHumanHandoff': false,
                'citations': null,
                'toolCalls': null,
              },
            ],
          });
        });

        await tester.pumpWidget(
          MaterialApp(home: AiChatbotScreen(repository: repo)),
        );
        await tester.pumpAndSettle();

        // 1st POST succeeds -> sessionToken is acquired
        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Câu hỏi 1',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();

        // 2nd POST fails with 500 -> uncertain state
        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Câu hỏi 2 bị gián đoạn',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-uncertain-banner')), findsOneWidget);
        // Send button is locked while uncertain
        final sendBtn = find.byKey(const ValueKey('ai-chatbot-send-btn'));
        expect(tester.widget<IconButton>(sendBtn).onPressed, isNull);

        // Tap "Kiểm tra phản hồi đã lưu" -> loads read-only history without dropping local exchanges or unlocking uncertain
        final readHistoryBtn = find.byKey(
          const Key('ai-chatbot-uncertain-history-btn'),
        );
        await Scrollable.ensureVisible(
          tester.element(readHistoryBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(readHistoryBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-history-card')), findsOneWidget);
        expect(
          find.text('Câu trả lời số 1 đã lưu trên máy chủ'),
          findsOneWidget,
        );
        expect(find.text('Câu hỏi 1'), findsOneWidget);
        // Still uncertain -> send button remains locked
        expect(tester.widget<IconButton>(sendBtn).onPressed, isNull);

        // Refresh history when server returns 404 SESSION_NOT_FOUND
        historyNotFound = true;
        final refreshHistoryBtn = find.byKey(
          const Key('ai-chatbot-history-refresh-btn'),
        );
        await Scrollable.ensureVisible(
          tester.element(refreshHistoryBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(refreshHistoryBtn);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('ai-chatbot-history-error')), findsOneWidget);
        expect(find.textContaining('Chưa tìm thấy lịch sử phiên này'), findsOneWidget);

        // Tap "Hội thoại mới (Giữ nháp)" -> clears uncertain and preserves 'Câu hỏi 2 bị gián đoạn'
        final keepDraftBtn = find.byKey(
          const Key('ai-chatbot-uncertain-new-keep-btn'),
        );
        await Scrollable.ensureVisible(
          tester.element(keepDraftBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(keepDraftBtn);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-uncertain-banner')), findsNothing);
        final textField = tester.widget<TextField>(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
        );
        expect(textField.controller?.text, 'Câu hỏi 2 bị gián đoạn');
        expect(tester.widget<IconButton>(sendBtn).onPressed, isNotNull);
      },
    );

    testWidgets(
      '6. Account login/logout switch and company filter reset visible exchanges, composer draft, and in-flight trip lookup; Back button pops cleanly',
      (tester) async {
        final fakeTrips = _FakeTripRepository();
        final tripCompleter = Completer<TripModel?>();
        fakeTrips.pendingById['833'] = tripCompleter;
        TripModel? navigatedTrip;

        final repo = _makeRepo((req) async {
          if (req.url.path.endsWith('/suggestions')) return _ok(const []);
          return _ok(
            _replyPayload(
              reply: 'Phản hồi riêng tư của phiên trước',
              suggestedTrips: [_tripPayload(tripId: 833)],
            ),
          );
        });

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: AiChatbotEntryCard(companyId: 5),
              ),
            ),
            GoRoute(
              path: '/ai-chatbot',
              builder: (context, state) => AiChatbotScreen(
                repository: repo,
                tripRepository: fakeTrips,
                initialCompanyId: state.extra as int?,
                onOpenVerifiedTrip: (trip, _) => navigatedTrip = trip,
              ),
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Tap entry card to open AI Chatbot with companyId = 5
        await tester.tap(find.byKey(const Key('ai-chatbot-entry-card')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai-chatbot-company-banner')), findsOneWidget);
        expect(find.text('Đang lọc theo nhà xe #5'), findsOneWidget);

        // Send a message and start verifying trip 833
        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Tin nhắn riêng tư',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();
        expect(find.text('Phản hồi riêng tư của phiên trước'), findsOneWidget);

        final selectTripBtn = find.byKey(
          const Key('ai-chatbot-trip-select-btn-0-0'),
        );
        await Scrollable.ensureVisible(
          tester.element(selectTripBtn),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(selectTripBtn);
        await tester.pump();

        // Type a draft and open New Conversation confirmation bar
        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Nháp chưa gửi',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('ai-chatbot-new-conv-btn')));
        await tester.pump();
        expect(
          find.byKey(const Key('ai-chatbot-new-conv-confirm-bar')),
          findsOneWidget,
        );

        // Switch account via TokenStorage -> clears exchanges, draft, confirmation bar, and ignores late trip lookup
        await TokenStorage.saveAccessToken('new-user-jwt');
        await tester.pumpAndSettle();

        tripCompleter.complete(_verifiedTripModel(833));
        await tester.pumpAndSettle();

        expect(navigatedTrip, isNull);
        expect(find.text('Phản hồi riêng tư của phiên trước'), findsNothing);
        expect(
          find.byKey(const Key('ai-chatbot-new-conv-confirm-bar')),
          findsNothing,
        );
        final textField = tester.widget<TextField>(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
        );
        expect(textField.controller?.text, isEmpty);

        // Tap Back button -> returns to '/'
        await tester.tap(find.byKey(const Key('ai-chatbot-back-btn')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('ai-chatbot-entry-card')), findsOneWidget);
      },
    );

    testWidgets(
      '7. Responsive QA: 320x640 at 2.0x textScale with long content/citations/trips/handoff + 640x360 landscape with keyboard open has 0 overflow and >= 48dp touch targets',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewInsets();
        });

        final cubit = AiChatbotCubit(
          repository: _makeRepo((req) async {
            if (req.url.path.endsWith('/suggestions')) {
              return _ok([
                {
                  'id': 's1',
                  'category': 'POLICY',
                  'question':
                      'Chính sách hoàn hủy vé lễ Tết và đổi giờ khởi hành trước 24 giờ như thế nào?',
                  'description':
                      'Hướng dẫn chi tiết điều kiện hủy vé và liên hệ nhà xe hoàn tiền.',
                },
              ]);
            }
            return _ok(
              _replyPayload(
                reply:
                    'Nội dung trả lời rất dài để kiểm tra khả năng tự xuống dòng trên màn hình hẹp 320dp ở mức phóng chữ 2.0x mà không gây lỗi tràn khung giao diện.',
                handoff: true,
                citations: [
                  _citationPayload(
                    code: 'DOC-REFUND-2026-LONG',
                    title: 'Quy chế hoàn hủy vé xe khách liên tỉnh năm 2026',
                    path: 'Chương III > Điều 12 > Khoản 4: Hoàn tiền tại quầy',
                  ),
                ],
                suggestedTrips: [
                  _tripPayload(tripId: 833, price: null),
                  _tripPayload(tripId: 834, price: 450000),
                ],
                suggestedQuestions: const [
                  'Phí hủy vé trước 12 tiếng là bao nhiêu?',
                ],
              ),
            );
          }),
          companyId: 12,
        );
        addTearDown(cubit.close);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: AiChatbotScreen(cubit: cubit),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify touch targets >= 48x48dp
        for (final key in [
          const ValueKey('ai-chatbot-send-btn'),
          const Key('ai-chatbot-new-conv-btn'),
          const Key('ai-chatbot-header-support-btn'),
        ]) {
          final size = tester.getSize(find.byKey(key));
          expect(size.width, greaterThanOrEqualTo(48.0));
          expect(size.height, greaterThanOrEqualTo(48.0));
        }

        // Send a question and expand citations at 320dp 2.0x textScale
        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Kiểm tra giao diện 2.0x',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final citationToggle = find.byKey(
          const Key('ai-chatbot-citations-toggle-0'),
        );
        await Scrollable.ensureVisible(
          tester.element(citationToggle),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(citationToggle);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Switch to 640x360 landscape with keyboard open (bottom = 160)
        tester.view.physicalSize = const Size(640, 360);
        tester.view.viewInsets = FakeViewPadding(bottom: 160);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '8. Late trip result must not navigate after New Conversation',
      (tester) async {
        final pending = Completer<TripModel?>();
        final trips = _FakeTripRepository()..pendingById['833'] = pending;
        TripModel? navigated;
        final repo = _makeRepo(
          (req) async => req.method == 'GET'
              ? _ok(const [])
              : _ok(_replyPayload(suggestedTrips: [_tripPayload()])),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AiChatbotScreen(
              repository: repo,
              tripRepository: trips,
              onOpenVerifiedTrip: (trip, _) => navigated = trip,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Tìm chuyến',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();

        final select = find.byKey(const Key('ai-chatbot-trip-select-btn-0-0'));
        await Scrollable.ensureVisible(tester.element(select), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(select);
        await tester.pump();

        // Start a new conversation before getTripById finishes
        await tester.tap(find.byKey(const Key('ai-chatbot-new-conv-btn')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('ai-chatbot-confirm-new-clear-btn')),
        );
        await tester.pump();

        pending.complete(_verifiedTripModel(833));
        await tester.pumpAndSettle();

        expect(
          navigated,
          isNull,
          reason:
              'Old conversation trip result must not navigate after visible chat was reset',
        );
      },
    );

    testWidgets(
      '9. Verified trip schedule overrides stale AI suggestion date (with UTC+7 conversion) and rejects missing/invalid schedule date without falling back to AI date or today',
      (tester) async {
        final updated = TripModel.fromJson({
          ..._verifiedTripModel(833).toJson(),
          'rawDepartureTime': '2026-11-16T15:00:00.000Z',
        });
        final missingDateTrip = _verifiedTripModel(834, rawDepartureTime: null);
        final trips = _FakeTripRepository()
          ..tripsById['833'] = updated
          ..tripsById['834'] = missingDateTrip;
        DateTime? openedDate;
        TripModel? openedTrip;

        final repo = _makeRepo(
          (req) async => req.method == 'GET'
              ? _ok(const [])
              : _ok(
                  _replyPayload(
                    suggestedTrips: [
                      _tripPayload(tripId: 833),
                      _tripPayload(tripId: 834),
                    ],
                  ),
                ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AiChatbotScreen(
              repository: repo,
              tripRepository: trips,
              onOpenVerifiedTrip: (trip, date) {
                openedTrip = trip;
                openedDate = date;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Tìm chuyến',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('ai-chatbot-send-btn')));
        await tester.pumpAndSettle();

        // Trip 833: AI suggested 2026-11-15, but verified TripModel departs 2026-11-16T15:00:00.000Z (Nov 16 22:00 UTC+7)
        final select0 = find.byKey(const Key('ai-chatbot-trip-select-btn-0-0'));
        await Scrollable.ensureVisible(tester.element(select0), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(select0);
        await tester.pumpAndSettle();

        expect(openedTrip?.id, '833');
        expect(openedDate, DateTime(2026, 11, 16));

        // Trip 834: Verified TripModel lacks rawDepartureTime -> must show error banner and NOT navigate
        openedTrip = null;
        openedDate = null;
        final select1 = find.byKey(const Key('ai-chatbot-trip-select-btn-0-1'));
        await Scrollable.ensureVisible(tester.element(select1), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(select1);
        await tester.pumpAndSettle();

        expect(openedTrip, isNull);
        expect(openedDate, isNull);
        expect(find.byKey(const Key('ai-chatbot-trip-error-banner')), findsOneWidget);
      },
    );

    testWidgets(
      '10. New-conversation confirmation fits narrow 320x640 at 2.0x textScale with keyboard bottom = 300 without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        tester.view.viewInsets = FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        final repo = _makeRepo((_) async => _ok(const []));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: AiChatbotScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('ai-chatbot-composer-input')),
          'Nháp',
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Before opening confirmation');

        await tester.tap(find.byKey(const Key('ai-chatbot-new-conv-btn')));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Confirmation is inside scroll area and must not overflow above keyboard',
        );
        expect(
          find.byKey(const Key('ai-chatbot-new-conv-confirm-bar')),
          findsOneWidget,
        );
      },
    );
  });
}
