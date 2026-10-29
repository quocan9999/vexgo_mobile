import '../../core/network/api_client.dart';
import '../datasources/remote/support_chat_remote_data_source.dart';
import '../models/support_chat_model.dart';
import '../models/operator_model.dart';

abstract class SupportChatRepository {
  Future<List<OperatorModel>> companies();
  Future<ChatPage<ChatConversation>> conversations(int page);
  Future<ChatConversation> conversation(int id);
  Future<ChatConversation> create(int companyId);
  Future<ChatPage<ChatMessage>> messages(int id, {int? beforeId});
  Future<ChatMessage> send(int id, String content, String clientId);
  Future<void> read(int id, List<int> ids);
  Future<ChatConversation> close(int id);
}

class RealSupportChatRepository implements SupportChatRepository {
  final SupportChatRemoteDataSource remote;
  RealSupportChatRepository({SupportChatRemoteDataSource? remote})
    : remote = remote ?? SupportChatRemoteDataSource(ApiClient());
  @override
  Future<List<OperatorModel>> companies() => remote.companies();
  @override
  Future<ChatPage<ChatConversation>> conversations(int page) =>
      remote.conversations(page);
  @override
  Future<ChatConversation> conversation(int id) => remote.conversation(id);
  @override
  Future<ChatConversation> create(int id) => remote.create(id);
  @override
  Future<ChatPage<ChatMessage>> messages(int id, {int? beforeId}) =>
      remote.messages(id, beforeId: beforeId);
  @override
  Future<ChatMessage> send(int id, String content, String clientId) =>
      remote.send(id, content, clientId);
  @override
  Future<void> read(int id, List<int> ids) => remote.read(id, ids);
  @override
  Future<ChatConversation> close(int id) => remote.close(id);
}
