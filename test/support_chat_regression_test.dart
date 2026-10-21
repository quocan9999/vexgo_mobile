import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/support_chat_socket.dart';
import 'package:vexgo_app/data/datasources/remote/support_chat_remote_data_source.dart';
import 'package:vexgo_app/data/models/support_chat_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/repositories/support_chat_repository.dart';
import 'package:vexgo_app/features/user/support_chat/bloc/support_chat_cubit.dart';

Map<String, dynamic> messageJson(
  int id, {
  int conversation = 1,
  int sender = 7,
  String? clientId,
  String status = 'DA_GUI',
}) => {
  'tinNhanId': id,
  'cuocTroChuyenId': conversation,
  'taiKhoanGuiId': sender,
  'clientMessageId': clientId,
  'noiDung': 'Nội dung $id',
  'loaiNguoiGui': sender == 7 ? 'KHACH_HANG' : 'NHAN_VIEN',
  'loaiTinNhan': 'VAN_BAN',
  'createdAt': '2026-10-20T12:00:00Z',
  'trangThai': status,
};
ChatMessage message(
  int id, {
  int conversation = 1,
  int sender = 7,
  String? clientId,
  String status = 'DA_GUI',
}) => ChatMessage.fromJson(
  messageJson(
    id,
    conversation: conversation,
    sender: sender,
    clientId: clientId,
    status: status,
  ),
);
ChatConversation fixtureConversation(int id, {String status = 'DANG_XU_LY'}) =>
    ChatConversation(
      id: id,
      companyId: id,
      companyName: 'Nhà xe $id',
      status: status,
    );

class FakeSocket implements ChatSocket {
  final controller = StreamController<ChatSocketEvent>.broadcast(sync: true);
  final requests = <MapEntry<String, Map<String, dynamic>>>[];
  bool ready = false;
  int connects = 0;
  final tokens = <String>[];
  Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)? handler;
  @override
  Stream<ChatSocketEvent> get events => controller.stream;
  @override
  bool get connected => ready;
  @override
  void connect(String token) {
    connects++;
    tokens.add(token);
  }

  @override
  void disconnect() {
    ready = false;
  }

  @override
  Future<void> dispose() => controller.close();
  @override
  Future<Map<String, dynamic>> request(
    String event,
    Map<String, dynamic> payload,
  ) async {
    requests.add(MapEntry(event, payload));
    if (handler != null) return handler!(event, payload);
    return {'success': true};
  }

  void incoming(String event, dynamic data) =>
      controller.add(ChatSocketEvent(event, data));
}

class FakeRepository implements SupportChatRepository {
  @override
  Future<List<OperatorModel>> companies() async => const [
    OperatorModel(id: '1', name: 'Nhà xe 1', shortName: 'TEST'),
  ];
  final records = <int, List<ChatMessage>>{};
  final readCalls = <List<int>>[];
  final messageCalls = <({int id, int? before})>[];
  final sends = <({int id, String clientId, String content})>[];
  final statuses = <int, String>{};
  int closeCalls = 0;
  Future<ChatConversation> Function(int)? onClose;
  Future<ChatPage<ChatMessage>> Function(int, int?)? getMessages;
  Future<ChatConversation> Function(int)? getConversation;
  Future<ChatMessage> Function(int, String, String)? onSend;
  Future<ChatConversation> Function(int)? onCreate;
  Future<ChatPage<ChatConversation>> Function(int)? onConversations;
  @override
  Future<ChatPage<ChatConversation>> conversations(int page) async =>
      onConversations != null
      ? onConversations!(page)
      : ChatPage([fixtureConversation(1), fixtureConversation(2)], 1);
  @override
  Future<ChatConversation> conversation(int id) async => getConversation != null
      ? getConversation!(id)
      : ChatConversation(
          id: id,
          companyId: id,
          companyName: 'Nhà xe $id',
          status: statuses[id] ?? 'DANG_XU_LY',
        );
  @override
  Future<ChatConversation> create(int id) async =>
      onCreate != null ? onCreate!(id) : conversation(id);
  @override
  Future<ChatPage<ChatMessage>> messages(int id, {int? beforeId}) async {
    messageCalls.add((id: id, before: beforeId));
    if (getMessages != null) return getMessages!(id, beforeId);
    final list = (records[id] ?? [])
        .where((m) => beforeId == null || m.id! < beforeId)
        .toList();
    return ChatPage(
      list.length > 30 ? list.sublist(list.length - 30) : list,
      1,
    );
  }

  @override
  Future<ChatMessage> send(int id, String content, String clientId) async {
    sends.add((id: id, clientId: clientId, content: content));
    if (onSend != null) return onSend!(id, content, clientId);
    final saved = message(100, conversation: id, clientId: clientId);
    records.putIfAbsent(id, () => []).add(saved);
    return saved;
  }

  @override
  Future<void> read(int id, List<int> ids) async {
    readCalls.add(ids);
  }

  @override
  Future<ChatConversation> close(int id) async {
    closeCalls++;
    if (onClose != null) return onClose!(id);
    statuses[id] = 'DA_DONG';
    return conversation(id);
  }
}

Future<void> tick() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late FakeRepository repo;
  late FakeSocket socket;
  late SupportChatCubit cubit;
  setUp(() async {
    repo = FakeRepository();
    socket = FakeSocket();
    cubit = SupportChatCubit(
      repository: repo,
      socket: socket,
      accessToken: () async => 'token',
      sessionVersion: () => 0,
    );
    cubit.setSession('7');
    await cubit.activate();
    await cubit.select(fixtureConversation(1));
  });
  tearDown(() async {
    await cubit.close();
  });

  test(
    'server model keeps identifiers, sender, UTC timestamp and read state',
    () {
      final parsed = message(9, clientId: 'stable', status: 'DA_DOC');
      expect(parsed.id, 9);
      expect(parsed.clientId, 'stable');
      expect(parsed.createdAt.isUtc, isTrue);
      expect(parsed.read, isTrue);
      expect(
        () => ChatMessage.fromJson({...messageJson(9), 'tinNhanId': 0}),
        throwsFormatException,
      );
      expect(
        () => ChatMessage.fromJson({...messageJson(9), 'createdAt': 'bad'}),
        throwsFormatException,
      );
    },
  );
  test('unknown conversation status fails closed', () {
    expect(fixtureConversation(1, status: 'NEW_UNKNOWN').canSend, isFalse);
  });
  test('slow initial history cannot erase a newer realtime message', () async {
    final pending = Completer<ChatPage<ChatMessage>>();
    repo.getMessages = (_, _) => pending.future;
    final loading = cubit.refresh();
    socket.incoming('support.message.new', messageJson(12, sender: 8));
    pending.complete(ChatPage([message(10)], 1));
    await loading;
    expect(cubit.state.messages.map((m) => m.id), [10, 12]);
  });
  test('late history from conversation A does not enter B', () async {
    final pending = Completer<ChatPage<ChatMessage>>();
    repo.getMessages = (id, _) async =>
        id == 1 ? pending.future : ChatPage([message(20, conversation: 2)], 1);
    final loading = cubit.refresh();
    await cubit.select(fixtureConversation(2));
    pending.complete(ChatPage([message(10)], 1));
    await loading;
    expect(cubit.state.selected!.id, 2);
    expect(cubit.state.messages.single.id, 20);
  });
  test(
    'logout discards pending history, socket events and composer session',
    () async {
      final pending = Completer<ChatPage<ChatMessage>>();
      repo.getMessages = (_, _) => pending.future;
      final loading = cubit.refresh();
      cubit.setSession(null);
      socket.incoming('support.message.new', messageJson(12));
      pending.complete(ChatPage([message(10)], 1));
      await loading;
      expect(cubit.state.session, isNull);
      expect(cubit.state.messages, isEmpty);
      expect(socket.ready, isFalse);
    },
  );
  test('account switch rejects an old create response', () async {
    final pending = Completer<ChatConversation>();
    repo.onCreate = (_) => pending.future;
    final create = cubit.start(2);
    cubit.setSession('99');
    pending.complete(fixtureConversation(2));
    await create;
    expect(cubit.state.session, '99');
    expect(cubit.state.selected, isNull);
  });
  test('REST fallback reuses exact socket clientMessageId', () async {
    socket.ready = true;
    socket.handler = (event, payload) async =>
        throw TimeoutException('ack lost');
    await cubit.send('Xin chào');
    final sent = socket.requests
        .where((r) => r.key == 'support.message.send')
        .single
        .value;
    expect(repo.sends.single.clientId, sent['clientMessageId']);
    expect(repo.sends.single.content, 'Xin chào');
    expect(cubit.state.messages.single.delivery, ChatDelivery.sent);
  });
  test(
    'broadcast before ACK failure proves persistence and avoids REST duplicate',
    () async {
      socket.ready = true;
      socket.handler = (event, payload) async {
        socket.incoming(
          'support.message.new',
          messageJson(44, clientId: payload['clientMessageId'] as String),
        );
        throw StateError('broadcast succeeded but ack failed');
      };
      await cubit.send('Chào');
      expect(repo.sends, isEmpty);
      expect(cubit.state.messages.length, 1);
      expect(cubit.state.messages.single.id, 44);
    },
  );
  test(
    'both send errors reconcile committed message even after conversation closes',
    () async {
      socket.ready = true;
      socket.handler = (_, _) async =>
          throw StateError('socket failure after commit');
      repo.onSend = (id, content, clientId) async {
        repo.records[id] = [message(45, clientId: clientId)];
        repo.statuses[id] = 'DA_DONG';
        throw StateError('closed');
      };
      await cubit.send('Chào');
      expect(cubit.state.messages.single.id, 45);
      expect(cubit.state.messages.single.delivery, ChatDelivery.sent);
    },
  );
  test('failed retry retains the original id and is single flight', () async {
    repo.onSend = (_, _, _) async => throw StateError('offline');
    await cubit.send('Chào');
    final failed = cubit.state.messages.single;
    expect(failed.delivery, ChatDelivery.failed);
    final pending = Completer<ChatMessage>();
    repo.onSend = (_, _, _) => pending.future;
    final first = cubit.retry(failed), second = cubit.retry(failed);
    pending.complete(message(55, clientId: failed.clientId));
    await Future.wait([first, second]);
    expect(repo.sends.length, 2);
    expect(repo.sends.map((s) => s.clientId).toSet(), {failed.clientId});
    expect(cubit.state.messages.single.id, 55);
  });
  test('late send ACK from A never mutates B', () async {
    final pending = Completer<ChatMessage>();
    repo.onSend = (_, _, _) => pending.future;
    final sending = cubit.send('Chào');
    final clientId = repo.sends.single.clientId;
    await cubit.select(fixtureConversation(2));
    pending.complete(message(60, clientId: clientId));
    await sending;
    expect(cubit.state.selected!.id, 2);
    expect(cubit.state.messages, isEmpty);
  });
  test(
    'duplicate broadcast merges server ID and client ID once, preserving read receipt',
    () {
      final merged = SupportChatCubit.mergeMessages(
        [message(10, clientId: 'x', status: 'DA_DOC')],
        [message(10, clientId: 'x'), message(10, clientId: 'x')],
        1,
      );
      expect(merged.length, 1);
      expect(merged.single.read, isTrue);
    },
  );
  test('read only loaded incoming IDs, never empty mark-all', () async {
    await cubit.markRead([20, 21]);
    expect(repo.readCalls, isEmpty);
    socket.incoming('support.message.new', messageJson(20, sender: 8));
    socket.incoming('support.message.new', messageJson(21));
    await cubit.markRead([20, 21]);
    await cubit.markRead([20, 21]);
    expect(repo.readCalls, [
      [20],
    ]);
    expect(cubit.state.messages.first.read, isTrue);
    expect(cubit.state.messages.last.read, isFalse);
  });
  test('read receipt from own account does not mark outgoing read', () {
    socket.incoming('support.message.new', messageJson(20));
    socket.incoming('support.message.read_receipt', {
      'cuocTroChuyenId': 1,
      'readByTaiKhoanId': 7,
      'tinNhanIds': [20],
      'updatedCount': 1,
    });
    expect(cubit.state.messages.single.read, isFalse);
    socket.incoming('support.message.read_receipt', {
      'cuocTroChuyenId': 1,
      'readByTaiKhoanId': 8,
      'tinNhanIds': [20],
      'updatedCount': 1,
    });
    expect(cubit.state.messages.single.read, isTrue);
  });
  test(
    'closed realtime scalar payload disables send and survives stale detail',
    () async {
      final detail = Completer<ChatConversation>();
      repo.getConversation = (_) => detail.future;
      final refresh = cubit.refresh();
      await tick();
      socket.incoming('support.conversation.closed', {
        'cuocTroChuyenId': 1,
        'nhaXeId': 1,
        'trangThai': 'DA_DONG',
      });
      detail.complete(fixtureConversation(1));
      await refresh;
      expect(cubit.state.selected!.closed, isTrue);
      expect(cubit.state.selected!.companyName, 'Nhà xe 1');
      await cubit.send('Không gửi');
      expect(repo.sends, isEmpty);
    },
  );
  test('reconnect bridges more than one missed message page', () async {
    repo.records[1] = [message(1)];
    await cubit.refresh();
    repo.records[1] = List.generate(95, (i) => message(i + 1));
    socket.ready = true;
    socket.incoming('support.connected', {});
    for (var i = 0; i < 8; i++) {
      await tick();
    }
    expect(cubit.state.messages.length, 95);
    expect(
      socket.requests.any(
        (r) =>
            r.key == 'support.conversation.join' &&
            r.value['cuocTroChuyenId'] == 1,
      ),
      isTrue,
    );
    expect(repo.messageCalls.where((c) => c.before != null).length, 3);
  });
  test('typing from another conversation is ignored', () {
    socket.incoming('support.typing', {
      'cuocTroChuyenId': 2,
      'taiKhoanId': 8,
      'isTyping': true,
    });
    expect(cubit.state.typing, isFalse);
    socket.incoming('support.typing', {
      'cuocTroChuyenId': 1,
      'taiKhoanId': 8,
      'isTyping': true,
    });
    expect(cubit.state.typing, isTrue);
    cubit.backToList();
    expect(cubit.state.typing, isFalse);
  });
  test(
    'background stops read and ignores stale history; resume can refresh',
    () async {
      socket.incoming('support.message.new', messageJson(9, sender: 8));
      final pending = Completer<ChatPage<ChatMessage>>();
      repo.getMessages = (_, _) => pending.future;
      final load = cubit.refresh();
      cubit.setForeground(false);
      await cubit.markRead([20, 21]);
      pending.complete(ChatPage([message(15)], 1));
      await load;
      expect(repo.readCalls, isEmpty);
      expect(cubit.state.historyLoading, isFalse);
      expect(cubit.state.messages.map((m) => m.id), [9]);
    },
  );
  test(
    'REST sends auth and preserves exact paths/body; empty read makes no request',
    () async {
      TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
      await TokenStorage.saveTokens(accessToken: 'test-token');
      final requests = <http.Request>[];
      final source = SupportChatRemoteDataSource(
        ApiClient(
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response(
              jsonEncode({'data': messageJson(40, clientId: 'retain-me')}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      await source.send(1, 'Nội dung', 'retain-me');
      await source.read(1, []);
      expect(requests.length, 1);
      expect(
        requests.single.url.path,
        '/api/v1/support-chat/conversations/1/messages',
      );
      expect(requests.single.headers['Authorization'], 'Bearer test-token');
      expect(jsonDecode(requests.single.body), {
        'noiDung': 'Nội dung',
        'loaiTinNhan': 'VAN_BAN',
        'clientMessageId': 'retain-me',
      });
      await TokenStorage.clearTokens();
    },
  );
  test(
    'realtime newest ID before reconnect does not hide a gap in REST history',
    () async {
      repo.records[1] = List.generate(30, (i) => message(i + 1));
      await cubit.refresh();
      repo.records[1] = List.generate(81, (i) => message(i + 1));
      socket.incoming('support.message.new', messageJson(81));
      socket.ready = true;
      socket.incoming('support.connected', {});
      for (var i = 0; i < 8; i++) {
        await tick();
      }
      expect(
        cubit.state.messages.map((m) => m.id),
        List.generate(81, (i) => i + 1),
      );
    },
  );
  test(
    'authentication recovery waits for a list request already refreshing the JWT',
    () async {
      var token = 'old-fixture-token';
      final other = SupportChatCubit(
        repository: repo,
        socket: FakeSocket(),
        accessToken: () async => token,
        sessionVersion: () => 0,
      );
      final transport = other.socket as FakeSocket;
      other.setSession('7');
      await other.activate();
      final pending = Completer<ChatPage<ChatConversation>>();
      repo.onConversations = (_) => pending.future;
      final list = other.loadConversations();
      transport.incoming('support.error', {'error': 'ACCESS_TOKEN_INVALID'});
      await tick();
      expect(transport.tokens, ['old-fixture-token']);
      token = 'new-fixture-token';
      pending.complete(ChatPage([fixtureConversation(1)], 1));
      await list;
      for (var i = 0; i < 4; i++) {
        await tick();
      }
      expect(transport.tokens, ['old-fixture-token', 'new-fixture-token']);
      await other.close();
    },
  );
  test('read scope excludes an offscreen incoming message', () async {
    socket.incoming('support.message.new', messageJson(20, sender: 8));
    socket.incoming('support.message.new', messageJson(21, sender: 8));
    await cubit.markRead([21]);
    expect(repo.readCalls, [
      [21],
    ]);
    expect(cubit.state.messages.first.read, isFalse);
    expect(cubit.state.messages.last.read, isTrue);
  });
  test(
    'close is single flight and prevents sending into a closing conversation',
    () async {
      final pending = Completer<ChatConversation>();
      repo.onClose = (_) => pending.future;
      final first = cubit.closeConversation(),
          second = cubit.closeConversation();
      expect(cubit.state.closing, isTrue);
      expect(repo.closeCalls, 1);
      pending.complete(fixtureConversation(1, status: 'DA_DONG'));
      await Future.wait([first, second]);
      expect(cubit.state.closing, isFalse);
      expect(cubit.state.selected!.closed, isTrue);
    },
  );
  test('company chooser follows every public active company page', () async {
    final requested = <int>[];
    final source = SupportChatRemoteDataSource(
      ApiClient(
        httpClient: MockClient((request) async {
          final page = int.parse(request.url.queryParameters['page']!);
          requested.add(page);
          expectSync(request.url.path, '/api/v1/bus-companies');
          expectSync(request.url.queryParameters['status'], 'HOAT_DONG');
          return http.Response(
            jsonEncode({
              'data': [
                {'busCompanyId': page, 'name': 'Operator $page'},
              ],
              'meta': {'page': page, 'totalPages': 2},
            }),
            200,
          );
        }),
      ),
    );
    final companies = await source.companies();
    expect(requested, [1, 2]);
    expect(companies.map((c) => c.id), ['1', '2']);
  });
  test(
    'suspending a deferred create clears busy state and allows another create after resume',
    () async {
      final pending = Completer<ChatConversation>();
      repo.onCreate = (_) => pending.future;
      final creating = cubit.start(2);
      expect(cubit.state.creating, isTrue);
      cubit.setForeground(false);
      expect(cubit.state.creating, isFalse);
      cubit.setForeground(true);
      await tick();
      pending.complete(fixtureConversation(2));
      await creating;
      expect(cubit.state.creating, isFalse);
      expect(
        cubit.state.selected!.id,
        1,
      ); // The suspended result cannot change the active view.
      repo.onCreate = null;
      await cubit.start(2);
      expect(cubit.state.selected!.id, 2);
    },
  );
  test(
    'suspending a deferred close clears busy and resync reads the authoritative result',
    () async {
      final pending = Completer<ChatConversation>();
      repo.onClose = (_) => pending.future;
      final closing = cubit.closeConversation();
      expect(cubit.state.closing, isTrue);
      cubit.setForeground(false);
      expect(cubit.state.closing, isFalse);
      repo.statuses[1] = 'DA_DONG';
      cubit.setForeground(true);
      pending.complete(fixtureConversation(1, status: 'DA_DONG'));
      await closing;
      expect(cubit.state.closing, isFalse);
      socket.ready = true;
      socket.incoming('support.connected', {});
      for (var i = 0; i < 8; i++) {
        await tick();
      }
      expect(cubit.state.selected!.closed, isTrue);
      expect(cubit.state.closing, isFalse);
    },
  );
  test(
    'a suspended create failure cannot clear a newer create busy state',
    () async {
      final old = Completer<ChatConversation>(),
          current = Completer<ChatConversation>();
      var calls = 0;
      repo.onCreate = (_) => calls++ == 0 ? old.future : current.future;
      final first = cubit.start(2);
      cubit.setForeground(false);
      cubit.setForeground(true);
      await tick();
      final second = cubit.start(3);
      expect(cubit.state.creating, isTrue);
      old.completeError(StateError('Old suspended operation failed'));
      await first;
      expect(cubit.state.creating, isTrue);
      expect(cubit.state.error, isNull);
      current.complete(fixtureConversation(3));
      await second;
      expect(cubit.state.selected!.id, 3);
      expect(cubit.state.creating, isFalse);
    },
  );
}
