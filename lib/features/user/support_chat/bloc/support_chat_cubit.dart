import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/network/support_chat_socket.dart';
import '../../../../data/models/support_chat_model.dart';
import '../../../../data/models/operator_model.dart';
import '../../../../data/repositories/support_chat_repository.dart';

class SupportChatState {
  final String? session;
  final List<ChatConversation> conversations;
  final ChatConversation? selected;
  final List<ChatMessage> messages;
  final bool loading,
      historyLoading,
      creating,
      closing,
      connected,
      typing,
      hasOlder,
      hasMore;
  final String? error;
  const SupportChatState({
    this.session,
    this.conversations = const [],
    this.selected,
    this.messages = const [],
    this.loading = false,
    this.historyLoading = false,
    this.creating = false,
    this.closing = false,
    this.connected = false,
    this.typing = false,
    this.hasOlder = false,
    this.hasMore = false,
    this.error,
  });
  SupportChatState copy({
    List<ChatConversation>? conversations,
    ChatConversation? selected,
    List<ChatMessage>? messages,
    bool? loading,
    bool? historyLoading,
    bool? creating,
    bool? closing,
    bool? connected,
    bool? typing,
    bool? hasOlder,
    bool? hasMore,
    String? error,
  }) => SupportChatState(
    session: session,
    conversations: conversations ?? this.conversations,
    selected: selected ?? this.selected,
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    historyLoading: historyLoading ?? this.historyLoading,
    creating: creating ?? this.creating,
    closing: closing ?? this.closing,
    connected: connected ?? this.connected,
    typing: typing ?? this.typing,
    hasOlder: hasOlder ?? this.hasOlder,
    hasMore: hasMore ?? this.hasMore,
    error: error,
  );
}

class SupportChatCubit extends Cubit<SupportChatState> {
  final SupportChatRepository repository;
  final ChatSocket socket;
  final Future<String?> Function() accessToken;
  final int Function() sessionVersion;
  late final StreamSubscription<ChatSocketEvent> _events;
  late final StreamSubscription<void> _invalidations;
  int _epoch = 0, _selection = 0, _page = 0, _lifecycleRevision = 0;
  int? _tokenVersion;
  int _connectionGeneration = 0;
  bool _active = false, _foreground = true;
  Object? _resyncOperation;
  final Set<String> _sending = {};
  final Set<int> _reading = {};
  Timer? _typingTimer, _outgoingTypingTimer;
  DateTime? _lastTyping;
  String? _rejectedToken;
  Future<void>? _listInFlight;
  Future<void>? _historyInFlight;
  int? _historyWatermark;
  SupportChatCubit({
    required this.repository,
    required this.socket,
    Future<String?> Function()? accessToken,
    int Function()? sessionVersion,
  }) : accessToken = accessToken ?? TokenStorage.getAccessToken,
       sessionVersion = sessionVersion ?? (() => TokenStorage.sessionVersion),
       super(const SupportChatState()) {
    _events = socket.events.listen(_onEvent);
    _invalidations = TokenStorage.sessionInvalidations.listen((_) {
      setSession(null);
    });
  }
  bool _valid(int epoch) =>
      !isClosed &&
      state.session != null &&
      epoch == _epoch &&
      _tokenVersion == sessionVersion();
  bool _canConnect(int epoch, int generation) =>
      _valid(epoch) &&
      _active &&
      _foreground &&
      generation == _connectionGeneration;
  bool _view(int epoch, int selection, int id) =>
      _valid(epoch) &&
      _active &&
      _foreground &&
      selection == _selection &&
      state.selected?.id == id;
  void setSession(String? key) {
    final version = sessionVersion();
    if (state.session == key && _tokenVersion == version) return;
    _epoch++;
    _connectionGeneration++;
    _selection++;
    _tokenVersion = version;
    _page = 0;
    _sending.clear();
    _reading.clear();
    _typingTimer?.cancel();
    _outgoingTypingTimer?.cancel();
    socket.disconnect();
    _rejectedToken = null;
    _listInFlight = null;
    _resyncOperation = null;
    _historyInFlight = null;
    _historyWatermark = null;
    emit(SupportChatState(session: key));
    if (key != null && _active) unawaited(activate());
  }

  Future<List<OperatorModel>> companies() => repository.companies();

  Future<void> activate() async {
    _active = true;
    if (state.session == null || !_foreground) return;
    final epoch = _epoch, generation = _connectionGeneration;
    await loadConversations(preserveLoadedPages: true);
    if (!_canConnect(epoch, generation)) return;
    final token = await accessToken();
    if (!_canConnect(epoch, generation) || token == null) return;
    if (!socket.connected) socket.connect(token);
  }

  void deactivate() {
    if (isClosed) return;
    _active = false;
    _connectionGeneration++;
    _resyncOperation = null;
    _historyInFlight = null;
    _historyWatermark = null;
    _selection++;
    _typingTimer?.cancel();
    _outgoingTypingTimer?.cancel();
    socket.disconnect();
    _sending.clear();
    emit(
      SupportChatState(
        session: state.session,
        conversations: state.conversations,
        hasMore: state.hasMore,
      ),
    );
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    if (!foreground) {
      _connectionGeneration++;
      _selection++;
      _resyncOperation = null;
      _reading.clear();
      _historyInFlight = null;
      socket.disconnect();
      emit(
        state.copy(
          connected: false,
          typing: false,
          creating: false,
          closing: false,
          historyLoading: false,
          messages: state.messages
              .map(
                (m) => m.delivery == ChatDelivery.sending
                    ? m.copy(delivery: ChatDelivery.failed)
                    : m,
              )
              .toList(),
        ),
      );
    } else if (_active) {
      unawaited(activate());
    }
  }

  Future<void> loadConversations({
    bool more = false,
    bool preserveLoadedPages = false,
  }) {
    final pending = _listInFlight;
    if (pending != null) return pending;
    final operation = _loadConversations(
      more: more,
      preserveLoadedPages: preserveLoadedPages,
    );
    _listInFlight = operation;
    return operation.whenComplete(() {
      if (identical(_listInFlight, operation)) _listInFlight = null;
    });
  }

  Future<void> _loadConversations({
    bool more = false,
    bool preserveLoadedPages = false,
  }) async {
    if (state.session == null || state.loading || (more && !state.hasMore)) {
      return;
    }
    final epoch = _epoch, page = more ? _page + 1 : 1;
    emit(state.copy(loading: true));
    try {
      final result = await repository.conversations(page);
      if (!_valid(epoch)) return;
      final fetched = {for (final c in result.items) c.id: c};
      // Realtime refreshes reorder page 1, but do not invalidate rows/cursors from
      // pages already fetched. The next offset page can overlap after reordering;
      // deduplicate by conversation ID instead of rewinding its cursor.
      final retainPages = preserveLoadedPages && result.totalPages > 0;
      final merged = more
          ? {for (final c in state.conversations) c.id: c, ...fetched}
          : {
              ...fetched,
              if (retainPages)
                for (final c in state.conversations)
                  if (!fetched.containsKey(c.id)) c.id: c,
            };
      _page = retainPages && !more ? max(_page, page) : page;
      emit(
        state.copy(
          conversations: merged.values.toList(),
          loading: false,
          hasMore: _page < result.totalPages,
        ),
      );
    } catch (_) {
      if (_valid(epoch)) {
        emit(
          state.copy(
            loading: false,
            error: 'Không tải được hội thoại. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  Future<void> start(int companyId) async {
    if (state.session == null || state.creating) return;
    final epoch = _epoch, selection = _selection;
    emit(state.copy(creating: true));
    try {
      // Server resumes the active conversation for this customer/company.
      final conversation = await repository.create(companyId);
      if (!_valid(epoch) || !_active || selection != _selection) return;
      emit(
        state.copy(
          creating: false,
          conversations: [
            conversation,
            ...state.conversations.where((c) => c.id != conversation.id),
          ],
        ),
      );
      await select(conversation);
    } catch (_) {
      if (_valid(epoch) && _active && _foreground && selection == _selection) {
        emit(
          state.copy(
            creating: false,
            error: 'Không mở được hội thoại với nhà xe.',
          ),
        );
      }
    }
  }

  Future<void> select(ChatConversation conversation) async {
    if (state.session == null) return;
    final previous = state.selected?.id;
    if (previous != null && socket.connected) unawaited(_leave(previous));
    _selection++;
    _historyInFlight = null;
    _historyWatermark = null;
    _resyncOperation = null;
    _lifecycleRevision++;
    _typingTimer?.cancel();
    _outgoingTypingTimer?.cancel();
    _reading.clear();
    emit(
      SupportChatState(
        session: state.session,
        conversations: state.conversations,
        selected: conversation,
        connected: socket.connected,
        hasMore: state.hasMore,
      ),
    );
    final epoch = _epoch, selection = _selection;
    if (socket.connected) {
      try {
        await socket.request('support.conversation.join', {
          'cuocTroChuyenId': conversation.id,
        });
      } catch (_) {}
    }
    if (_view(epoch, selection, conversation.id)) await refresh();
  }

  Future<void> _leave(int id) async {
    try {
      await socket.request('support.conversation.leave', {
        'cuocTroChuyenId': id,
      });
    } catch (_) {}
  }

  void backToList() {
    final id = state.selected?.id;
    if (id != null && socket.connected) unawaited(_leave(id));
    _selection++;
    _typingTimer?.cancel();
    _outgoingTypingTimer?.cancel();
    emit(
      SupportChatState(
        session: state.session,
        conversations: state.conversations,
        connected: socket.connected,
        hasMore: state.hasMore,
      ),
    );
    unawaited(loadConversations());
  }

  static List<ChatMessage> mergeMessages(
    List<ChatMessage> current,
    Iterable<ChatMessage> incoming,
    int conversationId,
  ) {
    final result = current
        .where((m) => m.conversationId == conversationId)
        .toList();
    for (final message in incoming) {
      if (message.conversationId != conversationId) continue;
      final index = result.indexWhere(
        (m) =>
            (message.id != null && m.id == message.id) ||
            (message.clientId != null &&
                m.clientId == message.clientId &&
                m.senderId == message.senderId),
      );
      if (index < 0) {
        result.add(message);
        continue;
      }
      final old = result[index];
      if (old.id != null && message.id == null) continue;
      result[index] = message.copy(read: old.read || message.read);
    }
    result.sort((a, b) {
      if (a.id != null && b.id != null) return a.id!.compareTo(b.id!);
      return a.createdAt.compareTo(b.createdAt);
    });
    return List.unmodifiable(result);
  }

  Future<void> refresh({bool older = false}) {
    final pending = _historyInFlight;
    if (pending != null) return pending;
    final operation = _refresh(older: older);
    _historyInFlight = operation;
    return operation.whenComplete(() {
      if (identical(_historyInFlight, operation)) _historyInFlight = null;
    });
  }

  Future<void> _refresh({bool older = false}) async {
    final id = state.selected?.id;
    if (id == null || state.historyLoading || (older && !state.hasOlder)) {
      return;
    }
    final epoch = _epoch,
        selection = _selection,
        lifecycle = _lifecycleRevision;
    final ids = state.messages.map((m) => m.id).whereType<int>().toList();
    final before = older && ids.isNotEmpty ? ids.reduce(min) : null;
    emit(state.copy(historyLoading: true));
    try {
      final page = await repository.messages(id, beforeId: before);
      if (!_view(epoch, selection, id)) return;
      var fetched = page.items;
      // Bridge every missed page on reconnect, not just the newest 30 messages.
      if (!older && _historyWatermark != null) {
        final knownLatest = _historyWatermark!;
        var chunk = page.items;
        while (chunk.length == 30 && chunk.first.id! > knownLatest) {
          final next = await repository.messages(id, beforeId: chunk.first.id);
          if (!_view(epoch, selection, id)) return;
          if (next.items.isEmpty || next.items.first.id! >= chunk.first.id!) {
            break;
          }
          chunk = next.items;
          fetched = [...chunk, ...fetched];
        }
      }
      if (!older && fetched.isNotEmpty) {
        _historyWatermark = fetched.map((m) => m.id!).reduce(max);
      }
      emit(
        state.copy(
          messages: mergeMessages(state.messages, fetched, id),
          historyLoading: false,
          hasOlder: page.items.length == 30,
        ),
      );
      if (!older) {
        final current = await repository.conversation(id);
        if (_view(epoch, selection, id) && lifecycle == _lifecycleRevision) {
          emit(state.copy(selected: current));
        }
      }
    } catch (_) {
      if (_view(epoch, selection, id)) {
        emit(
          state.copy(
            historyLoading: false,
            error: 'Không tải được tin nhắn. Kéo để thử lại.',
          ),
        );
      }
    }
  }

  Future<void> send(String content) async {
    final conversation = state.selected;
    final account = int.tryParse(state.session ?? '');
    final text = content.trim();
    if (conversation == null ||
        !conversation.canSend ||
        state.closing ||
        account == null ||
        text.isEmpty ||
        text.length > 2000) {
      return;
    }
    final random = Random.secure();
    final clientId =
        'mobile-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    final message = ChatMessage(
      conversationId: conversation.id,
      senderId: account,
      clientId: clientId,
      content: text,
      senderType: 'KHACH_HANG',
      createdAt: DateTime.now(),
      delivery: ChatDelivery.sending,
    );
    emit(
      state.copy(
        messages: mergeMessages(state.messages, [message], conversation.id),
      ),
    );
    await _send(message);
  }

  Future<void> retry(ChatMessage message) async {
    if (message.delivery != ChatDelivery.failed ||
        message.conversationId != state.selected?.id ||
        state.selected?.canSend != true) {
      return;
    }
    await _send(message);
  }

  Future<void> _send(ChatMessage message) async {
    final id = message.conversationId, clientId = message.clientId!;
    if (_sending.contains(clientId)) return;
    _sending.add(clientId);
    final epoch = _epoch, selection = _selection;
    _delivery(clientId, ChatDelivery.sending);
    try {
      ChatMessage? saved;
      if (socket.connected) {
        try {
          final ack = await socket.request('support.message.send', {
            'cuocTroChuyenId': id,
            'noiDung': message.content,
            'loaiTinNhan': 'VAN_BAN',
            'clientMessageId': clientId,
          });
          saved = ChatMessage.fromJson(chatMap(ack['data']));
        } catch (_) {}
      }
      if (!_view(epoch, selection, id)) return;
      // A broadcast can precede the ACK, including an ACK failure after commit.
      saved ??= _findSaved(clientId);
      if (saved == null) {
        try {
          saved = await repository.send(id, message.content, clientId);
        } catch (_) {
          if (!_view(epoch, selection, id)) return;
          // Failures can occur after persistence, or the conversation may now be closed.
          // Reconcile authoritative history before offering retry, retaining this ID.
          await _reconcileSend(id, clientId, epoch, selection);
          if (!_view(epoch, selection, id)) return;
          saved = _findSaved(clientId);
          if (saved == null) rethrow;
        }
      }
      if (!_view(epoch, selection, id)) return;
      if (saved.conversationId != id ||
          saved.clientId != clientId ||
          saved.senderId != message.senderId) {
        throw const FormatException('Tin nhắn xác nhận không khớp.');
      }
      emit(state.copy(messages: mergeMessages(state.messages, [saved], id)));
    } catch (_) {
      if (_view(epoch, selection, id) && _findSaved(clientId) == null) {
        _delivery(clientId, ChatDelivery.failed);
      }
    } finally {
      _sending.remove(clientId);
    }
  }

  Future<void> _reconcileSend(
    int id,
    String clientId,
    int epoch,
    int selection,
  ) async {
    int? before;
    // Search all pages for the retained ID; no guessed success or time-based match.
    while (_view(epoch, selection, id)) {
      final page = await repository.messages(id, beforeId: before);
      if (!_view(epoch, selection, id)) return;
      emit(state.copy(messages: mergeMessages(state.messages, page.items, id)));
      if (_findSaved(clientId) != null || page.items.length < 30) return;
      final ids = page.items.map((m) => m.id).whereType<int>();
      if (ids.isEmpty) return;
      final next = ids.reduce(min);
      if (before != null && next >= before) return;
      before = next;
    }
  }

  ChatMessage? _findSaved(String clientId) {
    for (final m in state.messages) {
      if (m.clientId == clientId && m.id != null) return m;
    }
    return null;
  }

  void _delivery(String clientId, ChatDelivery delivery) {
    emit(
      state.copy(
        messages: state.messages
            .map(
              (m) => m.clientId == clientId && m.id == null
                  ? m.copy(delivery: delivery)
                  : m,
            )
            .toList(),
      ),
    );
  }

  Future<void> markRead(List<int> visibleIds) async {
    final id = state.selected?.id, account = int.tryParse(state.session ?? '');
    if (id == null || account == null || !_active || !_foreground) return;
    final ids = state.messages
        .where(
          (m) =>
              m.id != null &&
              visibleIds.contains(m.id) &&
              m.senderId != account &&
              !m.read &&
              !_reading.contains(m.id),
        )
        .take(100)
        .map((m) => m.id!)
        .toList();
    if (ids.isEmpty) return;
    _reading.addAll(ids);
    final epoch = _epoch, selection = _selection;
    try {
      await repository.read(id, ids);
      if (_view(epoch, selection, id)) {
        emit(
          state.copy(
            messages: state.messages
                .map((m) => ids.contains(m.id) ? m.copy(read: true) : m)
                .toList(),
          ),
        );
      }
    } catch (_) {
    } finally {
      if (_view(epoch, selection, id)) _reading.removeAll(ids);
    }
  }

  void typing(bool value) {
    final id = state.selected?.id;
    if (id == null || !socket.connected || state.selected?.canSend != true) {
      return;
    }
    final now = DateTime.now();
    if (!value ||
        _lastTyping == null ||
        now.difference(_lastTyping!) > const Duration(seconds: 2)) {
      _lastTyping = now;
      unawaited(_emitTyping(id, value));
    }
    _outgoingTypingTimer?.cancel();
    if (value) {
      _outgoingTypingTimer = Timer(const Duration(seconds: 2), () {
        if (state.selected?.id == id) unawaited(_emitTyping(id, false));
      });
    }
  }

  Future<void> _emitTyping(int id, bool value) async {
    try {
      await socket.request('support.typing', {
        'cuocTroChuyenId': id,
        'isTyping': value,
      });
    } catch (_) {}
  }

  Future<void> closeConversation() async {
    final id = state.selected?.id;
    if (id == null || !state.selected!.canSend || state.closing) return;
    final epoch = _epoch, selection = _selection;
    emit(state.copy(closing: true));
    try {
      final closed = await repository.close(id);
      if (_view(epoch, selection, id)) {
        _lifecycleRevision++;
        emit(state.copy(selected: closed, typing: false, closing: false));
      }
    } catch (_) {
      if (_view(epoch, selection, id)) {
        emit(
          state.copy(
            closing: false,
            error: 'Chưa thể kết thúc hội thoại. Vui lòng tải lại.',
          ),
        );
      }
    }
  }

  void _onEvent(ChatSocketEvent event) {
    if (!_active || !_foreground || !_valid(_epoch)) return;
    if (event.name == 'support.connected') {
      emit(state.copy(connected: true));
      unawaited(_resync());
      return;
    }
    if (event.name == 'disconnect' || event.name == 'connect_error') {
      emit(state.copy(connected: false, typing: false));
      return;
    }
    if (event.name == 'support.error') {
      emit(
        state.copy(
          connected: false,
          error: 'Kết nối chat bị gián đoạn. Đang dùng API để đồng bộ.',
        ),
      );
      unawaited(_recoverAuthentication());
      return;
    }
    try {
      final j = chatMap(event.data), id = j['cuocTroChuyenId'];
      if (event.name == 'support.message.new') {
        final message = ChatMessage.fromJson(j);
        if (message.conversationId == state.selected?.id) {
          emit(
            state.copy(
              messages: mergeMessages(state.messages, [
                message,
              ], message.conversationId),
            ),
          );
        }
        unawaited(loadConversations(preserveLoadedPages: true));
        return;
      }
      if (id != state.selected?.id) return;
      if (event.name == 'support.typing' &&
          j['taiKhoanId'].toString() != state.session) {
        _typingTimer?.cancel();
        emit(state.copy(typing: j['isTyping'] == true));
        if (j['isTyping'] == true) {
          _typingTimer = Timer(const Duration(seconds: 4), () {
            if (!isClosed) emit(state.copy(typing: false));
          });
        }
      } else if (event.name == 'support.message.read_receipt' &&
          j['readByTaiKhoanId'].toString() != state.session) {
        final ids = j['tinNhanIds'];
        // Omitted IDs are not proof of which messages were read: resync from server.
        if (ids is! List) {
          unawaited(refresh());
          return;
        }
        emit(
          state.copy(
            messages: state.messages
                .map(
                  (m) =>
                      m.senderId.toString() == state.session &&
                          ids.contains(m.id)
                      ? m.copy(read: true)
                      : m,
                )
                .toList(),
          ),
        );
      } else if (event.name == 'support.conversation.closed' ||
          event.name == 'support.conversation.claimed') {
        final conversation = ChatConversation.fromJson(
          j,
          fallback: state.selected,
        );
        _lifecycleRevision++;
        emit(state.copy(selected: conversation, typing: false));
        unawaited(loadConversations(preserveLoadedPages: true));
      }
    } catch (_) {
      emit(state.copy(error: 'Dữ liệu chat chưa hợp lệ. Vui lòng tải lại.'));
    }
  }

  Future<void> _resync() async {
    if (_resyncOperation != null) return;
    final operation = Object();
    _resyncOperation = operation;
    final epoch = _epoch, selection = _selection, id = state.selected?.id;
    try {
      await loadConversations(preserveLoadedPages: true);
      if (id != null && _view(epoch, selection, id)) {
        await socket.request('support.conversation.join', {
          'cuocTroChuyenId': id,
        });
        final pending = _historyInFlight;
        if (pending != null) await pending;
        if (_view(epoch, selection, id)) await refresh();
      }
    } catch (_) {
    } finally {
      if (identical(_resyncOperation, operation)) _resyncOperation = null;
    }
  }

  Future<void> _recoverAuthentication() async {
    final epoch = _epoch, generation = _connectionGeneration;
    await loadConversations(
      preserveLoadedPages: true,
    ); // ApiClient rotates expired access tokens over REST.
    if (!_canConnect(epoch, generation)) return;
    final token = await accessToken();
    if (!_canConnect(epoch, generation) ||
        token == null ||
        token == _rejectedToken) {
      return;
    }
    _rejectedToken = token;
    socket.connect(token);
  }

  @override
  Future<void> close() async {
    _epoch++;
    _typingTimer?.cancel();
    _outgoingTypingTimer?.cancel();
    await _events.cancel();
    await _invalidations.cancel();
    await socket.dispose();
    return super.close();
  }
}
