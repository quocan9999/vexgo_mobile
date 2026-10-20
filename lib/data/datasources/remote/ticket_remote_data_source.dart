import '../../models/ticket_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

abstract class TicketRemoteDataSource {
  Future<List<TicketModel>> getCustomerTickets({
    int page = 1,
    int pageSize = 20,
    String? status,
  });

  Future<TicketModel> getCustomerTicketById(dynamic ticketId);

  Future<TicketModel> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  });

  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  });
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final ApiClient client;

  TicketRemoteDataSourceImpl({required this.client});

  @override
  Future<List<TicketModel>> getCustomerTickets({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final query = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final items = <TicketModel>[];
    var currentPage = page;
    while (true) {
      query['page'] = currentPage;
      final res = await client.get(
        ApiConfig.tickets,
        queryParams: query,
        requiresAuth: true,
      );
      final data = res is Map<String, dynamic> ? res['data'] : res;
      if (data is! List) {
        throw const FormatException('Danh sách từ máy chủ không hợp lệ.');
      }
      items.addAll(
        data.map((item) => TicketModel.fromJson(item as Map<String, dynamic>)),
      );
      final meta = res is Map<String, dynamic> ? res['meta'] : null;
      final totalPages = meta is Map
          ? (meta['totalPages'] as num?)?.toInt()
          : null;
      if (totalPages == null || currentPage >= totalPages || data.isEmpty) {
        break;
      }
      currentPage++;
    }
    return items;
  }

  @override
  Future<TicketModel> getCustomerTicketById(dynamic ticketId) async {
    final res = await client.get(
      ApiConfig.ticketDetail(ticketId),
      requiresAuth: true,
    );

    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return TicketModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid ticket detail response');
  }

  @override
  Future<TicketModel> lookupTicket({
    required String ticketCode,
    required String phoneNumber,
  }) async {
    final body = {'ticketCode': ticketCode, 'phoneNumber': phoneNumber};

    final res = await client.post(
      ApiConfig.ticketLookup,
      body: body,
      requiresAuth: false,
    );

    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return TicketModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid ticket lookup response');
  }

  @override
  Future<Map<String, dynamic>> cancelTicket({
    required String ticketCode,
    required String phoneNumber,
    String? reason,
    required double expectedCancelFeeRate,
  }) async {
    final body = <String, dynamic>{
      'ticketCode': ticketCode,
      'phoneNumber': phoneNumber,
      'expectedCancelFeeRate': expectedCancelFeeRate,
    };
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

    final res = await client.post(
      ApiConfig.ticketCancel,
      body: body,
      requiresAuth: false,
    );

    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'success': true};
  }
}
