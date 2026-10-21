enum ChatDelivery { sending, failed, sent }

int chatId(dynamic value) {
  if (value is! int || value < 1) {
    throw const FormatException('Mã chat không hợp lệ.');
  }
  return value;
}

Map<String, dynamic> chatMap(dynamic value) {
  if (value is! Map) throw const FormatException('Dữ liệu chat không hợp lệ.');
  return Map<String, dynamic>.from(value);
}

class ChatConversation {
  final int id, companyId;
  final String companyName, status, title;
  final String? preview;
  const ChatConversation({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.status,
    this.title = '',
    this.preview,
  });
  bool get closed => status == 'DA_DONG';
  bool get canSend => status == 'CHO_TIEP_NHAN' || status == 'DANG_XU_LY';
  String get statusLabel => switch (status) {
    'CHO_TIEP_NHAN' => 'Chờ tiếp nhận',
    'DANG_XU_LY' => 'Đang hỗ trợ',
    'DA_DONG' => 'Đã kết thúc',
    _ => 'Trạng thái chưa hỗ trợ',
  };
  factory ChatConversation.fromJson(
    Map<String, dynamic> j, {
    ChatConversation? fallback,
  }) => ChatConversation(
    id: chatId(j['cuocTroChuyenId']),
    companyId: chatId(j['nhaXeId']),
    companyName: j['nhaXe'] is Map
        ? chatMap(j['nhaXe'])['tenNhaXe'] as String
        : fallback?.companyName ?? '',
    status: j['trangThai'] as String,
    title: j['tieuDe'] as String? ?? '',
    preview: j['tinNhanCuoi'] is Map
        ? j['tinNhanCuoi']['noiDung'] as String?
        : null,
  );
}

class ChatMessage {
  final int? id;
  final int conversationId, senderId;
  final String? clientId;
  final String content, senderType, type;
  final DateTime createdAt;
  final bool read;
  final ChatDelivery delivery;
  const ChatMessage({
    this.id,
    required this.conversationId,
    required this.senderId,
    this.clientId,
    required this.content,
    required this.senderType,
    this.type = 'VAN_BAN',
    required this.createdAt,
    this.read = false,
    this.delivery = ChatDelivery.sent,
  });
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: chatId(j['tinNhanId']),
    conversationId: chatId(j['cuocTroChuyenId']),
    senderId: chatId(j['taiKhoanGuiId']),
    clientId: j['clientMessageId'] as String?,
    content: j['noiDung'] as String,
    senderType: j['loaiNguoiGui'] as String,
    type: j['loaiTinNhan'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    read: j['trangThai'] == 'DA_DOC',
  );
  ChatMessage copy({ChatDelivery? delivery, bool? read}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    clientId: clientId,
    content: content,
    senderType: senderType,
    type: type,
    createdAt: createdAt,
    read: read ?? this.read,
    delivery: delivery ?? this.delivery,
  );
}

class ChatPage<T> {
  final List<T> items;
  final int totalPages;
  const ChatPage(this.items, this.totalPages);
}
