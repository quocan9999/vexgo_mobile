import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/repositories/ai_chatbot_repository.dart';
import 'package:vexgo_app/features/user/ai_chatbot/ai_chatbot_cubit.dart';

const token = 'ab12cd34-1234-4567-8901-123456789012';
const otherToken = 'ab12cd34-1234-4567-8901-123456789013';
Map<String, Object?> answer({String session = token, bool handoff = false}) => {
  'sessionToken': session,
  'reply': 'Thông tin từ hệ thống',
  'intent': 'GENERAL',
  'citations': <Object>[],
  'requiresHumanHandoff': handoff,
  'latencyMs': 15,
  if (handoff) 'handoffReason': 'EXPLICIT_HUMAN_REQUEST',
};
Map<String, Object?> trip() => {
  'tripId': 833,
  'code': 'QA',
  'operator': 'Hoa Mai',
  'origin': 'TP.HCM',
  'destination': 'Đà Lạt',
  'departureDate': '2026-11-08',
  'departureTime': '22:00',
  'arrivalTime': null,
  'vehicleType': 'Ghế ngồi',
  'price': null,
  'availableSeats': 2,
  'bookingUrl': 'https://untrusted.example/path',
};
Map<String, Object?> history({
  String session = token,
  List<Object?>? messages,
}) => {
  'sessionToken': session,
  'status': 'ACTIVE',
  'messages':
      messages ??
      [
        {
          'id': 1,
          'role': 'ASSISTANT',
          'content': 'Phản hồi đã lưu',
          'createdAt': '2026-11-08T10:00:00Z',
          'requiresHumanHandoff': false,
          'citations': null,
          'toolCalls': null,
        },
      ],
};
http.Response ok(Object? value, [int status = 200]) => http.Response(
  jsonEncode({'data': value}),
  status,
  headers: {'content-type': 'application/json'},
);
http.Response failure(int status) => http.Response(
  jsonEncode({
    'statusCode': status,
    'error': status == 404 ? 'SESSION_NOT_FOUND' : 'QA_ERROR',
    'message': 'sensitive-server-message',
  }),
  status,
  headers: {'content-type': 'application/json'},
);
RealAiChatbotRepository repo(
  Future<http.Response> Function(http.Request) handler,
) =>
    RealAiChatbotRepository(client: ApiClient(httpClient: MockClient(handler)));
AiChatbotCubit cubit(Future<http.Response> Function(http.Request) handler) {
  final c = AiChatbotCubit(repository: repo(handler));
  addTearDown(c.close);
  return c;
}

void main() {
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });

  test(
    'history attaches owner bearer, guest omits it, and reads USER messages',
    () async {
      var requests = 0;
      final r = repo((request) async {
        expect(
          request.headers['Authorization'],
          requests++ == 0 ? null : 'Bearer qa-owner',
        );
        return ok(
          history(
            messages: [
              {
                'id': 1,
                'role': 'USER',
                'content': 'Câu hỏi đã lưu',
                'createdAt': '2026-11-08T10:00:00Z',
                'requiresHumanHandoff': false,
                'citations': null,
                'toolCalls': null,
              },
            ],
          ),
        );
      });
      await r.history(token);
      await TokenStorage.saveAccessToken('qa-owner');
      expect((await r.history(token)).messages.single.role, 'USER');
      expect(requests, 2);
    },
  );

  test(
    'expired history bearer refreshes without changing identity or posting chat again',
    () async {
      await TokenStorage.saveTokens(
        accessToken: 'expired-owner',
        refreshToken: 'qa-refresh',
      );
      final version = TokenStorage.sessionVersion;
      var reads = 0, refreshes = 0;
      final r = repo((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshes++;
          expect(request.method, 'POST');
          return ok({
            'accessToken': 'fresh-owner',
            'refreshToken': 'fresh-refresh',
          });
        }
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/ai-chatbot/sessions/$token/messages');
        reads++;
        if (request.headers['Authorization'] == 'Bearer expired-owner') {
          return failure(401);
        }
        expect(request.headers['Authorization'], 'Bearer fresh-owner');
        return ok(history());
      });
      await r.history(token);
      expect(reads, 2);
      expect(refreshes, 1);
      expect(TokenStorage.sessionVersion, version);
    },
  );

  test(
    'parse real reply shape and nullable trip fields, reject invalid required data',
    () {
      final data = answer()..['suggestedTrips'] = [trip()];
      final reply = AiChatReply.fromJson(data);
      expect(reply.suggestedTrips.single.tripId, 833);
      expect(reply.suggestedTrips.single.price, isNull);
      expect(reply.suggestedQuestions, isEmpty);
      expect(() => reply.suggestedTrips.clear(), throwsUnsupportedError);
      for (final malformed in [
        answer()..['requiresHumanHandoff'] = 'true',
        answer()..['sessionToken'] = '../secret',
        answer()..['latencyMs'] = -1,
        answer()..remove('reply'),
      ]) {
        expect(() => AiChatReply.fromJson(malformed), throwsFormatException);
      }
      expect(
        () =>
            AiSuggestedTrip.fromJson(trip()..['departureDate'] = '2026-02-31'),
        throwsFormatException,
      );
      expect(
        () => AiSuggestedTrip.fromJson(trip()..['price'] = 0.5),
        throwsFormatException,
      );
      expect(
        () => AiSuggestedTrip.fromJson(trip()..['departureTime'] = '24:00'),
        throwsFormatException,
      );
    },
  );

  test('history uses its own shape; invalid roles rejected', () {
    final parsed = AiChatHistory.fromJson(history());
    expect(parsed.messages.single.content, 'Phản hồi đã lưu');
    expect(parsed.messages.single.suggestedTrips, isEmpty);
    expect(
      () => AiChatHistory.fromJson(
        history(
          messages: [
            {
              'id': 1,
              'role': 'BOT',
              'content': 'x',
              'createdAt': '2026-11-08T00:00:00Z',
              'requiresHumanHandoff': false,
            },
          ],
        ),
      ),
      throwsFormatException,
    );
  });

  test(
    'repository sends guest contract, then authenticated optional bearer and tenant',
    () async {
      var count = 0;
      final r = repo((request) async {
        expect(request.url.path, '/api/v1/ai-chatbot/messages');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map;
        expect(body['message'], 'Hỏi chính sách');
        if (count++ == 0) {
          expect(request.headers['Authorization'], isNull);
          expect(body.containsKey('sessionToken'), false);
        } else {
          expect(request.headers['Authorization'], 'Bearer qa-token');
          expect(body['nhaXeId'], 3);
          expect(body['sessionToken'], token);
        }
        return ok(answer());
      });
      await r.send(message: ' Hỏi chính sách ');
      await TokenStorage.saveAccessToken('qa-token');
      await r.send(
        message: 'Hỏi chính sách',
        sessionToken: token,
        companyId: 3,
      );
      expect(count, 2);
    },
  );

  test(
    'validation blocks invalid payload before HTTP; history token cannot inject path',
    () async {
      var calls = 0;
      final r = repo((_) async {
        calls++;
        return ok(answer());
      });
      await expectLater(r.send(message: ' '), throwsArgumentError);
      await expectLater(r.send(message: 'x' * 2001), throwsArgumentError);
      await expectLater(
        r.send(message: 'x', companyId: 0),
        throwsArgumentError,
      );
      await expectLater(r.history('../private'), throwsFormatException);
      expect(calls, 0);
    },
  );

  test(
    'suggestions envelope, read-only history endpoint and missing-session404',
    () async {
      var calls = 0;
      final r = repo((request) async {
        calls++;
        expect(request.method, 'GET');
        if (request.url.path.endsWith('/suggestions')) {
          return ok([
            {
              'id': 's',
              'category': 'POLICY',
              'question': 'Hỏi?',
              'description': 'Mô tả',
            },
          ]);
        }
        expect(request.url.path, '/api/v1/ai-chatbot/sessions/$token/messages');
        return calls == 2 ? ok(history()) : failure(404);
      });
      expect((await r.suggestions()).single.question, 'Hỏi?');
      expect((await r.history(token)).messages.length, 1);
      await expectLater(
        r.history(token),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );
    },
  );

  test(
    'repository rejects response token mismatch and late prior-identity reply',
    () async {
      final r = repo((_) async => ok(answer(session: otherToken)));
      await expectLater(
        r.send(message: 'x', sessionToken: token),
        throwsFormatException,
      );
      await expectLater(r.history(token), throwsFormatException);
      final gate = Completer<http.Response>();
      final old = repo((_) => gate.future).send(message: 'old');
      await Future<void>.delayed(Duration.zero);
      await TokenStorage.clearTokens();
      gate.complete(ok(answer()));
      await expectLater(old, throwsA(isA<UnauthorizedException>()));
    },
  );

  test('single flight and preserve a new draft typed while sending', () async {
    var calls = 0;
    final gate = Completer<http.Response>();
    final c = cubit((_) {
      calls++;
      return gate.future;
    });
    c.setDraft('Câu đầu');
    final pending = c.send();
    await c.send();
    await Future<void>.delayed(Duration.zero);
    c.setDraft('Câu tiếp theo');
    gate.complete(ok(answer(handoff: true)));
    await pending;
    expect(calls, 1);
    expect(c.state.exchanges.single.question, 'Câu đầu');
    expect(c.state.draft, 'Câu tiếp theo');
    expect(c.state.requiresHumanHandoff, true);
    expect(c.state.handoffReason, 'EXPLICIT_HUMAN_REQUEST');
    expect(c.state.sessionToken, token);
  });

  test(
    'blank/overlong draft blocked, errors do not disclose raw server details',
    () async {
      var calls = 0;
      final c = cubit((_) async {
        calls++;
        return failure(400);
      });
      await c.send();
      c.setDraft('a' * 2001);
      await c.send();
      expect(calls, 0);
      c.setDraft('valid');
      await c.send();
      expect(c.state.draft, 'valid');
      expect(c.state.error, isNot(contains('sensitive-server-message')));
      expect(c.state.uncertain, false);
      expect(c.state.canSend, true);
    },
  );

  test(
    'timeout first POST keeps draft and blocks retry until explicit new conversation',
    () async {
      var calls = 0;
      final c = cubit((_) async {
        calls++;
        throw http.ClientException('offline');
      });
      c.setDraft('Câu chưa rõ');
      await c.send();
      expect(c.state.uncertain, true);
      expect(c.state.draft, 'Câu chưa rõ');
      expect(c.state.sessionToken, isNull);
      c.setDraft('Câu chưa rõ');
      expect(c.state.error, isNotNull);
      await c.send();
      await c.readHistory();
      expect(calls, 1);
      c.newConversation(keepDraft: true);
      expect(c.state.uncertain, false);
      expect(c.state.draft, 'Câu chưa rõ');
    },
  );

  test(
    '500 and malformed200 mark uncertain; 429 stays retryable and never auto retries',
    () async {
      for (final status in [500, 200, 429]) {
        var calls = 0;
        final c = cubit((_) async {
          calls++;
          return status == 200 ? ok({'reply': 'incomplete'}) : failure(status);
        });
        c.setDraft('Câu hỏi');
        await c.send();
        expect(calls, 1);
        expect(c.state.uncertain, status != 429);
        expect(c.state.draft, 'Câu hỏi');
      }
    },
  );

  test(
    'history readback never silently unlocks uncertain POST or drops local user messages',
    () async {
      var sends = 0;
      final c = cubit((r) async {
        if (r.method == 'GET') return ok(history());
        if (sends++ == 0) return ok(answer());
        return failure(500);
      });
      c.setDraft('first');
      await c.send();
      c.setDraft('second');
      await c.send();
      await c.readHistory();
      expect(c.state.historySnapshot!.messages.length, 1);
      expect(c.state.exchanges.single.question, 'first');
      expect(c.state.uncertain, true);
      expect(c.state.draft, 'second');
      await c.send();
      expect(sends, 2);
    },
  );

  test('history404 preserves known token, local exchange and draft', () async {
    final c = cubit(
      (r) async => r.method == 'POST' ? ok(answer()) : failure(404),
    );
    c.setDraft('first');
    await c.send();
    c.setDraft('next');
    await c.readHistory();
    expect(c.state.historyError, contains('Chưa tìm thấy'));
    expect(c.state.sessionToken, token);
    expect(c.state.exchanges.length, 1);
    expect(c.state.draft, 'next');
  });

  test('logout clears visible state and ignores late send', () async {
    final gate = Completer<http.Response>();
    final c = cubit((_) => gate.future);
    c.setDraft('private');
    final pending = c.send();
    await Future<void>.delayed(Duration.zero);
    await TokenStorage.clearTokens();
    gate.complete(ok(answer()));
    await pending;
    expect(c.state.exchanges, isEmpty);
    expect(c.state.sessionToken, isNull);
    expect(c.state.draft, isEmpty);
    expect(c.state.sending, false);
  });

  test(
    'login replacement clears acknowledged guest chat and prior handoff',
    () async {
      final c = cubit((_) async => ok(answer(handoff: true)));
      c.setDraft('guest');
      await c.send();
      await TokenStorage.saveAccessToken('new-user');
      expect(c.state.exchanges, isEmpty);
      expect(c.state.requiresHumanHandoff, false);
      expect(c.state.sessionToken, isNull);
    },
  );

  test(
    'tenant switch/new conversation/close discard late HTTP without emitting',
    () async {
      for (final action in ['tenant', 'new', 'close']) {
        final gate = Completer<http.Response>();
        final c = AiChatbotCubit(repository: repo((_) => gate.future));
        c.setDraft('old');
        final pending = c.send();
        await Future<void>.delayed(Duration.zero);
        if (action == 'tenant') {
          c.setCompany(3);
        } else if (action == 'new') {
          c.newConversation();
        } else {
          await c.close();
        }
        gate.complete(ok(answer()));
        await pending;
        if (action != 'close') {
          expect(c.state.exchanges, isEmpty);
          expect(c.state.companyId, action == 'tenant' ? 3 : null);
          await c.close();
        }
      }
    },
  );

  test(
    'suggestions failure does not block manual send; late history discarded after tenant change',
    () async {
      final gate = Completer<http.Response>();
      final c = cubit((r) async {
        if (r.url.path.endsWith('/suggestions')) return failure(500);
        if (r.method == 'GET') return gate.future;
        return ok(answer());
      });
      await c.loadSuggestions();
      expect(c.state.suggestionsError, isNotNull);
      c.setDraft('manual');
      await c.send();
      final pending = c.readHistory();
      await Future<void>.delayed(Duration.zero);
      c.setCompany(3);
      gate.complete(ok(history()));
      await pending;
      expect(c.state.historySnapshot, isNull);
      expect(c.state.loadingHistory, false);
    },
  );

  test('session token is redacted from ApiClient debug URI', () {
    final url = Uri.parse(
      'https://api.example/api/v1/ai-chatbot/sessions/$token/messages',
    );
    expect(ApiClient.sanitizeUriForLog(url), isNot(contains(token)));
  });
}
