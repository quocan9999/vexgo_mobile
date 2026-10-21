import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_config.dart';
import '../../data/models/support_chat_model.dart';

class ChatSocketEvent {
  final String name;
  final dynamic data;
  const ChatSocketEvent(this.name, [this.data]);
}

abstract class ChatSocket {
  Stream<ChatSocketEvent> get events;
  bool get connected;
  void connect(String token);
  Future<Map<String, dynamic>> request(
    String event,
    Map<String, dynamic> payload,
  );
  void disconnect();
  Future<void> dispose();
}

class SupportChatSocket implements ChatSocket {
  final _events = StreamController<ChatSocketEvent>.broadcast();
  io.Socket? _socket;
  bool _ready = false;
  @override
  Stream<ChatSocketEvent> get events => _events.stream;
  @override
  bool get connected => _ready;
  @override
  void connect(String token) {
    disconnect();
    final api = Uri.parse(ApiConfig.baseUrl);
    // /chat is a Socket.IO namespace; /socket.io remains the Engine.IO path.
    final socket = io.io(
      api.replace(path: '/chat', query: null, fragment: null).toString(),
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .disableMultiplex()
          .setAuth({'token': token})
          .build(),
    );
    _socket = socket;
    for (final name in [
      'support.connected',
      'support.error',
      'support.message.new',
      'support.message.read_receipt',
      'support.typing',
      'support.conversation.claimed',
      'support.conversation.closed',
      'disconnect',
      'connect_error',
    ]) {
      socket.on(name, (data) {
        if (!identical(_socket, socket) || _events.isClosed) return;
        if (name == 'support.connected') _ready = true;
        if (name == 'disconnect' ||
            name == 'connect_error' ||
            name == 'support.error') {
          _ready = false;
        }
        _events.add(ChatSocketEvent(name, data));
      });
    }
    socket.connect();
  }

  @override
  Future<Map<String, dynamic>> request(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final socket = _socket;
    if (!_ready || socket == null) throw StateError('Chat chưa kết nối.');
    final result = Completer<Map<String, dynamic>>();
    socket.emitWithAck(
      event,
      payload,
      ack: (dynamic value) {
        if (!result.isCompleted) {
          try {
            result.complete(chatMap(value));
          } catch (e, st) {
            result.completeError(e, st);
          }
        }
      },
    );
    final ack = await result.future.timeout(const Duration(seconds: 6));
    if (ack['success'] != true) {
      throw StateError(ack['message'] as String? ?? 'Yêu cầu chat thất bại.');
    }
    return ack;
  }

  @override
  void disconnect() {
    _ready = false;
    final socket = _socket;
    _socket = null;
    socket?.dispose();
  }

  @override
  Future<void> dispose() async {
    disconnect();
    await _events.close();
  }
}
