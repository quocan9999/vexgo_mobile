import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/token_storage.dart';
import '../models/ai_chatbot_model.dart';

abstract class AiChatbotRepository {
  Future<List<AiSuggestion>> suggestions();
  Future<AiChatReply> send({
    required String message,
    String? sessionToken,
    int? companyId,
  });
  Future<AiChatHistory> history(String sessionToken);
}

class RealAiChatbotRepository implements AiChatbotRepository {
  final ApiClient client;
  RealAiChatbotRepository({ApiClient? client}) : client = client ?? ApiClient();
  void _check(int version) {
    if (version != TokenStorage.sessionVersion) throw UnauthorizedException();
  }

  @override
  Future<List<AiSuggestion>> suggestions() async {
    final version = TokenStorage.sessionVersion;
    final result = await client.get('/ai-chatbot/suggestions');
    _check(version);
    return aiList(aiMap(result)['data'], AiSuggestion.fromJson);
  }

  @override
  Future<AiChatReply> send({
    required String message,
    String? sessionToken,
    int? companyId,
  }) async {
    final text = message.trim();
    if (text.isEmpty ||
        text.runes.length > 2000 ||
        (companyId != null && companyId < 1)) {
      throw ArgumentError('Invalid chatbot input');
    }
    if (sessionToken != null) aiSessionToken(sessionToken);
    final version = TokenStorage.sessionVersion;
    final result = await client.post(
      '/ai-chatbot/messages',
      body: {
        'message': text,
        'sessionToken': ?sessionToken,
        'nhaXeId': ?companyId,
      },
      optionalAuth: true,
      expectedSessionVersion: version,
    );
    _check(version);
    final reply = AiChatReply.fromJson(aiMap(result)['data']);
    if (sessionToken != null && reply.sessionToken != sessionToken) {
      throw const FormatException('AI session mismatch');
    }
    return reply;
  }

  @override
  Future<AiChatHistory> history(String sessionToken) async {
    aiSessionToken(sessionToken);
    final version = TokenStorage.sessionVersion;
    final result = await client.get(
      '/ai-chatbot/sessions/${Uri.encodeComponent(sessionToken)}/messages',
      optionalAuth: true,
    );
    _check(version);
    final history = AiChatHistory.fromJson(aiMap(result)['data']);
    if (history.sessionToken != sessionToken) {
      throw const FormatException('AI session mismatch');
    }
    return history;
  }
}
