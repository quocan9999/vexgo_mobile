import '../../models/payment_transaction_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider, // MOMO, VNPAY, ZALOPAY
  });

  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final ApiClient client;

  PaymentRemoteDataSourceImpl({required this.client});

  @override
  Future<PaymentTransactionModel> createPayment({
    required int bookingId,
    required String provider,
  }) async {
    final body = {'bookingId': bookingId, 'provider': provider.toUpperCase()};

    final res = await client.post(
      ApiConfig.payments,
      body: body,
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return PaymentTransactionModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid create payment response');
  }

  @override
  Future<PaymentTransactionModel> getPaymentStatus(dynamic paymentId) async {
    final res = await client.get(
      ApiConfig.paymentStatus(paymentId),
      requiresAuth: true,
    );
    if (res is Map<String, dynamic>) {
      final data = res['data'] ?? res;
      return PaymentTransactionModel.fromJson(data as Map<String, dynamic>);
    }
    throw Exception('Invalid payment status response');
  }
}
