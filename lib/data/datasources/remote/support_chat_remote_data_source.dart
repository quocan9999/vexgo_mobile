import '../../../core/network/api_client.dart';
import '../../models/support_chat_model.dart';
import '../../models/operator_model.dart';

class SupportChatRemoteDataSource {
  final ApiClient client;
  SupportChatRemoteDataSource(this.client);
  static const root = '/support-chat';
  dynamic _data(dynamic response) {
    final j = chatMap(response);
    if (!j.containsKey('data')) {
      throw const FormatException('Thiếu dữ liệu chat.');
    }
    return j['data'];
  }

  Future<List<OperatorModel>> companies() async {
    final companies = <String, OperatorModel>{};
    var page = 1;
    while (true) {
      final response = chatMap(
        await client.get(
          '/bus-companies',
          queryParams: {'page': page, 'pageSize': 100, 'status': 'HOAT_DONG'},
        ),
      );
      final items = response['data'] as List;
      for (final item in items) {
        final company = OperatorModel.fromJson(chatMap(item));
        if (int.tryParse(company.id) == null) {
          throw const FormatException('Nhà xe thiếu mã.');
        }
        companies[company.id] = company;
      }
      final totalPages = chatMap(response['meta'])['totalPages'] as int;
      if (page >= totalPages) break;
      if (items.isEmpty) throw const FormatException('Thiếu trang nhà xe.');
      page++;
    }
    return companies.values.toList();
  }

  Future<ChatPage<ChatConversation>> conversations(int page) async {
    final j = chatMap(
      await client.get(
        '$root/conversations',
        requiresAuth: true,
        queryParams: {'page': page, 'pageSize': 20},
      ),
    );
    return ChatPage(
      (j['data'] as List)
          .map((e) => ChatConversation.fromJson(chatMap(e)))
          .toList(),
      chatMap(j['meta'])['totalPages'] as int,
    );
  }

  Future<ChatConversation> conversation(int id) async =>
      ChatConversation.fromJson(
        chatMap(
          _data(
            await client.get('$root/conversations/$id', requiresAuth: true),
          ),
        ),
      );
  Future<ChatConversation> create(int companyId) async =>
      ChatConversation.fromJson(
        chatMap(
          _data(
            await client.post(
              '$root/conversations',
              requiresAuth: true,
              body: {'nhaXeId': companyId},
            ),
          ),
        ),
      );
  Future<ChatPage<ChatMessage>> messages(int id, {int? beforeId}) async {
    final j = chatMap(
      await client.get(
        '$root/conversations/$id/messages',
        requiresAuth: true,
        queryParams: {'pageSize': 30, 'beforeId': ?beforeId},
      ),
    );
    return ChatPage(
      (j['data'] as List).map((e) => ChatMessage.fromJson(chatMap(e))).toList(),
      chatMap(j['meta'])['totalPages'] as int,
    );
  }

  Future<ChatMessage> send(int id, String content, String clientId) async =>
      ChatMessage.fromJson(
        chatMap(
          _data(
            await client.post(
              '$root/conversations/$id/messages',
              requiresAuth: true,
              body: {
                'noiDung': content,
                'loaiTinNhan': 'VAN_BAN',
                'clientMessageId': clientId,
              },
            ),
          ),
        ),
      );
  Future<void> read(int id, List<int> ids) async {
    if (ids.isEmpty) return;
    await client.post(
      '$root/conversations/$id/read',
      requiresAuth: true,
      body: {'tinNhanIds': ids},
    );
  }

  Future<ChatConversation> close(int id) async {
    await client.post(
      '$root/conversations/$id/close',
      requiresAuth: true,
      body: {},
    );
    return conversation(id);
  }
}
