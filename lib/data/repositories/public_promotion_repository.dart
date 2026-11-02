import '../../core/network/api_client.dart';

class PublicPromotion {
  final String code, name, discountType, startsOn, endsOn;
  final num discountValue;
  final num? maxDiscount, minimumTicketAmount;
  const PublicPromotion({
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    required this.startsOn,
    required this.endsOn,
    this.maxDiscount,
    this.minimumTicketAmount,
  });

  factory PublicPromotion.fromJson(Map<String, dynamic> json) {
    num? amount(dynamic value) {
      if (value == null) return null;
      final parsed = num.tryParse(value.toString());
      if (parsed == null || !parsed.isFinite || parsed < 0) {
        throw const FormatException('Invalid promotion amount');
      }
      return parsed;
    }

    String date(dynamic value) {
      final text = value?.toString() ?? '';
      final parsed = DateTime.tryParse(text);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
          parsed == null ||
          !parsed.toIso8601String().startsWith(text)) {
        throw const FormatException('Invalid promotion date');
      }
      return text;
    }

    final code = json['code']?.toString().trim() ?? '';
    final kind = json['discountType'];
    final discount = amount(json['discountValue']);
    if (code.isEmpty ||
        !['PHAN_TRAM', 'SO_TIEN'].contains(kind) ||
        discount == null ||
        !discount.isFinite ||
        discount <= 0) {
      throw const FormatException('Invalid promotion response');
    }
    return PublicPromotion(
      code: code,
      name: json['name']?.toString() ?? code,
      discountType: kind as String,
      discountValue: discount,
      maxDiscount: amount(json['maxDiscount']),
      minimumTicketAmount: amount(json['minimumTicketAmount']),
      startsOn: date(json['startsOn']),
      endsOn: date(json['endsOn']),
    );
  }
}

class PublicPromotionRepository {
  final ApiClient client;
  PublicPromotionRepository({ApiClient? client})
    : client = client ?? ApiClient();
  Future<List<PublicPromotion>> getAvailable(int companyId) async {
    if (companyId <= 0) throw ArgumentError.value(companyId, 'companyId');
    final response = await client.get(
      '/promotions/available',
      queryParams: {'nhaXeId': companyId},
    );
    if (response is! Map || response['data'] is! List) {
      throw const FormatException('Invalid promotion envelope');
    }
    return (response['data'] as List)
        .map(
          (e) => PublicPromotion.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
